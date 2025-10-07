import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bmi_calc/services/sync_service.dart';
import 'package:bmi_calc/services/supabase_service.dart';
import 'package:bmi_calc/utils/event_bus.dart';

class BackgroundSyncService {
  static BackgroundSyncService? _instance;
  static BackgroundSyncService get instance => _instance ??= BackgroundSyncService._internal();
  BackgroundSyncService._internal();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  Timer? _syncTimer;

  void initialize() {
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool wasOffline = !_isOnline;
      _isOnline = results.any((result) => result != ConnectivityResult.none);

      // If we just came online, trigger sync
      if (wasOffline && _isOnline) {
        _triggerSync();
      }
    });

    // Check initial connectivity
    _checkInitialConnectivity();

    // Set up periodic sync every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isOnline) {
        _triggerSync();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _isOnline = results.any((result) => result != ConnectivityResult.none);

      if (_isOnline) {
        _triggerSync();
      }
    } catch (e) {
      _isOnline = false;
    }
  }

  Future<void> _triggerSync() async {
    try {
      // Only sync if user is logged in
      final user = SupabaseService.instance.getCurrentUser();
      if (user == null) return;

      // Check if there are pending records
      final hasPending = await SyncService.hasPendingSync();
      if (!hasPending) return;

      // Perform sync
      await SyncService.syncPendingRecords();

      // Emit event to notify UI
      EventBus.instance.emit('background_sync_completed');
    } catch (e) {
      print('Background sync failed: $e');
    }
  }

  bool get isOnline => _isOnline;

  // Manual sync trigger
  Future<void> syncNow() async {
    await _triggerSync();
  }
}