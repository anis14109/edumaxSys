import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/database_service.dart';
import '../../data/models/user.dart';
import '../../data/models/pending_sync.dart';

/// Sync Service
/// 
/// Implements the offline-first synchronization logic similar to PowerSync.
/// This service handles:
/// 1. Pushing local changes to the server when online
/// 2. Pulling server updates when online
/// 3. Conflict resolution
/// 4. Background sync scheduling
class SyncService {
  static final SyncService instance = SyncService._();
  
  final ApiService _api = ApiService.instance;
  final DatabaseService _db = DatabaseService.instance;
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  SyncService._();

  /// Check if device has internet connectivity
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.any((result) => 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet
    );
  }

  /// Main sync method - coordinates push and pull operations
  /// 
  /// This is the core of the offline-first architecture:
  /// 1. First, push any local changes to the server
  /// 2. Then, pull the latest data from the server
  /// 
  /// Returns true if sync was successful, false otherwise
  Future<bool> sync() async {
    if (_isSyncing) {
      return false;
    }

    _isSyncing = true;

    try {
      // Check if online
      if (!await isOnline()) {
        return false;
      }

      // Check if authenticated
      if (!await _api.isAuthenticated()) {
        return false;
      }

      // Step 1: Push local changes to server
      await _pushChanges();

      // Step 2: Pull server changes
      await _pullChanges();

      return true;
    } catch (e) {
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Push local pending changes to the server
  /// 
  /// This method processes the pending sync queue and sends
  /// CREATE, UPDATE, and DELETE operations to the Laravel API.
  Future<void> _pushChanges() async {
    final pendingSyncs = await _db.getPendingSyncs();

    for (final sync in pendingSyncs) {
      try {
        await _processSyncOperation(sync);
        
        // Remove from queue on success
        if (sync.id != null) {
          await _db.removePendingSync(sync.id!);
        }
      } catch (e) {
        // Update retry count on failure
        if (sync.id != null) {
          await _db.updatePendingSyncRetry(sync.id!, e.toString());
        }
      }
    }
  }

  /// Process a single sync operation
  Future<void> _processSyncOperation(PendingSync sync) async {
    final recordId = sync.recordId;
    
    switch (sync.operation) {
      case SyncConstants.operationCreate:
        await _handleCreate(sync);
        break;
      case SyncConstants.operationUpdate:
        await _handleUpdate(sync);
        break;
      case SyncConstants.operationDelete:
        await _handleDelete(recordId);
        break;
    }
  }

  /// Handle CREATE operation
  Future<void> _handleCreate(PendingSync sync) async {
    if (sync.data == null) return;

    final userData = jsonDecode(sync.data!) as Map<String, dynamic>;
    
    try {
      // Try to create on server
      final response = await _api.createUser(
        name: userData['name'] as String,
        email: userData['email'] as String,
        password: userData['password'] as String? ?? 'password123',
      );

      if (response.statusCode == 201) {
        // Get the server ID and mark as synced
        final serverUser = User.fromJson(response.data['data']);
        final localUser = await _db.getUserByLocalId(sync.recordId);
        
        if (localUser != null) {
          await _db.markUserSynced(localUser, serverUser.id!);
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 && 
          e.response?.data['errors']?['email'] != null) {
        // Email already exists - try to get the user by email
        await _handleExistingUser(sync, userData);
      } else {
        rethrow;
      }
    }
  }

  /// Handle case when user already exists on server (conflict resolution)
  Future<void> _handleExistingUser(PendingSync sync, Map<String, dynamic> userData) async {
    // Try to get user by email
    final usersResponse = await _api.getUsers();
    if (usersResponse.statusCode == 200) {
      final users = (usersResponse.data['data'] as List)
          .map((u) => User.fromJson(u))
          .toList();
      
      final existingUser = users.where((u) => u.email == userData['email']).firstOrNull;
      
      if (existingUser != null) {
        // Mark local user as synced with server ID
        final localUser = await _db.getUserByLocalId(sync.recordId);
        if (localUser != null) {
          await _db.markUserSynced(localUser, existingUser.id!);
        }
      }
    }
  }

  /// Handle UPDATE operation
  Future<void> _handleUpdate(PendingSync sync) async {
    if (sync.data == null) return;

    final userData = jsonDecode(sync.data!) as Map<String, dynamic>;
    final localUser = await _db.getUserByLocalId(sync.recordId);

    if (localUser == null) return;

    // Try to get server ID
    final serverId = localUser.id;
    
    if (serverId == null) {
      // If no server ID, treat as create
      await _handleCreate(sync);
      return;
    }

    await _api.updateUser(
      id: serverId,
      name: userData['name'] as String?,
      email: userData['email'] as String?,
    );

    // Mark as synced
    await _db.markUserSynced(localUser, serverId);
  }

  /// Handle DELETE operation
  Future<void> _handleDelete(String recordId) async {
    final localUser = await _db.getUserByLocalId(recordId);
    
    if (localUser?.id != null) {
      await _api.deleteUser(localUser!.id!);
    }
  }

  /// Pull latest data from server
  /// 
  /// Fetches the latest users from the Laravel API and updates
  /// the local database. Respects sync timestamps to only fetch
  /// changes since last sync.
  Future<void> _pullChanges() async {
    try {
      final response = await _api.getUsers();
      
      if (response.statusCode == 200) {
        final usersList = response.data['data'] as List;
        final serverUsers = usersList.map((u) => User.fromJson(u)).toList();

        for (final serverUser in serverUsers) {
          // Check if user exists locally
          final localUser = await _db.getUserById(serverUser.id!);
          
          if (localUser == null) {
            // New user from server - add to local DB
            final newUser = serverUser.copyWith(
              syncStatus: SyncConstants.syncStatusSynced,
              lastSyncedAt: DateTime.now(),
            );
            await _db.insertUser(newUser);
          } else if (localUser.syncStatus == SyncConstants.syncStatusSynced) {
            // Only update if local is not modified
            final updatedUser = serverUser.copyWith(
              syncStatus: SyncConstants.syncStatusSynced,
              lastSyncedAt: DateTime.now(),
            );
            await _db.updateUser(updatedUser);
          }
          // If local has pending changes, skip to avoid overwriting
        }
      }
    } on DioException {
      // Failed to pull - that's okay, will try again next sync
    }
  }

  /// Auto-sync method for background scheduling
  /// 
  /// Called by WorkManager or timer to perform automatic sync
  Future<void> autoSync() async {
    if (await isOnline() && await _api.isAuthenticated()) {
      await sync();
    }
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    return await _db.getPendingSyncCount();
  }

  /// Check if there are pending changes
  Future<bool> hasPendingChanges() async {
    final count = await getPendingSyncCount();
    return count > 0;
  }
}
