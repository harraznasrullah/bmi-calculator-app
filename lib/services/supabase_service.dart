import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart';
import 'package:flutter/foundation.dart';
import 'package:bmi_calc/utils/event_bus.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._internal();
  SupabaseService._internal();

  late SupabaseClient _client;

  // Initialize Supabase service with the pre-initialized Supabase instance
  Future<void> initialize() async {
    // The client is already initialized via Supabase.initialize() in main.dart
    _client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;

  // Sign up with email and password
  Future<void> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      // The user is automatically signed in after sign up
    } catch (e) {
      throw e; // Re-throw the original exception to preserve error details
    }
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw e; // Re-throw the original exception to preserve error details
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      // Emit logout event to notify screens to clear data
      EventBus.instance.emit(Events.userSignedOut);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get the current authenticated user
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // Get the current user's display name or email
  String? getCurrentUserName() {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    // Try to get display name first, then fall back to email
    String? name = user.userMetadata?['display_name'] ??
                   user.userMetadata?['name'] ??
                   user.userMetadata?['full_name'];

    if (name != null && name.isNotEmpty) {
      return name;
    }

    // Fall back to email if no name is found
    return user.email?.split('@')[0]; // Return the part before @ for a cleaner name
  }

  // Save BMI result to Supabase database
  Future<void> saveBMIResult({
    required double bmiValue,
    required String category,
    required double height,
    required double weight,
    required String heightUnit,
    required String weightUnit,
    int? age,
    String? gender,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final recordData = {
        'user_id': user.id,
        'bmi_value': bmiValue,
        'category': category,
        'height': height,
        'weight': weight,
        'height_unit': heightUnit,
        'weight_unit': weightUnit,
        'created_at': DateTime.now().toIso8601String(),
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
      };

      await _client
          .from('bmi_records') // This is the table name in your Supabase database
          .insert(recordData);
    } catch (e) {
      throw Exception('Failed to save BMI result: $e');
    }
  }

  // Get user's BMI history from Supabase
  Future<List<Map<String, dynamic>>> getBMIHistory() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('bmi_records')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      throw Exception('Failed to get BMI history: $e');
    }
  }

  // Clear user's BMI history from Supabase
  Future<void> clearBMIHistory() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('bmi_records')
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to clear BMI history: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? username,
    String? fullName,
    int? age,
    String? gender,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (fullName != null) updates['full_name'] = fullName;
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _client
          .from('profiles') // This is the profiles table in your Supabase database
          .upsert({
        'id': user.id,
        ...updates,
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      // Profile might not exist yet, which is okay
      return null;
    }
  }
}