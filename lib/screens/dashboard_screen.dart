import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:bmi_app1/utils/bmi_history_manager.dart';
import 'package:bmi_app1/utils/event_bus.dart';

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
  String userName = 'John Doe'; // Example user name

  StreamSubscription<String>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadLatestBMI();
    WidgetsBinding.instance.addObserver(this);
    
    // Listen for BMI calculation events
    _eventSubscription = EventBus.instance.stream.listen((event) {
      if (event == Events.bmiCalculated) {
        _loadLatestBMI();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    super.dispose();
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
      final records = await BMIHistoryManager.getBMIHistory();
      if (records.isNotEmpty) {
        // Get the most recent record
        final latestRecord = records[0]; // Most recent is first in the list
        
        // Only update state if the values have changed to avoid unnecessary rebuilds
        if (bmiValue != latestRecord['bmi'] || bmiCategory != latestRecord['category']) {
          setState(() {
            bmiValue = latestRecord['bmi'];
            bmiCategory = latestRecord['category'];
          });
        }
      } else {
        // If no records exist, ensure we reset to empty state
        if (bmiValue != 0 || bmiCategory != '') {
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
    switch (category) {
      case 'Underweight':
        return 'You might benefit from increasing your calorie intake with nutritious foods and regular strength training. Focus on protein-rich foods like chicken, fish, beans, and dairy products to help you gain healthy weight.';
      case 'Normal':
        return 'Great job! Maintain your healthy weight with balanced nutrition and regular exercise. Consider adding variety to your workouts to keep things interesting and challenging.';
      case 'Overweight':
        return 'Consider incorporating more physical activity and a balanced diet to reach a healthier weight. Start with small changes like taking daily walks and reducing portion sizes.';
      case 'Obese':
        return 'Consult with a healthcare professional to create a personalized plan for weight management and improved health. Small, sustainable changes can lead to significant improvements over time.';
      default:
        return 'Maintain a healthy lifestyle with balanced nutrition and regular exercise. Remember that progress takes time, so be patient and consistent with your efforts.';
    }
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
      return Colors.blue; // Underweight
    } else if (bmi < 25) {
      return Colors.green; // Normal
    } else if (bmi < 30) {
      return Colors.orange; // Overweight
    } else {
      return Colors.red; // Obese
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