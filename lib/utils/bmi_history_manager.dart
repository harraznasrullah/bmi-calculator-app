import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BMIHistoryManager {
  static const String _historyKey = 'bmi_history';

  // Save a new BMI record
  static Future<void> saveBMIRecord({
    required double bmi,
    required String category,
    required double height,
    required double weight,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_historyKey) ?? <String>[];

    // Create a new record with timestamp
    final record = {
      'date': DateTime.now().toIso8601String(),
      'bmi': bmi,
      'category': category,
      'height': height,
      'weight': weight,
    };

    // Convert to JSON string and add to the beginning of the list
    history.insert(0, jsonEncode(record));
    
    // Keep only the last 50 records to prevent storage bloat
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    await prefs.setStringList(_historyKey, history);
  }

  // Get all BMI records
  static Future<List<Map<String, dynamic>>> getBMIHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? history = prefs.getStringList(_historyKey);

    if (history == null || history.isEmpty) {
      return [];
    }

    // Convert from JSON strings back to maps
    return history.map((jsonString) {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded;
    }).toList();
  }

  // Clear all history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}