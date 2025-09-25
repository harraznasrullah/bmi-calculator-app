import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save BMI result to Firestore
  Future<void> saveBMIResult({
    required double bmiValue,
    required String category,
    required double height,
    required double weight,
    required String heightUnit,
    required String weightUnit,
  }) async {
    try {
      await _firestore.collection('bmi_results').add({
        'bmiValue': bmiValue,
        'category': category,
        'height': height,
        'weight': weight,
        'heightUnit': heightUnit,
        'weightUnit': weightUnit,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Consider using a proper logging solution in production
      // log('Error saving BMI result: $e');
      rethrow;
    }
  }

  // Get user's BMI history
  Future<QuerySnapshot> getBMIHistory() async {
    try {
      return await _firestore
          .collection('bmi_results')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
    } catch (e) {
      // Consider using a proper logging solution in production
      // log('Error getting BMI history: $e');
      rethrow;
    }
  }

  // Initialize Firebase
  Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Consider using a proper logging solution in production
      // log('Error initializing Firebase: $e');
      rethrow;
    }
  }
}