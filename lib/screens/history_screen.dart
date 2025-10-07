import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bmi_calc/services/supabase_service.dart';
import 'package:bmi_calc/services/sync_service.dart';
import 'package:bmi_calc/utils/bmi_history_manager.dart';
import 'package:bmi_calc/utils/event_bus.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _bmiRecords = [];
  bool _isLoading = true;
  bool _hasPendingSync = false;

  StreamSubscription<String>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _checkPendingSync();

    // Listen for BMI calculation, login, logout, and sync events to refresh history
    _eventSubscription = EventBus.instance.stream.listen((event) {
      if (event == Events.bmiCalculated ||
          event == Events.userLoggedIn ||
          event == Events.userSignedOut ||
          event == 'sync_completed' ||
          event == 'background_sync_completed') {
        _loadHistory();
        _checkPendingSync();
      }
    });
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use sync service for offline-first history
      final records = await SyncService.getBMIHistoryWithSync();
      setState(() {
        _bmiRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _bmiRecords = [];
        _isLoading = false;
      });
      _showErrorDialog('Failed to load history: $e');
    }
  }

  Future<void> _clearHistory() async {
    try {
      // Check if user is authenticated
      final user = SupabaseService.instance.getCurrentUser();
      if (user != null) {
        // If authenticated, clear from Supabase
        await SupabaseService.instance.clearBMIHistory();
      } else {
        // If not authenticated, clear from local storage only
        await BMIHistoryManager.clearHistory();
      }
      setState(() {
        _bmiRecords = []; // Clear the local list
      });
    } catch (e) {
      _showErrorDialog('Failed to clear history: $e');
    }
  }

  Future<void> _checkPendingSync() async {
    try {
      final hasPending = await SyncService.hasPendingSync();
      setState(() {
        _hasPendingSync = hasPending;
      });
    } catch (e) {
      // Error checking pending sync
    }
  }

  Future<void> _syncNow() async {
    try {
      await SyncService.syncPendingRecords();
      await _checkPendingSync();
      _showSuccessDialog('Sync completed successfully!');
    } catch (e) {
      _showErrorDialog('Sync failed: $e');
    }
  }
  
  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadHistory,
          tooltip: 'Refresh history',
        ),
        title: Text(
          'BMI History',
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasPendingSync)
            IconButton(
              icon: const Icon(Icons.sync, color: Colors.orange),
              onPressed: _syncNow,
              tooltip: 'Sync pending records',
            ),
          if (_bmiRecords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _showClearHistoryDialog();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _bmiRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No BMI records yet',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Calculate your BMI to see history',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      itemCount: _bmiRecords.length,
                      itemBuilder: (context, index) {
                        final record = _bmiRecords[index];
                        // Parse the date properly - handle both Supabase ('created_at') and local storage ('date')
                        final dateString = record['created_at'] ?? record['date'];
                        final date = DateTime.parse(dateString);
                        final formattedDate = "${date.day}/${date.month}/${date.year}";
                        
                        return _buildHistoryCard(
                          context,
                          formattedDate,
                          (record['bmi_value'] ?? record['bmi'])?.toDouble() ?? 0.0,
                          record['category'],
                          record['weight']?.toDouble() ?? 0.0,
                          record['height']?.toDouble() ?? 0.0,
                          record['age']?.toInt(),
                          record['gender'],
                        );
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    String date,
    double bmi,
    String category,
    double weight,
    double height,
    int? age,
    String? gender,
  ) {
    Color cardColor = _getCategoryColor(category);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cardColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: cardColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'BMI',
                    bmi.toStringAsFixed(1),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoCard(
                    'Weight',
                    '${weight.toStringAsFixed(1)} kg',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoCard(
                    'Height',
                    '${height.toStringAsFixed(0)} cm',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            // Age and Gender row
            if (age != null || gender != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (age != null) ...[
                    Expanded(
                      child: _buildInfoCard(
                        'Age',
                        '$age years',
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (gender != null) ...[
                    Expanded(
                      child: _buildInfoCard(
                        'Gender',
                        gender!,
                        Colors.teal,
                      ),
                    ),
                    if (age == null) const SizedBox(width: 10),
                  ],
                  if (age == null && gender != null)
                    Expanded(child: Container()), // Spacer for alignment
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Underweight':
        return const Color(0xFF1565C0); // Deep Blue - concerning
      case 'Normal':
      case 'Normal weight':
      case 'Healthy weight':
        return const Color(0xFF2E7D32); // Dark Green - healthy
      case 'Overweight':
        return const Color(0xFFF57C00); // Deep Orange - warning
      case 'Obese':
        return const Color(0xFFC62828); // Dark Red - serious health risk
      default:
        return Colors.grey[600]!;
    }
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History'),
          content: const Text('Are you sure you want to clear all BMI history? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearHistory();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}