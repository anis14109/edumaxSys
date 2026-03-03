import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  static final ApiService instance = ApiService._();
  
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _baseUrl = ApiConstants.baseUrl;

  ApiService._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _updateBaseUrl();
          options.baseUrl = _baseUrl;
          
          final token = await _storage.read(key: StorageKeys.authToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _storage.deleteAll();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _updateBaseUrl() async {
    final customUrl = await _storage.read(key: StorageKeys.apiUrl);
    if (customUrl != null && customUrl.isNotEmpty) {
      _baseUrl = customUrl;
    } else {
      _baseUrl = ApiConstants.baseUrl;
    }
  }

  Future<void> refreshBaseUrl() async {
    await _updateBaseUrl();
  }

  // ==================== AUTHENTICATION ====================

  /// Login user with email and password
  /// 
  /// Makes POST request to /api/login with credentials.
  /// Returns user data and Bearer token on success.
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await _dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  /// Register a new user
  Future<Response> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _dio.post(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  /// Logout user and revoke token
  Future<Response> logout() async {
    return await _dio.post(ApiConstants.logout);
  }

  // ==================== USER PROFILE ====================

  /// Get current authenticated user
  Future<Response> getCurrentUser() async {
    return await _dio.get(ApiConstants.user);
  }

  /// Update user profile
  Future<Response> updateProfile({
    required String name,
    required String email,
  }) async {
    return await _dio.put(
      ApiConstants.userProfile,
      data: {
        'name': name,
        'email': email,
      },
    );
  }

  /// Update user password
  Future<Response> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _dio.put(
      ApiConstants.userPassword,
      data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  /// Upload user profile photo
  Future<Response> updatePhoto(String filePath) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
    });
    
    return await _dio.post(
      ApiConstants.userPhoto,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  // ==================== USER CRUD ====================

  /// Get all users (paginated)
  Future<Response> getUsers({int perPage = 15}) async {
    return await _dio.get(
      ApiConstants.users,
      queryParameters: {'per_page': perPage},
    );
  }

  /// Get a single user by ID
  Future<Response> getUser(int id) async {
    return await _dio.get('${ApiConstants.users}/$id');
  }

  /// Create a new user
  Future<Response> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    return await _dio.post(
      ApiConstants.users,
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  /// Update an existing user
  Future<Response> updateUser({
    required int id,
    String? name,
    String? email,
    String? password,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (password != null) data['password'] = password;

    return await _dio.put('${ApiConstants.users}/$id', data: data);
  }

  /// Delete a user
  Future<Response> deleteUser(int id) async {
    return await _dio.delete('${ApiConstants.users}/$id');
  }

  // ==================== TOKEN MANAGEMENT ====================

  /// Store auth token securely
  Future<void> storeToken(String token) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
  }

  /// Get stored auth token
  Future<String?> getToken() async {
    return await _storage.read(key: StorageKeys.authToken);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored data
  Future<void> clearStorage() async {
    await _storage.deleteAll();
  }
}
