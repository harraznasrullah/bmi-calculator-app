import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bmi_app1/constants/app_constants.dart';
import 'package:bmi_app1/services/firebase_service.dart';
import 'package:bmi_app1/utils/bmi_history_manager.dart';
import 'package:bmi_app1/services/bmi_storage_service.dart';
import 'package:bmi_app1/utils/event_bus.dart';

class BMICalculatorScreen extends StatefulWidget {
  const BMICalculatorScreen({super.key});

  @override
  State<BMICalculatorScreen> createState() => _BMICalculatorScreenState();
}

class _BMICalculatorScreenState extends State<BMICalculatorScreen> with WidgetsBindingObserver {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  double? _bmiValue;
  String? _bmiCategory;
  Color? _riskColor;
  String? _riskIndicator;

  @override
  void initState() {
    super.initState();
    _loadStoredBMI();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh the stored BMI when the screen comes back to the foreground
      _loadStoredBMI();
    }
  }

  // Load the stored BMI when the screen initializes
  Future<void> _loadStoredBMI() async {
    final storedBMI = await BMIStorageService.loadCurrentBMI();
    if (storedBMI != null) {
      setState(() {
        _bmiValue = double.parse(storedBMI['bmi'].toStringAsFixed(1));
        _bmiCategory = storedBMI['category'];
        _riskColor = _getRiskColor(storedBMI['category']);
        _riskIndicator = storedBMI['riskIndicator'];
      });
    }
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

    // Store in Firestore (online storage)
    bool firestoreSuccess = false;
    try {
      await FirebaseService().saveBMIResult(
        bmiValue: bmi,
        category: category,
        height: heightCm,
        weight: weightKg,
        heightUnit: 'cm',
        weightUnit: 'kg',
      );
      firestoreSuccess = true;
    } catch (e) {
      // Firebase storage failed, but we'll still save locally
    }

    // Store in local storage as backup/primary
    await _saveToLocalHistory(bmi, category, heightCm, weightKg);
    
    // Also store the current BMI for persistent display
    await _saveCurrentBMI(bmi, category, heightCm, weightKg, riskIndicator);

    setState(() {
      _bmiValue = double.parse(bmi.toStringAsFixed(1));
      _bmiCategory = category;
      _riskColor = riskColor;
      _riskIndicator = riskIndicator;
    });

    if (firestoreSuccess) {
      _showSuccessDialog('BMI result saved to your history!');
    } else {
      _showSuccessDialog('BMI result calculated and saved locally. Will sync when online.');
    }
    
    // Emit event to notify other screens that BMI was calculated
    EventBus.instance.emit(Events.bmiCalculated);
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
  
  // Save BMI result to local storage
  Future<void> _saveToLocalHistory(double bmi, String category, double height, double weight) async {
    try {
      await BMIHistoryManager.saveBMIRecord(
        bmi: bmi,
        category: category,
        height: height,
        weight: weight,
      );
    } catch (e) {
      // If local storage fails, we still want the calculation to work
      // Consider using a proper logging solution in production
      // log('Error saving to local history: $e');
    }
  }
  
  // Save current BMI for persistent display
  Future<void> _saveCurrentBMI(double bmi, String category, double height, double weight, String riskIndicator) async {
    try {
      await BMIStorageService.saveCurrentBMI(
        bmi: bmi,
        category: category,
        height: height,
        weight: weight,
        riskIndicator: riskIndicator,
        date: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // If saving current BMI fails, we still want the calculation to work
      // Consider using a proper logging solution in production
      // log('Error saving current BMI: $e');
    }
  }
  
  // Clear the current BMI
  Future<void> _clearCurrentBMI() async {
    try {
      await BMIStorageService.clearCurrentBMI();
    } catch (e) {
      // If clearing the current BMI fails, just continue
      // Consider using a proper logging solution in production
      // log('Error clearing current BMI: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          'BMI Calculator',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                    _clearCurrentBMI();
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