import 'package:equatable/equatable.dart';

/// Device type enum
enum DeviceType {
  light,
  thermostat,
  lock,
  camera,
  sensor,
  switchDevice,
}

/// Device model for smart home
class Device extends Equatable {
  final String id;
  final String name;
  final DeviceType type;
  final String status;
  final Map<String, dynamic> settings;
  final String? createdAt;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.settings,
    this.createdAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: _parseDeviceType(json['type'] ?? ''),
      status: json['status'] ?? 'off',
      settings: json['settings'] ?? {},
      createdAt: json['createdAt'],
    );
  }

  static DeviceType _parseDeviceType(String type) {
    switch (type) {
      case 'light':
        return DeviceType.light;
      case 'thermostat':
        return DeviceType.thermostat;
      case 'lock':
        return DeviceType.lock;
      case 'camera':
        return DeviceType.camera;
      case 'sensor':
        return DeviceType.sensor;
      case 'switch':
        return DeviceType.switchDevice;
      default:
        return DeviceType.sensor;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'status': status,
      'settings': settings,
      'createdAt': createdAt,
    };
  }

  /// Get icon for device type
  String get iconName {
    switch (type) {
      case DeviceType.light:
        return 'lightbulb';
      case DeviceType.thermostat:
        return 'thermostat';
      case DeviceType.lock:
        return 'lock';
      case DeviceType.camera:
        return 'videocam';
      case DeviceType.sensor:
        return 'sensors';
      case DeviceType.switchDevice:
        return 'toggle_on';
    }
  }

  /// Check if device is on
  bool get isOn => status == 'on' || status == 'locked';

  /// Create a copy with updated fields
  Device copyWith({
    String? name,
    String? status,
    Map<String, dynamic>? settings,
  }) {
    return Device(
      id: id,
      name: name ?? this.name,
      type: type,
      status: status ?? this.status,
      settings: settings ?? this.settings,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, type, status, settings, createdAt];
}
