import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tontine_provider.dart';
import '../widgets/statistiques_dashboard.dart';
import '../widgets/graphiques_widgets.dart';

class StatistiquesScreen extends StatelessWidget {
  const StatistiquesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TontineProvider>(context);
    final tontines = provider.tontines;
    final stats = provider.statistiques;

    // Données pour les graphiques
    Map<String, double> repartition = {
      'Actives': tontines.where((t) => t.statut == 'active').length.toDouble(),
      'Terminées': tontines.where((t) => t.statut != 'active').length.toDouble(),
    };

    // Données d'évolution (exemple)
    List<double> evolution = [1000, 2500, 1800, 3200, 2800, 4000];
    List<String> mois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              provider.chargerStatistiques();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard
            StatistiquesDashboard(stats: stats),
            const SizedBox(height: 24),

            // Graphique d'évolution
            const Text(
              'Évolution des cotisations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GraphiqueLineaire(
              donnees: evolution,
              labels: mois,
            ),
            const SizedBox(height: 24),

            // Graphique de répartition
            const Text(
              'Répartition des tontines',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GraphiqueCirculaire(
              donnees: repartition,
            ),
            const SizedBox(height: 24),

            // Détails des tontines
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Détails des tontines',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...tontines.map((tontine) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tontine.nom),
                                Text(
                                  '${tontine.membres} membres',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${tontine.montant} FCFA'),
                              Text(
                                '${tontine.progression.toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 12, color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}