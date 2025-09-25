import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bmi_app1/utils/bmi_history_manager.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _bmiRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await BMIHistoryManager.getBMIHistory();
      setState(() {
        _bmiRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _bmiRecords = [];
        _isLoading = false;
      });
      // Show error dialog if needed
      _showErrorDialog('Failed to load history: $e');
    }
  }

  Future<void> _clearHistory() async {
    await BMIHistoryManager.clearHistory();
    setState(() {
      _bmiRecords = [];
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          'BMI History',
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
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
                        // Parse the date properly
                        final date = DateTime.parse(record['date']);
                        final formattedDate = "${date.day}/${date.month}/${date.year}";
                        
                        return _buildHistoryCard(
                          context,
                          formattedDate,
                          record['bmi'],
                          record['category'],
                          record['weight'],
                          record['height'],
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
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.grey;
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