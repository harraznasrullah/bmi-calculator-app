import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:bmi_calc/utils/bmi_history_manager.dart';
import 'package:bmi_calc/utils/event_bus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmi_calc/services/supabase_service.dart';
import 'package:bmi_calc/services/sync_service.dart';
import 'package:bmi_calc/services/bmi_storage_service.dart';
import 'package:bmi_calc/utils/bmi_util.dart';

// Dashboard Screen Widget
// This screen displays the user's BMI, health tips based on their BMI, and their name

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  // Mock data for demonstration purposes
  double bmiValue = 0; // Initial BMI value (0 means empty)
  String bmiCategory = ''; // Initial BMI category (empty)
  String userName = 'Guest'; // Default user name
  int? userAge;
  String? userGender;

  StreamSubscription<String>? _eventSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadLatestBMI();
    _loadUserName(); // Load the user's name
    _loadUserProfile(); // Load user's age and gender
    WidgetsBinding.instance.addObserver(this);
    
    // Listen for BMI calculation, login, logout, and sync events
    _eventSubscription = EventBus.instance.stream.listen((event) {
      if (event == Events.bmiCalculated ||
          event == Events.userLoggedIn ||
          event == Events.userSignedOut ||
          event == 'sync_completed' ||
          event == 'background_sync_completed') {
        print('DEBUG: Dashboard received event: $event, refreshing BMI');
        _loadLatestBMI();
      }
    });
    
    // Listen for auth state changes to update the user name
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final eventType = data.event;
      if (eventType == AuthChangeEvent.signedIn || eventType == AuthChangeEvent.userUpdated) {
        _loadUserName();
      } else if (eventType == AuthChangeEvent.signedOut) {
        setState(() {
          userName = 'Guest';
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  // Load the current user's name
  Future<void> _loadUserName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Try to get the username from the profiles table
        final response = await Supabase.instance.client
            .from('profiles')
            .select('username, full_name')
            .eq('id', user.id)
            .single();

        if (response != null) {
          final userData = response as Map<String, dynamic>;
          final username = userData['username'] ?? userData['full_name'] ?? (user.email != null ? user.email!.split('@')[0] : null);
          setState(() {
            userName = username ?? 'User';
          });
        } else {
          // If no profile exists, use email or default
          setState(() {
            userName = (user.email != null ? user.email!.split('@')[0] : null) ?? 'User';
          });
        }
      } else {
        setState(() {
          userName = 'Guest';
        });
      }
    } catch (e) {
      // If there's an error fetching the profile, use the email as fallback
      final user = Supabase.instance.client.auth.currentUser;
      setState(() {
        userName = (user?.email != null ? user!.email!.split('@')[0] : null) ?? 'Guest';
      });
    }
  }

  // Load user profile (age and gender)
  Future<void> _loadUserProfile() async {
    try {
      final profile = await BMIStorageService.loadUserProfile();
      if (profile != null) {
        setState(() {
          userAge = profile['age']?.toInt();
          userGender = profile['gender'];
        });
      }
    } catch (e) {
      // Error loading profile - continue with null values
      print('Error loading user profile: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh the BMI when the app comes back to the foreground
      _loadLatestBMI();
    }
  }

  Future<void> _loadLatestBMI() async {
    try {
      print('DEBUG: Dashboard loading latest BMI...');
      // Use sync service for offline-first BMI history
      final records = await SyncService.getBMIHistoryWithSync(prioritizeLatest: true);
      print('DEBUG: Dashboard found ${records.length} records');

      if (records.isNotEmpty) {
        // Get the most recent record
        final latestRecord = records[0]; // Most recent is first in the list
        print('DEBUG: Latest record: $latestRecord');

        // Handle both Supabase ('bmi_value') and local storage ('bmi') formats
        final recordBmiValue = latestRecord['bmi_value'] ?? latestRecord['bmi'];

        // Only update state if the values have changed to avoid unnecessary rebuilds
        if (bmiValue != recordBmiValue?.toDouble() || bmiCategory != latestRecord['category']) {
          print('DEBUG: Dashboard updating BMI display to: $recordBmiValue, ${latestRecord['category']}');
          setState(() {
            bmiValue = recordBmiValue?.toDouble() ?? 0.0;
            bmiCategory = latestRecord['category'] ?? '';
          });
        } else {
          print('DEBUG: Dashboard BMI unchanged, skipping update');
        }
      } else {
        // If no records exist, ensure we reset to empty state
        if (bmiValue != 0 || bmiCategory != '') {
          print('DEBUG: Dashboard resetting to empty state');
          setState(() {
            bmiValue = 0;
            bmiCategory = '';
          });
        }
      }
    } catch (e) {
      // If there's an error loading history, keep the initial values
      print('Error loading BMI history: $e');
    }
  }

  // Method to manually refresh BMI
  void refreshBMI() {
    _loadLatestBMI();
  }
  
  // Public method to be called from outside to refresh BMI
  Future<void> refreshDashboard() async {
    await _loadLatestBMI();
  }
  
  // Health tips based on BMI category
  String getHealthTips(String category) {
    // Use the new BMIUtil for age and gender-specific recommendations
    return BMIUtil.getHealthRecommendations(bmiValue, userAge, userGender);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          'Dashboard',
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: () => _loadLatestBMI(),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User greeting with animation
                FadeInDown(
                  key: const ValueKey('greeting-animation'),
                  duration: const Duration(milliseconds: 600),
                  child: Text(
                    'Hello, $userName!',
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // User profile information with animation
                if (userAge != null || userGender != null)
                  FadeInDown(
                    key: const ValueKey('profile-animation'),
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (userAge != null) ...[
                            Icon(Icons.cake, size: 16, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '$userAge years',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (userAge != null && userGender != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (userGender != null) ...[
                            Icon(
                              userGender?.toLowerCase() == 'male' ? Icons.male : Icons.female,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              userGender!,
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                
                // BMI display card - now pressable
              GestureDetector(
                onTap: () {
                  _showBMIOptions(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your BMI',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Gear/setting icon at the top right
                          IconButton(
                            icon: Icon(Icons.settings, size: 20,),
                            onPressed: () {
                              _showBMIOptions(context);
                            },
                            color: Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (bmiValue == 0) 
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 60, // Fixed height for the Empty/Value area
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Empty',
                                    style: GoogleFonts.lato(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Please calculate your BMI first',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        )
                      else 
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              bmiValue.toStringAsFixed(1),
                              style: GoogleFonts.lato(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: getColorForBMI(bmiValue),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: getColorForBMI(bmiValue).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                bmiCategory,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: getColorForBMI(bmiValue),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
                const SizedBox(height: 30),
                
                // Health tips card with animation
                FadeInUp(
                  key: const ValueKey('health-tips-animation'),
                  duration: const Duration(milliseconds: 1000),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health Tips for You',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          getHealthTips(bmiCategory),
                          style: GoogleFonts.lato(
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Additional motivational message
                FadeInUp(
                  key: const ValueKey('motivational-message-animation'),
                  duration: const Duration(milliseconds: 1200),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        'Remember: Small steps lead to big changes. Keep up the great work!',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to get color based on BMI value
  Color getColorForBMI(double bmi) {
    if (bmi < 18.5) {
      return const Color(0xFF1565C0); // Deep Blue - underweight (concerning)
    } else if (bmi < 25) {
      return const Color(0xFF2E7D32); // Dark Green - normal (healthy)
    } else if (bmi < 30) {
      return const Color(0xFFF57C00); // Deep Orange - overweight (warning)
    } else {
      return const Color(0xFFC62828); // Dark Red - obese (serious risk)
    }
  }

  // Show BMI options popup
  void _showBMIOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('BMI Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calculate),
                title: const Text('BMI Calculator'),
                onTap: () async {
                  Navigator.of(context).pop();
                  // Navigate to BMI calculator screen and wait for it to return
                  await Navigator.pushNamed(context, '/bmi-calculator');
                  // Refresh the BMI after returning from the calculator
                  _loadLatestBMI();
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('BMI History'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Navigate to BMI history screen
                  Navigator.pushNamed(context, '/history');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}