import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/inicio_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

 await Supabase.initialize(
  url: 'https://hjuqggbtisdqtmrtmzmu.supabase.co',
  anonKey: 'sb_publishable_KWaGtg-8xdR7A2HDyalE9g_NtLt3kmJ',
);

  await NotificationService.init();

  runApp(const MedFindApp());
}

final supabase = Supabase.instance.client;

class MedFindApp extends StatelessWidget {
  const MedFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedFind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BCD4),
          primary: const Color(0xFF00BCD4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0FBFC),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BCD4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        useMaterial3: true,
      ),
      home: supabase.auth.currentSession != null
          ? const InicioScreen()
          : const LoginScreen(),
    );
  }
}