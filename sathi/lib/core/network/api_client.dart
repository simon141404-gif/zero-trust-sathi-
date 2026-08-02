import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';

/// API Client with JWT authentication
/// Implements Zero-Trust by requiring authentication for all requests
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;
  final SecureStorageService _storage = SecureStorageService();
  
  // Configure your backend URL here
  static const String baseUrl = 'http://10.0.2.2:3000'; // Android emulator localhost
  // For real device, use your server's IP address

  bool _isInitialized = false;

  /// Initialize the API client
  void initialize() {
    if (_isInitialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add JWT token to all requests
        final token = await _storage.readToken('accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors - try to refresh token
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the request
            final token = await _storage.readToken('accessToken');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ));

    _isInitialized = true;
    debugPrint('API Client initialized with base URL: $baseUrl');
  }

  /// Refresh the access token using refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.readToken('refreshToken');
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {}), // Don't add auth header for refresh
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        await _storage.storeToken('accessToken', newAccessToken);
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return false;
  }

  /// Login user
  Future<Response> login(String username, String password) async {
    return await _dio.post(
      '/api/auth/login',
      data: {'username': username, 'password': password},
    );
  }

  /// Register user
  Future<Response> register(String username, String email, String password) async {
    return await _dio.post(
      '/api/auth/register',
      data: {'username': username, 'email': email, 'password': password},
    );
  }

  /// Get current user info
  Future<Response> getCurrentUser() async {
    return await _dio.get('/api/auth/me');
  }

  /// Get files list
  Future<Response> getFiles() async {
    return await _dio.get('/api/storage');
  }

  /// Upload file metadata
  Future<Response> uploadFile(String name, int size, String mimeType, String encryptedKey) async {
    return await _dio.post(
      '/api/storage',
      data: {
        'name': name,
        'size': size,
        'mimeType': mimeType,
        'encryptedKey': encryptedKey,
      },
    );
  }

  /// Delete file
  Future<Response> deleteFile(String fileId) async {
    return await _dio.delete('/api/storage/$fileId');
  }

  /// Get devices list
  Future<Response> getDevices() async {
    return await _dio.get('/api/smarthome');
  }

  /// Control device
  Future<Response> controlDevice(String deviceId, String action) async {
    return await _dio.post(
      '/api/smarthome/devices/$deviceId/control',
      data: {'action': action},
    );
  }

  /// Update device
  Future<Response> updateDevice(String deviceId, Map<String, dynamic> data) async {
    return await _dio.put('/api/smarthome/devices/$deviceId', data: data);
  }

  /// Logout
  Future<Response> logout() async {
    return await _dio.post('/api/auth/logout');
  }
}
