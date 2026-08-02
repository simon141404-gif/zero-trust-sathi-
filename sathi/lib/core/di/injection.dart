import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';
import '../encryption/encryption_service.dart';
import '../security/device_security_service.dart';
import '../../presentation/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

/// Initialize dependency injection
Future<void> initDependencies() async {
  // Services
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  getIt.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  getIt.registerLazySingleton<EncryptionService>(() => EncryptionService());
  getIt.registerLazySingleton<DeviceSecurityService>(() => DeviceSecurityService());

  // BLoCs
  getIt.registerFactory<AuthBloc>(() => AuthBloc());

  // Initialize API client
  getIt<ApiClient>().initialize();
}
