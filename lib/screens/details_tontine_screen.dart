import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tontine.dart';
import '../providers/tontine_provider.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import 'membres_screen.dart';
import 'cotisations_screen.dart';
import 'modifier_tontine_screen.dart';

class DetailsTontineScreen extends StatefulWidget {
  const DetailsTontineScreen({super.key});

  @override
  State<DetailsTontineScreen> createState() => _DetailsTontineScreenState();
}

class _DetailsTontineScreenState extends State<DetailsTontineScreen> {
  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    final provider = Provider.of<TontineProvider>(context, listen: false);
    final tontine = provider.tontineSelectionnee;
    if (tontine != null) {
      await provider.chargerMembres(tontine.id!);
      await provider.chargerCotisations(tontine.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TontineProvider>(context);
    final tontine = provider.tontineSelectionnee;
    final auth = AuthService();
    final isAdmin = auth.isAdmin;

    if (tontine == null) {
      return const Scaffold(
        body: Center(child: Text('Aucune tontine sélectionnée')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tontine.nom),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Bouton d'export (visible pour tous)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await ExportService.exportRapportTontine(
                tontine: tontine,
                membres: provider.membres,
                cotisations: provider.cotisations,
              );
            },
          ),
          // Bouton Modifier (visible seulement pour les admins)
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModifierTontineScreen(
                      tontine: tontine,
                      onRefresh: _chargerDonnees,
                    ),
                  ),
                );
                _chargerDonnees();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _chargerDonnees,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte d'informations
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.money, 'Montant', '${tontine.montant} FCFA'),
                      const Divider(),
                      _buildInfoRow(Icons.people, 'Membres', '${tontine.membres}'),
                      const Divider(),
                      _buildInfoRow(Icons.calendar_today, 'Fréquence', tontine.frequenceLibelle),
                      const Divider(),
                      _buildInfoRow(Icons.calendar_month, 'Début', '${tontine.dateDebut.day}/${tontine.dateDebut.month}/${tontine.dateDebut.year}'),
                      if (tontine.description != null) ...[
                        const Divider(),
                        _buildInfoRow(Icons.description, 'Description', tontine.description!),
                      ],
                      const Divider(),
                      _buildInfoRow(
                        Icons.attach_money,
                        'Progression',
                        '${tontine.progression.toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: tontine.progression / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Collecté: ${tontine.montantTotal} FCFA'),
                          Text('Restant: ${tontine.montantRestant} FCFA'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MembresScreen(
                              tontineId: tontine.id!,
                              tontineNom: tontine.nom,
                              isAdmin: isAdmin,
                            ),
                          ),
                        );
                        _chargerDonnees();
                      },
                      icon: const Icon(Icons.people),
                      label: Text('Membres (${provider.membres.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CotisationsScreen(
                              tontine: tontine,
                              isAdmin: isAdmin,
                            ),
                          ),
                        );
                        _chargerDonnees();
                      },
                      icon: const Icon(Icons.payment),
                      label: Text('Cotisations (${provider.cotisations.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dernières cotisations
              if (provider.cotisations.isNotEmpty) ...[
                const Text(
                  'Dernières cotisations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...provider.cotisations.take(3).map((cotisation) {
                  return ListTile(
                    leading: const Icon(Icons.payment, color: Colors.green),
                    title: Text(cotisation.membreNom),
                    subtitle: Text('${cotisation.montant} FCFA - ${cotisation.datePaiement.day}/${cotisation.datePaiement.month}'),
                    trailing: Text(cotisation.modePaiement ?? ''),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}