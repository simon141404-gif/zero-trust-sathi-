import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for tokens using Flutter Secure Storage
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
  }
}
