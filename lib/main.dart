import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lightmode/core/theme/app_theme.dart';
import 'package:lightmode/core/backend/config/supabase_config.dart';
import 'package:lightmode/core/backend/services/storage_service.dart';
import 'package:lightmode/core/backend/services/supabase_service.dart';
import 'package:lightmode/core/backend/services/notification_service.dart';
import 'package:lightmode/core/backend/services/auth_service.dart';
import 'package:lightmode/core/backend/providers/auth_provider.dart';
import 'package:lightmode/core/backend/providers/notification_provider.dart';
import 'package:lightmode/core/backend/services/api_service.dart';
import 'package:lightmode/core/backend/services/security_logic.dart';
import 'package:lightmode/features/auth/presentation/pages/login_screen.dart';
import 'package:lightmode/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:lightmode/features/student/presentation/pages/student_dashboard.dart';
import 'package:lightmode/features/officer/presentation/pages/officer_dashboard.dart';
import 'package:lightmode/features/officer/presentation/pages/verification_view.dart';
import 'package:lightmode/features/admin/presentation/pages/admin_hub.dart';

import 'package:lightmode/features/auth/presentation/pages/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await StorageService.instance.init();
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<SupabaseService>(create: (_) => SupabaseService()),
        ProxyProvider<SupabaseService, AuthService>(
          update: (_, supabase, __) => AuthService(supabase),
        ),
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (_, authService, authProvider) => authProvider ?? AuthProvider(authService),
        ),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<ApiService>(create: (_) => ApiService(baseUrl: 'http://143.110.169.243:8011')),
        ProxyProvider2<SupabaseService, NotificationService, SecurityLogic>(
          update: (_, supabase, notification, __) => SecurityLogic(supabase, notification),
        ),
        ChangeNotifierProxyProvider2<SupabaseService, AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(
            Provider.of<SupabaseService>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '',
          ),
          update: (_, supabase, auth, previous) => previous ?? NotificationProvider(supabase, auth.currentUser?.id ?? ''),
        ),
      ],
      child: const SecureGateApp(),
    ),
  );
}

class SecureGateApp extends StatelessWidget {
  const SecureGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureGate AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/student': (context) => const StudentDashboard(),
        '/officer': (context) => const OfficerDashboard(),
        '/officer/verify': (context) => const VerificationView(),
        '/admin': (context) => const AdminHub(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (auth.isAuthenticated) {
          final user = auth.currentUser;
          if (user?.role == 'admin') {
            return const AdminHub();
          } else if (user?.role == 'officer') {
            return const OfficerDashboard();
          } else {
            return const StudentDashboard();
          }
        }

        return const LoginScreen();
      },
    );
  }
}
