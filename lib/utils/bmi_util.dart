import 'package:bmi_app1/config/app_config.dart';
import 'package:bmi_app1/constants/app_constants.dart';

class BMIUtil {
  // Calculate BMI based on height and weight
  static double calculateBMI(double height, double weight, String heightUnit, String weightUnit) {
    // Convert height to meters
    double heightInMeters = height;
    if (heightUnit == 'cm') {
      heightInMeters = height * Constants.cmToM; // Convert cm to meters
    } else if (heightUnit == 'ft') {
      heightInMeters = height * 0.3048; // Convert feet to meters
    }
    // If heightUnit is 'm', no conversion needed
    
    // Convert weight to kg
    double weightInKg = weight;
    if (weightUnit == 'lbs') {
      weightInKg = weight * Constants.lbsToKg;
    }
    // If weightUnit is 'kg', no conversion needed
    
    // Calculate BMI
    return weightInKg / (heightInMeters * heightInMeters);
  }

  // Get BMI category based on value
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Normal weight';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  // Get BMI category color
  static int getBMIColor(double bmi) {
    if (bmi < 18.5) {
      return AppConfig.bmiCategories['underweight']!['color']!.toInt();
    } else if (bmi < 25) {
      return AppConfig.bmiCategories['normal']!['color']!.toInt();
    } else if (bmi < 30) {
      return AppConfig.bmiCategories['overweight']!['color']!.toInt();
    } else {
      return AppConfig.bmiCategories['obese']!['color']!.toInt();
    }
  }
  
  // Get healthy BMI range
  static Map<String, double> getHealthyRange() {
    return {
      'min': 18.5,
      'max': 24.9,
    };
  }
  
  // Calculate ideal weight range for given height
  static Map<String, double> getIdealWeightRange(double height, String heightUnit) {
    double heightInMeters = height;
    if (heightUnit == 'cm') {
      heightInMeters = height * 0.01;
    } else if (heightUnit == 'ft') {
      heightInMeters = height * 0.3048;
    }
    
    double minWeight = 18.5 * (heightInMeters * heightInMeters);
    double maxWeight = 24.9 * (heightInMeters * heightInMeters);
    
    return {
      'min': minWeight,
      'max': maxWeight,
    };
  }
}