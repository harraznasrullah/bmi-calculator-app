import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_page.dart';
import 'screens/bmi_calculator_screen.dart';
import 'screens/history_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'services/supabase_service.dart';
import 'services/background_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with Flutter
  await Supabase.initialize(
    url: 'https://hhxkoyitkmljgjepkfpn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhoeGtveWl0a21samdqZXBrZnBuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1MDEzODEsImV4cCI6MjA3NTA3NzM4MX0.mqF1AhwRln15x6_FreN_UUE_AbhRKlGPXjgbFcw9KNo',
  );
  
  // Initialize any additional service configuration
  await SupabaseService.instance.initialize();

  // Initialize background sync service
  BackgroundSyncService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Calc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: const WelcomePage(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/bmi-calculator': (context) => const BMICalculatorScreen(),
        '/history': (context) => const HistoryScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}

