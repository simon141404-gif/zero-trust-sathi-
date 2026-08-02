import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/user.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;

  const AuthRegisterRequested({
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [username, email, password];
}

class AuthLogoutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final token = await _storage.readToken('accessToken');
      if (token != null) {
        final response = await _apiClient.getCurrentUser();
        if (response.statusCode == 200) {
          final user = User.fromJson(response.data['user']);
          emit(AuthAuthenticated(user: user));
          return;
        }
      }
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _apiClient.login(event.username, event.password);
      
      if (response.statusCode == 200) {
        // Store tokens securely
        await _storage.storeToken('accessToken', response.data['accessToken']);
        await _storage.storeToken('refreshToken', response.data['refreshToken']);
        
        final user = User.fromJson(response.data['user']);
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: response.data['error'] ?? 'Login failed'));
      }
    } catch (e) {
      String errorMessage = 'Login failed';
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        errorMessage = 'Cannot connect to server. Make sure backend is running on port 3000';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout. Check your internet connection';
      } else if (e.toString().contains('DioException')) {
        errorMessage = 'Network error. Please try again';
      }
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _apiClient.register(
        event.username,
        event.email,
        event.password,
      );
      
      if (response.statusCode == 201) {
        // Store tokens securely
        await _storage.storeToken('accessToken', response.data['accessToken']);
        await _storage.storeToken('refreshToken', response.data['refreshToken']);
        
        final user = User.fromJson(response.data['user']);
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: response.data['error'] ?? 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _apiClient.logout();
    } catch (_) {
      // Ignore logout errors
    } finally {
      await _storage.deleteToken('accessToken');
      await _storage.deleteToken('refreshToken');
      emit(AuthUnauthenticated());
    }
  }
}
