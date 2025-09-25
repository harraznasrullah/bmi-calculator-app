import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample health tips data
    final List<HealthTip> tips = [
      HealthTip(
        title: 'Stay Hydrated',
        content: 'Drink at least 8 glasses of water daily to maintain good health and support weight management.',
        icon: Icons.local_drink,
        color: Colors.blue,
      ),
      HealthTip(
        title: 'Exercise Regularly',
        content: 'Aim for at least 150 minutes of moderate aerobic activity or 75 minutes of vigorous activity each week.',
        icon: Icons.fitness_center,
        color: Colors.green,
      ),
      HealthTip(
        title: 'Eat Balanced Meals',
        content: 'Include fruits, vegetables, lean proteins, and whole grains in your daily diet for optimal nutrition.',
        icon: Icons.restaurant,
        color: Colors.orange,
      ),
      HealthTip(
        title: 'Get Quality Sleep',
        content: 'Aim for 7-9 hours of sleep per night to support your body\'s recovery and overall health.',
        icon: Icons.bed,
        color: Colors.purple,
      ),
      HealthTip(
        title: 'Monitor Your BMI',
        content: 'Regularly check your BMI to track your weight management progress and maintain a healthy lifestyle.',
        icon: Icons.monitor_heart,
        color: Colors.red,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          'Health Tips',
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: tips.length,
          itemBuilder: (context, index) {
            final tip = tips[index];
            return _buildTipCard(context, tip);
          },
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, HealthTip tip) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: tip.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tip.color,
                  width: 1,
                ),
              ),
              child: Icon(
                tip.icon,
                color: tip.color,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tip.content,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HealthTip {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  HealthTip({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });
}