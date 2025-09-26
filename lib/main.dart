import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_page.dart';
import 'screens/bmi_calculator_screen.dart';
import 'screens/history_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Calculator',
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
      },
    );
  }
}

