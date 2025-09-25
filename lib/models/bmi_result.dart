import 'package:cloud_firestore/cloud_firestore.dart';

class BMIResult {
  final double bmiValue;
  final String category;
  final String interpretation;
  final DateTime timestamp;
  final double height;
  final double weight;
  final String heightUnit;
  final String weightUnit;

  BMIResult({
    required this.bmiValue,
    required this.category,
    required this.interpretation,
    required this.timestamp,
    required this.height,
    required this.weight,
    required this.heightUnit,
    required this.weightUnit,
  });

  // Factory constructor to create a BMIResult from a map
  factory BMIResult.fromMap(Map<String, dynamic> data) {
    return BMIResult(
      bmiValue: data['bmiValue']?.toDouble() ?? 0.0,
      category: data['category'] ?? '',
      interpretation: data['interpretation'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      height: data['height']?.toDouble() ?? 0.0,
      weight: data['weight']?.toDouble() ?? 0.0,
      heightUnit: data['heightUnit'] ?? 'cm',
      weightUnit: data['weightUnit'] ?? 'kg',
    );
  }

  // Convert BMIResult to a map
  Map<String, dynamic> toMap() {
    return {
      'bmiValue': bmiValue,
      'category': category,
      'interpretation': interpretation,
      'timestamp': Timestamp.fromDate(timestamp),
      'height': height,
      'weight': weight,
      'heightUnit': heightUnit,
      'weightUnit': weightUnit,
    };
  }
}