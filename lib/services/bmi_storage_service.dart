import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BMIStorageService {
  static const String _currentBMIKey = 'current_bmi_data';

  // Save current BMI data
  static Future<void> saveCurrentBMI({
    required double bmi,
    required String category,
    required double height,
    required double weight,
    required String riskIndicator,
    required String date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final Map<String, dynamic> data = {
      'bmi': bmi,
      'category': category,
      'height': height,
      'weight': weight,
      'riskIndicator': riskIndicator,
      'date': date,
    };

    await prefs.setString(_currentBMIKey, jsonEncode(data));
  }

  // Load current BMI data
  static Future<Map<String, dynamic>?> loadCurrentBMI() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString(_currentBMIKey);

    if (dataString != null) {
      final Map<String, dynamic> data = jsonDecode(dataString);
      return data;
    }

    return null;
  }

  // Clear current BMI data
  static Future<void> clearCurrentBMI() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentBMIKey);
  }
}