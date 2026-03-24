import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatistiquesDashboard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatistiquesDashboard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final formatteur = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.wallet,
                  'Tontines',
                  '${stats['totalTontines'] ?? 0}',
                  Colors.blue,
                ),
                _buildStatItem(
                  Icons.people,
                  'Membres',
                  '${stats['totalMembres'] ?? 0}',
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.payment,
                  'Cotisations',
                  formatteur.format(stats['totalCotisations'] ?? 0),
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Taux de participation'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (stats['tauxParticipation'] ?? 0) / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(stats['tauxParticipation'] ?? 0).toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}