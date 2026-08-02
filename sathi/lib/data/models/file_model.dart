import 'package:equatable/equatable.dart';

/// File model for cloud storage
class FileModel extends Equatable {
  final String id;
  final String name;
  final int size;
  final String mimeType;
  final String? encryptedKey;
  final String? createdAt;
  final String? updatedAt;

  const FileModel({
    required this.id,
    required this.name,
    required this.size,
    required this.mimeType,
    this.encryptedKey,
    this.createdAt,
    this.updatedAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      mimeType: json['mimeType'] ?? '',
      encryptedKey: json['encryptedKey'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'mimeType': mimeType,
      'encryptedKey': encryptedKey,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Format file size for display
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  List<Object?> get props => [id, name, size, mimeType, encryptedKey, createdAt, updatedAt];
}
