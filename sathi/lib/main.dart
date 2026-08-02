import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/security/device_security_service.dart';
import 'presentation/bloc/auth_bloc.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/security_alert_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies
  await initDependencies();
  
  // Check device security (root/jailbreak detection)
  final deviceSecurity = DeviceSecurityService();
  final isCompromised = await deviceSecurity.checkDeviceSecurity();
  
  runApp(SathiApp(checkDeviceSecurity: isCompromised));
}

class SathiApp extends StatelessWidget {
  final bool checkDeviceSecurity;
  
  const SathiApp({
    super.key,
    required this.checkDeviceSecurity,
  });

  @override
  Widget build(BuildContext context) {
    // If device is compromised, show security alert and don't run app
    if (checkDeviceSecurity) {
      return MaterialApp(
        title: 'Sathi - Security Alert',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        home: const SecurityAlertScreen(),
      );
    }

    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(AuthCheckRequested()),
      child: MaterialApp(
        title: 'Sathi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1), // Indigo
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
