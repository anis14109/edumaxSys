import '../models/user.dart';
import '../../core/services/database_service.dart';
import '../../core/services/sync_service.dart';

/// User Repository
/// 
/// Implements the Repository Pattern for User data access.
/// Reads from local database first, then syncs with server.
/// This is the key to the offline-first architecture.
class UserRepository {
  final DatabaseService _db = DatabaseService.instance;
  final SyncService _sync = SyncService.instance;

  /// Get all users - reads from local database first
  Future<List<User>> getAllUsers() async {
    // First, try to sync with server
    if (await _sync.isOnline()) {
      await _sync.sync();
    }
    
    // Then return local data
    return await _db.getAllUsers();
  }

  /// Get a user by ID
  Future<User?> getUserById(int id) async {
    return await _db.getUserById(id);
  }

  /// Create a new user locally
  Future<User> createUser({
    required String name,
    required String email,
    String? password,
  }) async {
    final user = User(
      name: name,
      email: email,
      password: password ?? 'password123',
    );

    // Save to local database (will be synced later)
    final createdUser = await _db.insertUser(user);
    
    // Trigger immediate sync if online
    if (await _sync.isOnline()) {
      await _sync.sync();
    }
    
    return createdUser;
  }

  /// Update an existing user locally
  Future<User> updateUser(User user) async {
    // Update locally first
    final updatedUser = await _db.updateUser(user);
    
    // Trigger immediate sync if online
    if (await _sync.isOnline()) {
      await _sync.sync();
    }
    
    return updatedUser;
  }

  /// Delete a user
  Future<void> deleteUser(int id, String? localId) async {
    // Delete locally (will sync later)
    await _db.deleteUser(id, localId);
  }

  /// Get users pending sync
  Future<List<User>> getPendingUsers() async {
    return await _db.getPendingUsers();
  }

  /// Force sync with server
  Future<bool> forceSync() async {
    return await _sync.sync();
  }
}
