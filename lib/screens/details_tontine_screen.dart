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
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text('Collecté: ${tontine.montantTotal} FCFA', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          Flexible(child: Text('Restant: ${tontine.montantRestant} FCFA', style: const TextStyle(fontSize: 11, color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- SECTION BOUTONS CORRIGÉE ---
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Membres (${provider.membres.length})',
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Cotiser (${provider.cotisations.length})',
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (provider.cotisations.isNotEmpty) ...[
                const Text(
                  'Dernières cotisations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.cotisations.length > 3 ? 3 : provider.cotisations.length,
                  itemBuilder: (context, index) {
                    final cotisation = provider.cotisations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white, size: 20),
                        ),
                        title: Text(cotisation.membreNom, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${cotisation.montant} FCFA • ${cotisation.datePaiement.day}/${cotisation.datePaiement.month}'),
                        trailing: Text(
                          cotisation.modePaiement ?? '',
                          style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- MÉTHODE _buildInfoRow CORRIGÉE ---
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}