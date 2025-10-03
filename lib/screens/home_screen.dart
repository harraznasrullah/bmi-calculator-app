import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart'; // Import the Dashboard screen
import 'bmi_calculator_screen.dart'; // Import the BMI calculator screen
import 'health_tips_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart'; // Import the Settings screen
import '../widgets/bottom_nav_bar.dart'; // Import the bottom navigation bar widget

// Home Screen with Bottom Navigation Bar
// This is the main screen that displays the bottom navigation bar
// and manages the different screens for each tab

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Track current tab index
  
  @override
  Widget build(BuildContext context) {
    // Get a list of screens
    final List<Widget> screens = [
      const DashboardScreen(), // Dashboard tab
      const BMICalculatorScreen(), // BMI Calculator tab
      const HealthTipsScreen(), // Health Tips tab
      const HistoryScreen(), // History tab
      const SettingsScreen(), // Settings tab
    ];
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}