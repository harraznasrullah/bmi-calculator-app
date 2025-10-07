import 'package:bmi_calc/config/app_config.dart';
import 'package:bmi_calc/constants/app_constants.dart';

class BMIUtil {
  // Calculate BMI based on height and weight
  static double calculateBMI(double height, double weight, String heightUnit, String weightUnit, {int? age, String? gender}) {
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

    // Calculate basic BMI
    double basicBMI = weightInKg / (heightInMeters * heightInMeters);

    // Apply age and gender adjustments for more accurate assessment
    double adjustedBMI = _applyAgeGenderAdjustments(basicBMI, age, gender);

    return adjustedBMI;
  }

  // Apply age and gender adjustments to BMI
  static double _applyAgeGenderAdjustments(double basicBMI, int? age, String? gender) {
    if (age == null || gender == null) {
      return basicBMI; // No adjustment if age or gender not provided
    }

    double adjustmentFactor = 1.0;

    // Age-based adjustments
    if (age < 18) {
      // For children and adolescents, BMI percentiles are more appropriate
      // This is a simplified adjustment - in practice, pediatric BMI uses percentiles
      adjustmentFactor *= 0.95;
    } else if (age >= 65) {
      // For older adults, higher BMI may be acceptable due to muscle mass loss
      adjustmentFactor *= 1.02;
    }

    // Gender-based adjustments
    if (gender.toLowerCase() == 'male') {
      // Men typically have more muscle mass, which affects BMI interpretation
      if (age >= 18 && age < 40) {
        adjustmentFactor *= 0.98;
      } else if (age >= 40 && age < 65) {
        adjustmentFactor *= 0.99;
      }
    } else if (gender.toLowerCase() == 'female') {
      // Women typically have higher body fat percentage at the same BMI
      if (age >= 18 && age < 40) {
        adjustmentFactor *= 1.02;
      } else if (age >= 40 && age < 65) {
        adjustmentFactor *= 1.01;
      }
    }

    return basicBMI * adjustmentFactor;
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

  // Get age and gender-specific BMI category
  static String getAgeGenderBMICategory(double bmi, int? age, String? gender) {
    if (age == null || gender == null) {
      return getBMICategory(bmi); // Use standard categories if age or gender not provided
    }

    // For children and adolescents, different categories apply
    if (age < 18) {
      return _getPediatricBMICategory(bmi, age);
    }

    // For adults (18+), standard categories apply but we can add gender-specific notes
    String category = getBMICategory(bmi);

    // For older adults (65+), consider slightly different thresholds
    if (age >= 65) {
      if (bmi < 22) {
        return 'Underweight';
      } else if (bmi < 27) {
        return 'Normal weight';
      } else if (bmi < 32) {
        return 'Overweight';
      } else {
        return 'Obese';
      }
    }

    return category;
  }

  // Get pediatric BMI category (simplified for children and adolescents)
  static String _getPediatricBMICategory(double bmi, int age) {
    // This is a simplified approach - in practice, pediatric BMI uses percentiles
    // based on age and gender-specific growth charts

    if (age < 5) {
      if (bmi < 14) return 'Underweight';
      if (bmi < 17) return 'Healthy weight';
      if (bmi < 18) return 'Overweight';
      return 'Obese';
    } else if (age < 10) {
      if (bmi < 14.5) return 'Underweight';
      if (bmi < 18) return 'Healthy weight';
      if (bmi < 20) return 'Overweight';
      return 'Obese';
    } else { // age 10-17
      if (bmi < 16) return 'Underweight';
      if (bmi < 22) return 'Healthy weight';
      if (bmi < 25) return 'Overweight';
      return 'Obese';
    }
  }

  // Get health recommendations based on age, gender, and BMI
  static String getHealthRecommendations(double bmi, int? age, String? gender) {
    String category = getAgeGenderBMICategory(bmi, age, gender);

    if (age == null || gender == null) {
      return _getBasicHealthTips(category);
    }

    if (age < 18) {
      return _getPediatricHealthTips(category, age);
    } else if (age >= 65) {
      return _getSeniorHealthTips(category, gender);
    } else {
      return _getAdultHealthTips(category, gender);
    }
  }

  static String _getBasicHealthTips(String category) {
    switch (category) {
      case 'Underweight':
        return 'Consider consulting with a healthcare provider about healthy weight gain strategies.';
      case 'Normal weight':
        return 'Great job! Maintain your healthy weight with balanced nutrition and regular exercise.';
      case 'Overweight':
        return 'Consider incorporating more physical activity and a balanced diet to reach a healthier weight.';
      case 'Obese':
        return 'Consult with a healthcare professional to create a personalized plan for weight management.';
      default:
        return 'Maintain a healthy lifestyle with balanced nutrition and regular exercise.';
    }
  }

  static String _getAdultHealthTips(String category, String gender) {
    String baseTips = _getBasicHealthTips(category);

    if (gender.toLowerCase() == 'male') {
      switch (category) {
        case 'Overweight':
          return '$baseTips Focus on strength training to maintain muscle mass while losing weight.';
        case 'Normal weight':
          return '$baseTips Include resistance training to preserve muscle mass as you age.';
      }
    } else if (gender.toLowerCase() == 'female') {
      switch (category) {
        case 'Overweight':
          return '$baseTips Consider calcium-rich foods and weight-bearing exercises for bone health.';
        case 'Normal weight':
          return '$baseTips Ensure adequate iron intake and regular weight-bearing exercise.';
      }
    }

    return baseTips;
  }

  static String _getPediatricHealthTips(String category, int age) {
    switch (category) {
      case 'Underweight':
        return 'Focus on nutrient-dense foods and regular meals. Consult with a pediatrician for guidance.';
      case 'Healthy weight':
        return 'Great! Maintain healthy habits with balanced meals and daily physical activity.';
      case 'Overweight':
        return 'Encourage active play and limit screen time. Focus on balanced, portion-controlled meals.';
      case 'Obese':
        return 'Work with a pediatrician to create a healthy lifestyle plan appropriate for your age.';
      default:
        return 'Develop healthy eating habits and stay active!';
    }
  }

  static String _getSeniorHealthTips(String category, String gender) {
    switch (category) {
      case 'Underweight':
        return 'Focus on protein-rich foods and strength training to maintain muscle mass.';
      case 'Normal weight':
        return 'Excellent! Maintain weight with nutrient-dense foods and regular, moderate exercise.';
      case 'Overweight':
        return 'Gentle weight management through balanced nutrition and low-impact activities like walking.';
      case 'Obese':
        return 'Work with healthcare providers on a safe weight management plan considering your overall health.';
      default:
        return 'Focus on maintaining muscle mass and overall health through good nutrition and appropriate exercise.';
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