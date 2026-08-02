import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../encryption/encryption_service.dart';

/// Secure storage service that encrypts data at rest
/// Implements Zero-Trust principle of never storing sensitive data in plaintext
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Box<dynamic>? _encryptedBox;
  final EncryptionService _encryptionService = EncryptionService();
  bool _isInitialized = false;

  /// Initialize secure storage with encryption
  Future<void> initialize(String masterPassword) async {
    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Initialize encryption service
      await _encryptionService.initialize(masterPassword);

      // Open encrypted box
      _encryptedBox = await Hive.openBox('sathi_secure_data');

      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Store a value securely (encrypted)
  Future<void> write(String key, dynamic value) async {
    if (!_isInitialized) {
      throw Exception('SecureStorage not initialized');
    }

    try {
      // Convert value to string and encrypt
      final jsonString = jsonEncode(value);
      final encrypted = _encryptionService.encryptData(jsonString);
      
      // Store encrypted data
      await _encryptedBox!.put(key, encrypted);
    } catch (e) {
      rethrow;
    }
  }

  /// Read and decrypt a value
  Future<dynamic> read(String key) async {
    if (!_isInitialized) {
      throw Exception('SecureStorage not initialized');
    }

    try {
      final encrypted = _encryptedBox!.get(key);
      if (encrypted == null) return null;

      // Decrypt data
      final decrypted = _encryptionService.decryptData(encrypted);
      return jsonDecode(decrypted);
    } catch (e) {
      return null;
    }
  }

  /// Delete a value
  Future<void> delete(String key) async {
    if (!_isInitialized) {
      throw Exception('SecureStorage not initialized');
    }

    await _encryptedBox!.delete(key);
  }

  /// Store sensitive token in secure storage
  Future<void> storeToken(String key, String token) async {
    await _secureStorage.write(key: key, value: token);
  }

  /// Read sensitive token from secure storage
  Future<String?> readToken(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Delete token from secure storage
  Future<void> deleteToken(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Clear all secure storage
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    if (_encryptedBox != null) {
      await _encryptedBox!.clear();
    }
    _isInitialized = false;
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}
