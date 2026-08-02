import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// AES-256 encryption service for data-at-rest encryption
/// Implements Zero-Trust principle of encrypting sensitive data
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  encrypt.Key? _encryptionKey;
  encrypt.IV? _iv;
  encrypt.Encrypter? _encrypter;
  bool _isInitialized = false;

  /// Initialize encryption with a master password
  /// In production, derive key from user's master password using PBKDF2
  Future<void> initialize(String masterPassword, {String? salt}) async {
    try {
      // Derive a 256-bit key from password using SHA-256
      final saltValue = salt ?? 'sathi-default-salt';
      final keyBytes = _deriveKey(masterPassword, saltValue);
      _encryptionKey = encrypt.Key(keyBytes);

      // Generate IV from key (for simplicity - in production use random IV)
      _iv = encrypt.IV.fromLength(16);

      _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.cbc));
      _isInitialized = true;

      debugPrint('Encryption service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize encryption: $e');
      rethrow;
    }
  }

  /// Derive 256-bit key from password using SHA-256
  Uint8List _deriveKey(String password, String salt) {
    final combined = utf8.encode(password + salt);
    final hash = sha256.convert(combined);
    return Uint8List.fromList(hash.bytes);
  }

  /// Encrypt data using AES-256-CBC
  String encryptData(String plainText) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypted = _encrypter!.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('Encryption error: $e');
      rethrow;
    }
  }

  /// Decrypt data using AES-256-CBC
  String decryptData(String encryptedText) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return _encrypter!.decrypt(encrypted, iv: _iv);
    } catch (e) {
      debugPrint('Decryption error: $e');
      rethrow;
    }
  }

  /// Encrypt bytes using AES-256-CBC
  Uint8List encryptBytes(Uint8List data) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypted = _encrypter!.encryptBytes(data, iv: _iv);
      return encrypted.bytes;
    } catch (e) {
      debugPrint('Bytes encryption error: $e');
      rethrow;
    }
  }

  /// Decrypt bytes using AES-256-CBC
  Uint8List decryptBytes(Uint8List encryptedData) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypted = encrypt.Encrypted(encryptedData);
      final decrypted = _encrypter!.decryptBytes(encrypted, iv: _iv);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      debugPrint('Bytes decryption error: $e');
      rethrow;
    }
  }

  /// Check if encryption is initialized
  bool get isInitialized => _isInitialized;

  /// Generate a secure random key
  static String generateSecureKey() {
    final key = encrypt.Key.fromSecureRandom(32);
    return key.base64;
  }

  /// Generate a secure random IV
  static String generateSecureIV() {
    final iv = encrypt.IV.fromSecureRandom(16);
    return iv.base64;
  }
}
