import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BMIStorageService {
  static const String _currentBMIKey = 'current_bmi_data';
  static const String _userProfileKey = 'user_profile_data';

  // Save current BMI data
  static Future<void> saveCurrentBMI({
    required double bmi,
    required String category,
    required double height,
    required double weight,
    required String riskIndicator,
    required String date,
    int? age,
    String? gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> data = {
      'bmi': bmi,
      'category': category,
      'height': height,
      'weight': weight,
      'riskIndicator': riskIndicator,
      'date': date,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
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

  // Save user profile data (age and gender)
  static Future<void> saveUserProfile({
    int? age,
    String? gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> data = {
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_userProfileKey, jsonEncode(data));
  }

  // Load user profile data
  static Future<Map<String, dynamic>?> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString(_userProfileKey);

    if (dataString != null) {
      final Map<String, dynamic> data = jsonDecode(dataString);
      return data;
    }

    return null;
  }

  // Clear user profile data
  static Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userProfileKey);
  }

  // Get user age from profile
  static Future<int?> getUserAge() async {
    final profile = await loadUserProfile();
    return profile?['age']?.toInt();
  }

  // Get user gender from profile
  static Future<String?> getUserGender() async {
    final profile = await loadUserProfile();
    return profile?['gender'] as String?;
  }
}