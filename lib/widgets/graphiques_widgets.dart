import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphiqueLineaire extends StatelessWidget {
  final List<double> donnees;
  final List<String> labels;

  const GraphiqueLineaire({
    super.key,
    required this.donnees,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(labels[value.toInt()]),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: donnees.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GraphiqueCirculaire extends StatelessWidget {
  final Map<String, double> donnees;

  const GraphiqueCirculaire({super.key, required this.donnees});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.green, Colors.orange, Colors.blue, Colors.purple];

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: donnees.entries.map((entry) {
            return PieChartSectionData(
              value: entry.value,
              title: '${entry.key}\n${entry.value.toStringAsFixed(0)}%',
              color: colors[donnees.keys.toList().indexOf(entry.key) % colors.length],
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}