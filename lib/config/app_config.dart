// Configuration file for BMI App
class AppConfig {
  // App name
  static const String appName = 'BMI Calculator';

  // Version info
  static const String version = '1.0.0';

  // BMI categories and ranges
  static const Map<String, Map<String, double>> bmiCategories = {
    'underweight': {'min': 0, 'max': 18.4, 'color': 0xFF2196F3}, // Blue
    'normal': {'min': 18.5, 'max': 24.9, 'color': 0xFF4CAF50},  // Green
    'overweight': {'min': 25, 'max': 29.9, 'color': 0xFFFF9800}, // Orange
    'obese': {'min': 30, 'max': 100, 'color': 0xFFF44336},       // Red
  };

  // Height units
  static const List<String> heightUnits = ['cm', 'm', 'ft'];
  
  // Weight units  
  static const List<String> weightUnits = ['kg', 'lbs'];

  // Default height unit
  static const String defaultHeightUnit = 'cm';

  // Default weight unit
  static const String defaultWeightUnit = 'kg';
}