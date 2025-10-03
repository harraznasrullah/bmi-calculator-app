import 'package:bmi_app1/utils/bmi_history_manager.dart';

class HealthTipsCacheService {
  static final HealthTipsCacheService _instance = HealthTipsCacheService._internal();
  factory HealthTipsCacheService() => _instance;
  HealthTipsCacheService._internal();

  String? _cachedHealthTips;
  double? _cachedBmi;
  String? _cachedCategory;
  String? _cachedError;

  String? get cachedHealthTips => _cachedHealthTips;
  double? get cachedBmi => _cachedBmi;
  String? get cachedCategory => _cachedCategory;
  String? get cachedError => _cachedError;

  bool get hasCachedData => _cachedHealthTips != null;

  // Check if cached data is still valid based on current BMI
  Future<bool> isValidCache() async {
    try {
      final records = await BMIHistoryManager.getBMIHistory();
      
      if (records.isEmpty) {
        return false; // No BMI data, so cache is invalid
      }
      
      final recentRecord = records[0];
      final bmi = recentRecord['bmi'];
      final category = recentRecord['category'];
      
      // Check if BMI and category match cached values (using rounded values for comparison)
      return _cachedBmi?.toStringAsFixed(1) == bmi.toStringAsFixed(1) && _cachedCategory == category;
    } catch (e) {
      return false; // Error checking cache, so it's invalid
    }
  }

  // Update the cached data
  void updateCache(String? healthTips, double? bmi, String? category, String? error) {
    _cachedHealthTips = healthTips;
    _cachedBmi = bmi != null ? double.parse(bmi.toStringAsFixed(1)) : null;
    _cachedCategory = category;
    _cachedError = error;
  }

  // Clear the cache
  void clearCache() {
    _cachedHealthTips = null;
    _cachedBmi = null;
    _cachedCategory = null;
    _cachedError = null;
  }
}