import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bmi_app1/config/app_config.dart';
import 'package:bmi_app1/constants/app_constants.dart';
import 'package:bmi_app1/utils/bmi_util.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase initialization is commented out temporarily to troubleshoot blank screen
  // try {
  //   await Firebase.initializeApp();
  // } catch (e) {
  //   print('Firebase initialization error: $e');
  // }
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
      home: const MyHomePage(title: AppConfig.appName),
    );
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
  Color? _bmiColor;
  String _heightUnit = AppConfig.defaultHeightUnit;
  String _weightUnit = AppConfig.defaultWeightUnit;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _calculateBMI() {
    double? height = double.tryParse(_heightController.text);
    double? weight = double.tryParse(_weightController.text);

    if (height == null || weight == null || height <= 0 || weight <= 0) {
      _showErrorDialog('Please enter valid height and weight values.');
      return;
    }

    // Validate ranges
    if ((_heightUnit == 'cm' && (height < Constants.minHeightCm || height > Constants.maxHeightCm)) ||
        (_heightUnit == 'm' && (height < Constants.minHeightCm/100 || height > Constants.maxHeightCm/100)) ||
        (_weightUnit == 'kg' && (weight < Constants.minWeightKg || weight > Constants.maxWeightKg))) {
      _showErrorDialog('Please enter height and weight within valid ranges.');
      return;
    }

    double bmi = BMIUtil.calculateBMI(height, weight, _heightUnit, _weightUnit);

    setState(() {
      _bmiValue = double.parse(bmi.toStringAsFixed(1));
      _bmiCategory = BMIUtil.getBMICategory(bmi);
      _bmiColor = Color(BMIUtil.getBMIColor(bmi));
    });
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
              const Icon(
                Icons.monitor_weight,
                size: 100,
                color: Colors.blue,
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
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Height ($_heightUnit)',
                                hintText: 'Enter your height',
                                prefixIcon: const Icon(Icons.height),
                              ),
                            ),
                          ),
                          const SizedBox(width: Constants.mediumSpacing),
                          DropdownButton<String>(
                            value: _heightUnit,
                            icon: const Icon(Icons.arrow_drop_down),
                            onChanged: (String? newValue) {
                              setState(() {
                                _heightUnit = newValue!;
                              });
                            },
                            items: AppConfig.heightUnits.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: Constants.mediumSpacing),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Weight ($_weightUnit)',
                                hintText: 'Enter your weight',
                                prefixIcon: const Icon(Icons.monitor_weight),
                              ),
                            ),
                          ),
                          const SizedBox(width: Constants.mediumSpacing),
                          DropdownButton<String>(
                            value: _weightUnit,
                            icon: const Icon(Icons.arrow_drop_down),
                            onChanged: (String? newValue) {
                              setState(() {
                                _weightUnit = newValue!;
                              });
                            },
                            items: AppConfig.weightUnits.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ],
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Calculate BMI',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: Constants.extraLargeSpacing),
              if (_bmiValue != null) ...[
                Container(
                  padding: const EdgeInsets.all(Constants.standardPadding * 1.25),
                  decoration: BoxDecoration(
                    color: _bmiColor?.withValues(alpha: 0.1) ?? Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Constants.borderRadius),
                    border: Border.all(color: _bmiColor ?? Colors.blue, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your BMI',
                        style: TextStyle(
                          fontSize: 20,
                          color: _bmiColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Constants.mediumSpacing / 2),
                      Text(
                        '${_bmiValue!}',
                        style: TextStyle(
                          fontSize: Constants.bmiResultFontSize,
                          color: _bmiColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Constants.mediumSpacing / 2),
                      Text(
                        _bmiCategory!,
                        style: TextStyle(
                          fontSize: Constants.categoryFontSize,
                          color: _bmiColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Constants.largeSpacing),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _bmiValue = null;
                        _bmiCategory = null;
                        _bmiColor = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _bmiColor ?? Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                    label: Text(
                      "Reset",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}