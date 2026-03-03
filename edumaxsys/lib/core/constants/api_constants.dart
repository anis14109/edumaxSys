// API Configuration Constants
//
// This file contains all the API-related configuration constants
// used throughout the application for connecting to the Laravel backend.

class ApiConstants {
  ApiConstants._();

  /// Base URL for the Laravel API
  /// Update this to match your Laravel server URL
  static const String baseUrl =
      'http://192.168.0.151/edumaxSys/laravel-server/public/api';

  /// API Endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String user = '/user';
  static const String users = '/users';
  static const String userProfile = '/user/profile';
  static const String userPassword = '/user/password';
  static const String userPhoto = '/user/photo';

  /// Request timeout durations
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}

/// Database Constants
///
/// Contains all database-related configuration
class DatabaseConstants {
  DatabaseConstants._();

  static const String databaseName = 'edumaxsys.db';
  static const int databaseVersion = 1;

  /// Table names
  static const String usersTable = 'users';
  static const String pendingSyncTable = 'pending_sync';
}

/// Sync Configuration
///
/// Contains settings for the offline-first sync mechanism
class SyncConstants {
  SyncConstants._();

  /// Auto-sync interval in hours
  static const int autoSyncIntervalHours = 1;

  /// Sync status constants
  static const int syncStatusPending = 0;
  static const int syncStatusSynced = 1;
  static const int syncStatusFailed = 2;

  /// Operation types for sync queue
  static const String operationCreate = 'CREATE';
  static const String operationUpdate = 'UPDATE';
  static const String operationDelete = 'DELETE';
}

/// Storage Keys
///
/// Keys used for secure storage of tokens and user data
class StorageKeys {
  StorageKeys._();

  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String lastSyncTime = 'last_sync_time';
  static const String apiUrl = 'api_url';
}
