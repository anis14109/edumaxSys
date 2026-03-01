import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/sync_service.dart';
import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';

/// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService.instance;
});

/// Database Service Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

/// Sync Service Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService.instance;
});

/// User Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Auth State
class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth Notifier
/// 
/// Handles authentication state management using Riverpod.
/// Provides login, logout, and session persistence.
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api = ApiService.instance;
  final DatabaseService _db = DatabaseService.instance;

  AuthNotifier() : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final isAuthenticated = await _api.isAuthenticated();
      
      if (isAuthenticated) {
        // Try to get user from local DB first
        final users = await _db.getAllUsers();
        if (users.isNotEmpty) {
          state = state.copyWith(
            user: users.first,
            isLoading: false,
          );
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Login with email and password
  /// 
  /// This method handles the authentication handshake:
  /// 1. Sends credentials to Laravel /api/login endpoint
  /// 2. Receives Bearer token on success
  /// 3. Stores token securely using flutter_secure_storage
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.login(email: email, password: password);

      if (response.statusCode == 200) {
        final token = response.data['token'] as String;
        final userData = response.data['user'];

        // Store token securely
        await _api.storeToken(token);

        // Create local user
        final user = User.fromJson(userData);
        
        // Save user to local database
        await _db.insertUser(user);

        state = state.copyWith(
          user: user,
          token: token,
          isLoading: false,
        );

        // Trigger initial sync
        await SyncService.instance.sync();

        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Login failed',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  /// Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response.statusCode == 201) {
        final token = response.data['token'] as String;
        final userData = response.data['user'];

        await _api.storeToken(token);

        final user = User.fromJson(userData);
        await _db.insertUser(user);

        state = state.copyWith(
          user: user,
          token: token,
          isLoading: false,
        );

        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _api.logout();
    } catch (e) {
      // Continue with logout even if API fails
    }

    // Clear local data
    await _db.clearAllData();
    await _api.clearStorage();

    state = const AuthState();
  }

  String _getErrorMessage(dynamic e) {
    if (e.toString().contains('socket')) {
      return 'No internet connection';
    }
    return 'Invalid credentials';
  }
}

/// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Users List Provider
final usersProvider = FutureProvider<List<User>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getAllUsers();
});

/// Single User Provider
final userProvider = FutureProvider.family<User?, int>((ref, id) async {
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getUserById(id);
});
