import 'package:equatable/equatable.dart';

/// User model
class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, username, email, role, createdAt];
}
