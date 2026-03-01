import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/user.dart';
import '../../data/models/pending_sync.dart';
import '../constants/api_constants.dart';

/// Database Service
/// 
/// Provides SQLite database operations for offline-first functionality.
/// Similar to how PowerSync or Drift works - manages local data persistence
/// with sync capabilities.
class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._();

  DatabaseService._();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.usersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT,
        profile_photo_path TEXT,
        profile_photo_url TEXT,
        email_verified_at TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 1,
        local_id TEXT,
        last_synced_at TEXT,
        UNIQUE(email, local_id)
      )
    ''');

    // Pending sync table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.pendingSyncTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_users_sync_status ON ${DatabaseConstants.usersTable}(sync_status)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_pending_sync_created ON ${DatabaseConstants.pendingSyncTable}(created_at)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  // ==================== USER OPERATIONS ====================

  /// Insert a new user locally
  /// 
  /// If the user has no server ID, generates a local UUID.
  /// Adds the operation to the pending sync queue.
  Future<User> insertUser(User user) async {
    final db = await database;
    final uuid = const Uuid();
    final localId = user.localId ?? uuid.v4();
    final now = DateTime.now();

    // Create user with local sync metadata
    final newUser = user.copyWith(
      localId: localId,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncConstants.syncStatusPending,
    );

    // Insert into database
    final id = await db.insert(
      DatabaseConstants.usersTable,
      newUser.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Add to pending sync queue
    await _addToPendingSync(
      tableName: DatabaseConstants.usersTable,
      operation: SyncConstants.operationCreate,
      recordId: localId,
      data: jsonEncode(newUser.toJson()),
    );

    return newUser.copyWith(id: id);
  }

  /// Update an existing user locally
  Future<User> updateUser(User user) async {
    final db = await database;
    final now = DateTime.now();

    final updatedUser = user.copyWith(
      updatedAt: now,
      syncStatus: SyncConstants.syncStatusPending,
    );

    await db.update(
      DatabaseConstants.usersTable,
      updatedUser.toMap(),
      where: 'id = ? OR local_id = ?',
      whereArgs: [user.id, user.localId],
    );

    // Add to pending sync queue
    await _addToPendingSync(
      tableName: DatabaseConstants.usersTable,
      operation: SyncConstants.operationUpdate,
      recordId: user.localId ?? user.id.toString(),
      data: jsonEncode(updatedUser.toJson()),
    );

    return updatedUser;
  }

  /// Delete a user locally
  Future<void> deleteUser(int id, String? localId) async {
    final db = await database;

    await db.delete(
      DatabaseConstants.usersTable,
      where: 'id = ? OR local_id = ?',
      whereArgs: [id, localId],
    );

    // Add to pending sync queue
    await _addToPendingSync(
      tableName: DatabaseConstants.usersTable,
      operation: SyncConstants.operationDelete,
      recordId: localId ?? id.toString(),
      data: null,
    );
  }

  /// Get all users (with pending sync status first)
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.usersTable,
      orderBy: 'sync_status ASC, created_at DESC',
    );

    return maps.map((map) => User.fromMap(map)).toList();
  }

  /// Get a user by ID
  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.usersTable,
      where: 'id = ? OR server_id = ? OR local_id = ?',
      whereArgs: [id, id, id],
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Get a user by local ID
  Future<User?> getUserByLocalId(String localId) async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.usersTable,
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Get users pending sync
  Future<List<User>> getPendingUsers() async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.usersTable,
      where: 'sync_status = ?',
      whereArgs: [SyncConstants.syncStatusPending],
    );

    return maps.map((map) => User.fromMap(map)).toList();
  }

  /// Mark user as synced
  Future<void> markUserSynced(User user, int serverId) async {
    final db = await database;
    await db.update(
      DatabaseConstants.usersTable,
      {
        'server_id': serverId,
        'sync_status': SyncConstants.syncStatusSynced,
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? OR local_id = ?',
      whereArgs: [user.id, user.localId],
    );
  }

  // ==================== PENDING SYNC OPERATIONS ====================

  /// Add an operation to the pending sync queue
  Future<void> _addToPendingSync({
    required String tableName,
    required String operation,
    required String recordId,
    String? data,
  }) async {
    final db = await database;
    await db.insert(
      DatabaseConstants.pendingSyncTable,
      {
        'table_name': tableName,
        'operation': operation,
        'record_id': recordId,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      },
    );
  }

  /// Get all pending sync operations
  Future<List<PendingSync>> getPendingSyncs() async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.pendingSyncTable,
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => PendingSync.fromMap(map)).toList();
  }

  /// Remove a pending sync operation
  Future<void> removePendingSync(int id) async {
    final db = await database;
    await db.delete(
      DatabaseConstants.pendingSyncTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update pending sync retry count
  Future<void> updatePendingSyncRetry(int id, String? error) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE ${DatabaseConstants.pendingSyncTable}
      SET retry_count = retry_count + 1, last_error = ?
      WHERE id = ?
    ''', [error, id]);
  }

  /// Clear all pending sync operations for a table
  Future<void> clearPendingSyncsForTable(String tableName) async {
    final db = await database;
    await db.delete(
      DatabaseConstants.pendingSyncTable,
      where: 'table_name = ?',
      whereArgs: [tableName],
    );
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConstants.pendingSyncTable}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== UTILITY METHODS ====================

  /// Clear all data (for logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(DatabaseConstants.usersTable);
    await db.delete(DatabaseConstants.pendingSyncTable);
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
