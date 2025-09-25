import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample BMI history data
    final List<BMIRecord> bmiRecords = [
      BMIRecord(date: '2023-09-25', bmi: 24.5, category: 'Normal', weight: 72.0, height: 172.0),
      BMIRecord(date: '2023-09-18', bmi: 25.1, category: 'Overweight', weight: 74.0, height: 172.0),
      BMIRecord(date: '2023-09-11', bmi: 26.3, category: 'Overweight', weight: 76.0, height: 172.0),
      BMIRecord(date: '2023-09-04', bmi: 27.0, category: 'Overweight', weight: 77.0, height: 172.0),
      BMIRecord(date: '2023-08-28', bmi: 27.8, category: 'Overweight', weight: 78.0, height: 172.0),
    ];

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
      ),
      body: bmiRecords.isEmpty
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: bmiRecords.length,
                itemBuilder: (context, index) {
                  final record = bmiRecords[index];
                  return _buildHistoryCard(context, record);
                },
              ),
            ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, BMIRecord record) {
    Color cardColor = _getCategoryColor(record.category);
    
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
                  record.date,
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
                    record.category,
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
                    record.bmi.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoCard(
                    'Weight',
                    '${record.weight} kg',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoCard(
                    'Height',
                    '${record.height} cm',
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
              color: Colors.grey[600],
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
}

class BMIRecord {
  final String date;
  final double bmi;
  final String category;
  final double weight;
  final double height;

  BMIRecord({
    required this.date,
    required this.bmi,
    required this.category,
    required this.weight,
    required this.height,
  });
}