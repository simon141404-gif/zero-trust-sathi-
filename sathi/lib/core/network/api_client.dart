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
  
  // Demo mode - set to true to work without backend
  static const bool demoMode = true;
  
  // Configure your backend URL here
  static const String baseUrl = 'http://10.0.2.2:3000'; // Android emulator localhost

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
    // Demo mode - simulate login without backend
    if (demoMode) {
      await Future.delayed(const Duration(seconds: 1));
      
      // Validate demo credentials
      if ((username == 'admin' && password == 'admin123') ||
          (username == 'user' && password == 'user123') ||
          (username == 'guest' && password == 'guest123')) {
        return Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 200,
          data: {
            'message': 'Login successful',
            'user': {
              'id': 'demo-user-id',
              'username': username,
              'email': '$username@sathi.demo',
              'role': username == 'admin' ? 'admin' : (username == 'user' ? 'user' : 'guest'),
            },
            'accessToken': 'demo_access_token_12345',
            'refreshToken': 'demo_refresh_token_67890',
          },
        );
      }
      throw DioException(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 401,
          data: {'error': 'Invalid credentials'},
        ),
        message: 'Invalid credentials',
      );
    }
    
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
    if (demoMode) {
      return Response(
        requestOptions: RequestOptions(path: '/api/auth/me'),
        statusCode: 200,
        data: {'user': {'id': 'demo-user-id', 'username': 'demo', 'email': 'demo@sathi.demo', 'role': 'admin'}},
      );
    }
    return await _dio.get('/api/auth/me');
  }

  /// Get files list
  Future<Response> getFiles() async {
    if (demoMode) {
      return Response(
        requestOptions: RequestOptions(path: '/api/storage'),
        statusCode: 200,
        data: {
          'files': [
            {'id': '1', 'name': 'document.pdf', 'size': 1024000, 'mimeType': 'application/pdf', 'uploadedAt': '2024-01-15T10:30:00Z'},
            {'id': '2', 'name': 'photo.jpg', 'size': 2048000, 'mimeType': 'image/jpeg', 'uploadedAt': '2024-01-14T09:20:00Z'},
            {'id': '3', 'name': 'report.docx', 'size': 512000, 'mimeType': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'uploadedAt': '2024-01-13T14:45:00Z'},
          ]
        },
      );
    }
    return await _dio.get('/api/storage');
  }

  /// Upload file metadata
  Future<Response> uploadFile(String name, int size, String mimeType, String encryptedKey) async {
    if (demoMode) {
      return Response(
        requestOptions: RequestOptions(path: '/api/storage'),
        statusCode: 201,
        data: {'message': 'File uploaded successfully', 'id': DateTime.now().millisecondsSinceEpoch.toString()},
      );
    }
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
    if (demoMode) {
      return Response(
        requestOptions: RequestOptions(path: '/api/storage/$fileId'),
        statusCode: 200,
        data: {'message': 'File deleted successfully'},
      );
    }
    return await _dio.delete('/api/storage/$fileId');
  }

  /// Get devices list
  Future<Response> getDevices() async {
    if (demoMode) {
      return Response(
        requestOptions: RequestOptions(path: '/api/smarthome'),
        statusCode: 200,
        data: {
          'devices': [
            {'id': '1', 'name': 'Living Room Light', 'type': 'light', 'status': 'on', 'location': 'Living Room'},
            {'id': '2', 'name': 'Bedroom AC', 'type': 'thermostat', 'status': 'off', 'location': 'Bedroom', 'temperature': 24},
            {'id': '3', 'name': 'Front Door Lock', 'type': 'lock', 'status': 'locked', 'location': 'Entrance'},
            {'id': '4', 'name': 'Kitchen Light', 'type': 'light', 'status': 'on', 'location': 'Kitchen'},
            {'id': '5', 'name': 'Garage Door', 'type': 'garage', 'status': 'closed', 'location': 'Garage'},
          ]
        },
      );
    }
    return await _dio.get('/api/smarthome');
  }

  /// Control device
  Future<Response> controlDevice(String deviceId, String action) async {
    if (demoMode) {
      return Response(
        requestOptions: RequestOptions(path: '/api/smarthome/devices/$deviceId/control'),
        statusCode: 200,
        data: {'message': 'Device controlled successfully', 'deviceId': deviceId, 'action': action},
      );
    }
    return await _dio.post(
      '/api/smarthome/devices/$deviceId/control',
      data: {'action': action},
    );
  }

  /// Update device
  Future<Response> updateDevice(String deviceId, Map<String, dynamic> data) async {
    if (demoMode) {
      return Response(
        requestOptions: RequestOptions(path: '/api/smarthome/devices/$deviceId'),
        statusCode: 200,
        data: {'message': 'Device updated successfully', 'deviceId': deviceId},
      );
    }
    return await _dio.put('/api/smarthome/devices/$deviceId', data: data);
  }

  /// Logout
  Future<Response> logout() async {
    if (demoMode) {
      return Response(
        requestOptions: RequestOptions(path: '/api/auth/logout'),
        statusCode: 200,
        data: {'message': 'Logged out successfully'},
      );
    }
    return await _dio.post('/api/auth/logout');
  }
}
