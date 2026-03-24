import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tontine.dart';
import '../providers/tontine_provider.dart';
import '../services/auth_service.dart';
import '../screens/modifier_tontine_screen.dart';
import 'role_based_widget.dart';

class CarteTontine extends StatelessWidget {
  final Tontine tontine;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const CarteTontine({
    super.key,
    required this.tontine,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TontineProvider>(context, listen: false);
    final auth = AuthService();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tontine.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tontine.statut == 'active'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tontine.statut == 'active'
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        child: Text(
                          tontine.statut == 'active' ? 'Active' : 'Terminée',
                          style: TextStyle(
                            color: tontine.statut == 'active'
                                ? Colors.green
                                : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      // Le menu à 3 points est visible UNIQUEMENT pour les admins
                      if (auth.isAdmin)
                        const SizedBox(width: 8),
                      if (auth.isAdmin)
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert, size: 20),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Modifier'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Supprimer'),
                                ],
                              ),
                            ),
                            if (tontine.statut == 'active')
                              const PopupMenuItem(
                                value: 'terminer',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Terminer'),
                                  ],
                                ),
                              ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ModifierTontineScreen(
                                    tontine: tontine,
                                    onRefresh: onRefresh,
                                  ),
                                ),
                              );
                              onRefresh();
                            } else if (value == 'delete') {
                              _confirmerSuppression(context);
                            } else if (value == 'terminer') {
                              _terminerTontine(context);
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
              // ... le reste du code (description, infos, progression)
              if (tontine.description != null && tontine.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    tontine.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.money, '${tontine.montant} FCFA'),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.people, '${tontine.membres} membres'),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.calendar_today, tontine.frequenceLibelle),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: tontine.progression / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                      Text(
                        '${tontine.progression.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Collecté: ${tontine.montantTotal} FCFA',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Restant: ${tontine.montantRestant} FCFA',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Future<void> _confirmerSuppression(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Supprimer la tontine "${tontine.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<TontineProvider>(context, listen: false);
      await provider.supprimerTontine(tontine.id!);
      onRefresh();
    }
  }

  Future<void> _terminerTontine(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Terminer la tontine "${tontine.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final tontineModifiee = Tontine(
        id: tontine.id,
        nom: tontine.nom,
        montant: tontine.montant,
        frequence: tontine.frequence,
        membres: tontine.membres,
        dateDebut: tontine.dateDebut,
        dateCreation: tontine.dateCreation,
        statut: 'terminee',
        description: tontine.description,
        montantTotal: tontine.montantTotal,
      );
      final provider = Provider.of<TontineProvider>(context, listen: false);
      await provider.modifierTontine(tontine.id!, tontineModifiee);
      onRefresh();
    }
  }
}