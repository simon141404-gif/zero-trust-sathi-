import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Security service that checks if device is rooted or jailbroken
/// This implements Zero-Trust principles by verifying device integrity
/// Uses method channel to communicate with native code
class DeviceSecurityService {
  static final DeviceSecurityService _instance = DeviceSecurityService._internal();
  factory DeviceSecurityService() => _instance;
  DeviceSecurityService._internal();

  bool _isDeviceCompromised = false;
  bool _securityCheckCompleted = false;

  static const MethodChannel _channel = MethodChannel('com.sathi.security/device');

  /// Check if device is rooted (Android) or jailbroken (iOS)
  /// Returns true if device is compromised
  Future<bool> checkDeviceSecurity() async {
    if (_securityCheckCompleted) {
      return _isDeviceCompromised;
    }

    try {
      // Check for root/jailbreak indicators using method channel
      final bool detected = await _channel.invokeMethod<bool>('isDeviceCompromised') ?? false;

      _isDeviceCompromised = detected;
      _securityCheckCompleted = true;

      if (_isDeviceCompromised) {
        debugPrint('⚠️ SECURITY ALERT: Compromised device detected!');
        debugPrint('Root/Jailbreak detected - device is compromised');
      }

      return _isDeviceCompromised;
    } catch (e) {
      debugPrint('Error checking device security: $e');
      // Assume compromised if we can't verify
      _isDeviceCompromised = true;
      _securityCheckCompleted = true;
      return true;
    }
  }

  /// Check if security check has been completed
  bool get isSecurityCheckCompleted => _securityCheckCompleted;

  /// Check if device is compromised
  bool get isDeviceCompromised => _isDeviceCompromised;

  /// Reset security check (for testing)
  void resetSecurityCheck() {
    _securityCheckCompleted = false;
    _isDeviceCompromised = false;
  }
}
