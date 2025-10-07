import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bmi_calc/services/supabase_service.dart';
import 'package:bmi_calc/services/bmi_storage_service.dart';
import 'package:bmi_calc/utils/bmi_history_manager.dart';
import 'package:bmi_calc/utils/event_bus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  static const String _pendingSyncKey = 'pending_bmi_sync';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _cachedHistoryKey = 'cached_bmi_history';

  // Save BMI record with sync capability
  static Future<void> saveBMIWithSync({
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
      final user = SupabaseService.instance.getCurrentUser();

      if (user != null) {
        // User is logged in, try to save to Supabase first
        try {
          await SupabaseService.instance.saveBMIResult(
            bmiValue: bmiValue,
            category: category,
            height: height,
            weight: weight,
            heightUnit: heightUnit,
            weightUnit: weightUnit,
            age: age,
            gender: gender,
          );
          // If successful, save locally for offline access
          await _saveToLocalCache(bmiValue, category, height, weight, age, gender);
        } catch (e) {
          // Supabase failed, save to pending sync queue
          await _saveToPendingSync(
            bmiValue: bmiValue,
            category: category,
            height: height,
            weight: weight,
            heightUnit: heightUnit,
            weightUnit: weightUnit,
            age: age,
            gender: gender,
          );
          // Also save to local storage for immediate access
          await BMIHistoryManager.saveBMIRecord(
            bmi: bmiValue,
            category: category,
            height: height,
            weight: weight,
            age: age,
            gender: gender,
          );
          print('DEBUG: BMI saved locally due to offline/failed connection');
        }
      } else {
        // User is not logged in, save only to local storage
        await BMIHistoryManager.saveBMIRecord(
          bmi: bmiValue,
          category: category,
          height: height,
          weight: weight,
          age: age,
          gender: gender,
        );
        print('DEBUG: BMI saved locally for guest user');
      }
    } catch (e) {
      // Fallback to local storage
      await BMIHistoryManager.saveBMIRecord(
        bmi: bmiValue,
        category: category,
        height: height,
        weight: weight,
        age: age,
        gender: gender,
      );
    }
  }

  // Get BMI history with offline support
  static Future<List<Map<String, dynamic>>> getBMIHistoryWithSync({bool prioritizeLatest = false}) async {
    try {
      final user = SupabaseService.instance.getCurrentUser();
      print('DEBUG: SyncService getting BMI history, user logged in: ${user != null}');

      if (user != null) {
        // User is logged in
        final localRecords = await BMIHistoryManager.getBMIHistory();
        print('DEBUG: SyncService got ${localRecords.length} local records first');

        if (prioritizeLatest && localRecords.isNotEmpty) {
          // For dashboard display, prioritize latest local record for immediate display
          print('DEBUG: SyncService immediately returning local records to ensure latest BMI shows in dashboard');
          return localRecords;
        }

        // For history display, get both online and local records and merge them
        try {
          final onlineRecords = await SupabaseService.instance.getBMIHistory();
          print('DEBUG: SyncService got ${onlineRecords.length} online records');

          // Cache the online records for offline access
          await _cacheOnlineRecords(onlineRecords);

          // Merge online and local records (online records take precedence for duplicates)
          final mergedRecords = await _mergeOnlineAndLocalRecords(onlineRecords, localRecords);
          print('DEBUG: SyncService returning ${mergedRecords.length} merged records');
          return mergedRecords;
        } catch (e) {
          // Supabase failed (offline), use cached records
          print('DEBUG: SyncService offline mode, getting cached records');
          final cachedRecords = await _getCachedRecords();

          if (localRecords.isNotEmpty) {
            // Merge cached records with local records
            final mergedRecords = await _mergeOnlineAndLocalRecords(cachedRecords, localRecords);
            return mergedRecords;
          }

          return cachedRecords;
        }
      } else {
        // User is not logged in, return local records
        final localRecords = await BMIHistoryManager.getBMIHistory();
        print('DEBUG: SyncService returning ${localRecords.length} local records for guest user');
        return localRecords;
      }
    } catch (e) {
      // Fallback to local records
      print('DEBUG: SyncService fallback, getting local records due to error: $e');
      return await BMIHistoryManager.getBMIHistory();
    }
  }

  // Sync pending records when online
  static Future<void> syncPendingRecords() async {
    try {
      final user = SupabaseService.instance.getCurrentUser();
      if (user == null) return;

      final pendingRecords = await _getPendingSyncRecords();
      if (pendingRecords.isEmpty) return;

      int syncedCount = 0;
      List<Map<String, dynamic>> failedRecords = [];

      for (final record in pendingRecords) {
        try {
          await SupabaseService.instance.saveBMIResult(
            bmiValue: record['bmi_value'],
            category: record['category'],
            height: record['height'],
            weight: record['weight'],
            heightUnit: record['height_unit'],
            weightUnit: record['weight_unit'],
            age: record['age']?.toInt(),
            gender: record['gender'],
          );
          syncedCount++;
        } catch (e) {
          failedRecords.add(record);
        }
      }

      // Update pending sync list
      await _updatePendingSyncRecords(failedRecords);

      // Update last sync timestamp
      await _updateLastSyncTimestamp();

      if (syncedCount > 0) {
        // Emit event to refresh UI
        EventBus.instance.emit('sync_completed');
      }
    } catch (e) {
      print('Sync failed: $e');
    }
  }

  // Check if there are pending records to sync
  static Future<bool> hasPendingSync() async {
    final pendingRecords = await _getPendingSyncRecords();
    return pendingRecords.isNotEmpty;
  }

  // Get pending sync records count
  static Future<int> getPendingSyncCount() async {
    final pendingRecords = await _getPendingSyncRecords();
    return pendingRecords.length;
  }

  // Private methods

  static Future<void> _saveToPendingSync({
    required double bmiValue,
    required String category,
    required double height,
    required double weight,
    required String heightUnit,
    required String weightUnit,
    int? age,
    String? gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pendingList = prefs.getStringList(_pendingSyncKey) ?? [];

    final record = {
      'bmi_value': bmiValue,
      'category': category,
      'height': height,
      'weight': weight,
      'height_unit': heightUnit,
      'weight_unit': weightUnit,
      'created_at': DateTime.now().toIso8601String(),
      'pending_sync': true,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
    };

    pendingList.add(jsonEncode(record));
    await prefs.setStringList(_pendingSyncKey, pendingList);
  }

  static Future<List<Map<String, dynamic>>> _getPendingSyncRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? pendingList = prefs.getStringList(_pendingSyncKey);

    if (pendingList == null || pendingList.isEmpty) {
      return [];
    }

    return pendingList.map((jsonString) {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded;
    }).toList();
  }

  static Future<void> _updatePendingSyncRecords(List<Map<String, dynamic>> records) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pendingList = records
        .map((record) => jsonEncode(record))
        .toList();
    await prefs.setStringList(_pendingSyncKey, pendingList);
  }

  static Future<void> _saveToLocalCache(
    double bmiValue,
    String category,
    double height,
    double weight,
    int? age,
    String? gender,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> cachedList = prefs.getStringList(_cachedHistoryKey) ?? [];

    final record = {
      'bmi_value': bmiValue,
      'category': category,
      'height': height,
      'weight': weight,
      'created_at': DateTime.now().toIso8601String(),
      'cached': true,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
    };

    // Add to beginning of list and keep only last 50 records
    cachedList.insert(0, jsonEncode(record));
    if (cachedList.length > 50) {
      cachedList.removeRange(50, cachedList.length);
    }

    await prefs.setStringList(_cachedHistoryKey, cachedList);
  }

  static Future<void> _cacheOnlineRecords(List<Map<String, dynamic>> records) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> cachedList = records
        .map((record) => jsonEncode(record))
        .toList();
    await prefs.setStringList(_cachedHistoryKey, cachedList);
  }

  static Future<List<Map<String, dynamic>>> _getCachedRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? cachedList = prefs.getStringList(_cachedHistoryKey);

    if (cachedList == null || cachedList.isEmpty) {
      return [];
    }

    return cachedList.map((jsonString) {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded;
    }).toList();
  }

  static Future<void> _updateLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timestamp = prefs.getString(_lastSyncKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  // Merge online and local records, removing duplicates
  static List<Map<String, dynamic>> _mergeOnlineAndLocalRecords(
    List<Map<String, dynamic>> onlineRecords,
    List<Map<String, dynamic>> localRecords,
  ) {
    print('DEBUG: Merge - Online records: ${onlineRecords.length}');
    print('DEBUG: Merge - Local records: ${localRecords.length}');

    // Combine both lists - LOCAL RECORDS FIRST for priority
    List<Map<String, dynamic>> allRecords = [...localRecords, ...onlineRecords];
    print('DEBUG: Merge - Combined records before sorting: ${allRecords.length}');

    // Print all records before sorting
    for (int i = 0; i < allRecords.length; i++) {
      final record = allRecords[i];
      final bmi = record['bmi_value'] ?? record['bmi'];
      final dateStr = record['created_at'] ?? record['date'];
      print('DEBUG: Record[$i] BEFORE sorting: BMI=$bmi, Date=$dateStr');
    }

    // Sort by date (newest first)
    allRecords.sort((a, b) {
      // Handle both timestamp formats: with and without timezone info
      String dateStrA = a['created_at'] ?? a['date'];
      String dateStrB = b['created_at'] ?? b['date'];

      // Normalize both timestamps to UTC for consistent comparison
      DateTime dateA = DateTime.parse(dateStrA).toUtc();
      DateTime dateB = DateTime.parse(dateStrB).toUtc();

      print('DEBUG: SORTING COMPARISON - $dateA vs $dateB, result: ${dateB.compareTo(dateA)}');

      return dateB.compareTo(dateA);
    });

    // Print all records after sorting
    for (int i = 0; i < allRecords.length; i++) {
      final record = allRecords[i];
      final bmi = record['bmi_value'] ?? record['bmi'];
      final dateStr = record['created_at'] ?? record['date'];
      print('DEBUG: Record[$i] AFTER sorting: BMI=$bmi, Date=$dateStr');
    }

    // Remove duplicates based on BMI value, category, and timestamp (within 1 minute)
    List<Map<String, dynamic>> uniqueRecords = [];
    Set<String> seenSignatures = {};

    for (final record in allRecords) {
      final date = DateTime.parse(record['created_at'] ?? record['date']);
      final bmi = record['bmi_value'] ?? record['bmi'];
      final category = record['category'];

      // Create a signature to identify duplicates (same BMI, category, and exact time to second precision)
      final signature = '${bmi}_${category}_${date.year}-${date.month}-${date.day}-${date.hour}-${date.minute}-${date.second}';

      if (!seenSignatures.contains(signature)) {
        seenSignatures.add(signature);
        uniqueRecords.add(record);
        print('DEBUG: Merge - Added record: BMI=$bmi, Category=$category, Date=$date');
      } else {
        print('DEBUG: Merge - Skipped duplicate: BMI=$bmi, Category=$category, Date=$date');
      }
    }

    print('DEBUG: Merge - Final unique records: ${uniqueRecords.length}');
    if (uniqueRecords.isNotEmpty) {
      final latest = uniqueRecords[0];
      final latestBmi = latest['bmi_value'] ?? latest['bmi'];
      final latestCategory = latest['category'];
      final latestDate = latest['created_at'] ?? latest['date'];
      print('DEBUG: Merge - Latest record WILL BE: BMI=$latestBmi, Category=$latestCategory, Date=$latestDate');
    }

    return uniqueRecords;
  }

  // Check if local BMI data exists
  static Future<bool> hasLocalBMIData() async {
    try {
      final localRecords = await BMIHistoryManager.getBMIHistory();
      return localRecords.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get local BMI data count
  static Future<int> getLocalBMIDataCount() async {
    try {
      final localRecords = await BMIHistoryManager.getBMIHistory();
      return localRecords.length;
    } catch (e) {
      return 0;
    }
  }

  // Transfer all local BMI data to Supabase
  static Future<bool> transferLocalBMIDataToAccount() async {
    try {
      final user = SupabaseService.instance.getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final localRecords = await BMIHistoryManager.getBMIHistory();
      if (localRecords.isEmpty) {
        return true; // No data to transfer
      }

      print('DEBUG: Transferring ${localRecords.length} local BMI records to account');

      // Get user profile data
      final userProfile = await BMIStorageService.loadUserProfile();
      final userAge = userProfile?['age']?.toInt();
      final userGender = userProfile?['gender'];

      // Transfer each record to Supabase
      int successCount = 0;
      for (final record in localRecords) {
        try {
          await SupabaseService.instance.saveBMIResult(
            bmiValue: double.parse(record['bmi'].toString()),
            category: record['category'],
            height: double.parse(record['height'].toString()),
            weight: double.parse(record['weight'].toString()),
            heightUnit: 'cm',
            weightUnit: 'kg',
            age: userAge, // Use profile age if available
            gender: userGender, // Use profile gender if available
          );
          successCount++;
        } catch (e) {
          print('DEBUG: Failed to transfer individual record: $e');
          // Continue with other records even if one fails
        }
      }

      if (successCount > 0) {
        // Clear local data after successful transfer
        await BMIHistoryManager.clearHistory();
        await BMIStorageService.clearCurrentBMI();
        print('DEBUG: Successfully transferred $successCount BMI records to account');
        return true;
      } else {
        print('DEBUG: Failed to transfer any BMI records');
        return false;
      }
    } catch (e) {
      print('DEBUG: Failed to transfer BMI data: $e');
      return false;
    }
  }

  // Clear all cached data (useful for logout)
  static Future<void> clearCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedHistoryKey);
    await prefs.remove(_pendingSyncKey);
    await prefs.remove(_lastSyncKey);
  }
}