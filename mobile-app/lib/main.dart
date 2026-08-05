import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/forget_password_screen.dart';
import 'screens/main_shell.dart';
import 'screens/guest_mode_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cflqazqjfvwadjdmnviv.supabase.co',
    anonKey: 'sb_publishable_I5rkLiVFfmWOXQpmmcU5rg_aw6bFDn_',
  );
  runApp(const SmartCalmApp());
}

final supabase = Supabase.instance.client;

class SmartCalmApp extends StatelessWidget {
  const SmartCalmApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    final session = supabase.auth.currentSession;

    return MaterialApp(
      title: 'SmartCalm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: session != null ? '/home' : '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forget_password': (context) => const ForgetPasswordScreen(),
        '/home': (context) => const MainShell(initialIndex: 0),
        '/guest_mode': (context) => const GuestModeScreen(),
      },
    );
  }
}
