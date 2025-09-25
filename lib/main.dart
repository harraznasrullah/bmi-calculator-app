import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bmi_app1/config/app_config.dart';
import 'package:bmi_app1/constants/app_constants.dart';
import 'package:bmi_app1/services/firebase_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: FutureBuilder(
        future: _initializeFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return const MyHomePage(title: AppConfig.appName);
        },
      ),
    );
  }
  
  Future<void> _initializeFirebase() async {
    try {
      // Try to initialize Firebase, but don't fail if it doesn't work
      await Firebase.initializeApp();
    } catch (e) {
      // Consider using a proper logging solution in production
      // log('Firebase initialization error: $e');
      // Continue anyway so the app still works without Firebase
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  double? _bmiValue;
  String? _bmiCategory;
  Color? _riskColor;
  String? _riskIndicator;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _calculateBMI() async {
    double? heightCm = double.tryParse(_heightController.text);
    double? weightKg = double.tryParse(_weightController.text);

    if (heightCm == null || weightKg == null || heightCm <= 0 || weightKg <= 0) {
      _showErrorDialog('Please enter valid height and weight values.');
      return;
    }

    // Convert to meters for calculation
    double heightM = heightCm / 100;
    double bmi = weightKg / (heightM * heightM);
    
    String category = _getBMICategory(bmi);
    Color riskColor = _getRiskColor(category);
    String riskIndicator = _getRiskIndicator(category);

    // Store in Firestore
    try {
      await FirebaseService().saveBMIResult(
        bmiValue: bmi,
        category: category,
        height: heightCm,
        weight: weightKg,
        heightUnit: 'cm',
        weightUnit: 'kg',
      );
      _showSuccessDialog('BMI result saved successfully!');
    } catch (e) {
      _showErrorDialog('Failed to save result: $e');
    }

    setState(() {
      _bmiValue = double.parse(bmi.toStringAsFixed(1));
      _bmiCategory = category;
      _riskColor = riskColor;
      _riskIndicator = riskIndicator;
    });
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getRiskColor(String category) {
    if (category == 'Normal') return Colors.green;
    if (category == 'Underweight' || category == 'Overweight') return Colors.orange;
    return Colors.red; // Obese
  }

  String _getRiskIndicator(String category) {
    if (category == 'Normal') return 'Green = healthy';
    if (category == 'Underweight' || category == 'Overweight') return 'Yellow = caution';
    return 'Red = high risk'; // Obese
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(Constants.standardPadding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.monitor_weight,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: Constants.largeSpacing),
              Text(
                'BMI Calculator',
                style: GoogleFonts.lato(
                  fontSize: Constants.titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Constants.mediumSpacing / 2),
              Text(
                'Enter your height and weight to calculate your BMI',
                style: GoogleFonts.lato(
                  fontSize: Constants.subtitleFontSize,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Constants.extraLargeSpacing),
              Card(
                elevation: Constants.cardElevation,
                child: Padding(
                  padding: const EdgeInsets.all(Constants.standardPadding * 1.25),
                  child: Column(
                    children: [
                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          hintText: 'Enter your weight in kg',
                          prefixIcon: Icon(Icons.monitor_weight),
                        ),
                      ),
                      const SizedBox(height: Constants.mediumSpacing),
                      TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          hintText: 'Enter your height in cm',
                          prefixIcon: Icon(Icons.height),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Constants.largeSpacing),
              ElevatedButton(
                onPressed: _calculateBMI,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Calculate BMI',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: Constants.extraLargeSpacing),
              if (_bmiValue != null) ...[
                Container(
                  padding: const EdgeInsets.all(Constants.standardPadding * 1.5),
                  decoration: BoxDecoration(
                    color: _riskColor?.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Constants.borderRadius),
                    border: Border.all(color: _riskColor ?? Colors.grey, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your BMI',
                        style: TextStyle(
                          fontSize: 20,
                          color: _riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Constants.mediumSpacing / 2),
                      Text(
                        '${_bmiValue!}',
                        style: TextStyle(
                          fontSize: Constants.bmiResultFontSize,
                          color: _riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Constants.mediumSpacing / 2),
                      Text(
                        _bmiCategory!,
                        style: TextStyle(
                          fontSize: Constants.categoryFontSize,
                          color: _riskColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: Constants.mediumSpacing / 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _riskColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _riskIndicator!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Constants.largeSpacing),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _bmiValue = null;
                      _bmiCategory = null;
                      _riskColor = null;
                      _riskIndicator = null;
                      _weightController.clear();
                      _heightController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}