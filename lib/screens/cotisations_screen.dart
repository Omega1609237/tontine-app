import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/tontine.dart';
import '../providers/tontine_provider.dart';

class CotisationsScreen extends StatefulWidget {
  final Tontine tontine;
  final bool isAdmin;
  const CotisationsScreen({super.key, required this.tontine, required this.isAdmin});

  @override
  State<CotisationsScreen> createState() => _CotisationsScreenState();
}

class _CotisationsScreenState extends State<CotisationsScreen> {
  final _montantController = TextEditingController();
  int? _selectedMembreId;
  String _modePaiement = 'Espèces';
  bool _isSaving = false;

  // Récupère le début de la période (jour, semaine, mois)
  DateTime _getDebutPeriode() {
    final now = DateTime.now();
    switch (widget.tontine.frequence) {
      case 'quotidienne':
        return DateTime(now.year, now.month, now.day);
      case 'hebdomadaire':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'mensuelle':
        return DateTime(now.year, now.month, 1);
      default:
        return now;
    }
  }

  // Récupère la cotisation de la période actuelle pour un membre
  dynamic _getCotisationPeriode(int membreId) {
    final provider = Provider.of<TontineProvider>(context, listen: false);
    final debut = _getDebutPeriode();
    try {
      return provider.cotisations.firstWhere((c) =>
      c.membreId == membreId &&
          c.datePaiement.isAfter(debut));
    } catch (e) {
      return null;
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _validerPaiement() async {
    if (_selectedMembreId == null) return _showMessage('Sélectionnez un membre', Colors.orange);
    final montantSaisi = double.tryParse(_montantController.text) ?? 0;
    if (montantSaisi <= 0) return _showMessage('Montant invalide', Colors.orange);

    final provider = Provider.of<TontineProvider>(context, listen: false);

    // Récupère la cotisation de la période en cours
    final cotisationPeriode = _getCotisationPeriode(_selectedMembreId!);
    final dejaPaye = cotisationPeriode?.montant ?? 0.0;
    final nouveauTotal = dejaPaye + montantSaisi;

    // Vérification du surplus
    if (nouveauTotal > widget.tontine.montant) {
      return _showMessage('Impossible ! Le total dépasserait ${widget.tontine.montant.toInt()} FCFA', Colors.red);
    }

    setState(() => _isSaving = true);
    try {
      if (cotisationPeriode != null) {
        // Mise à jour de la cotisation existante
        await provider.modifierCotisation(cotisationPeriode.id!, nouveauTotal, _modePaiement);
      } else {
        // Création d'une nouvelle cotisation
        await provider.ajouterCotisation(widget.tontine.id!, _selectedMembreId!, montantSaisi, _modePaiement);
      }
      _montantController.clear();
      _selectedMembreId = null;
      _showMessage('Paiement validé !', Colors.green);
    } catch (e) {
      _showMessage('Erreur: $e', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmerSuppression(int id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer'),
        content: const Text('Voulez-vous vraiment supprimer cette cotisation ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NON')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OUI', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await Provider.of<TontineProvider>(context, listen: false).supprimerCotisation(id);
      _showMessage('Supprimé avec succès', Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TontineProvider>(context);
    final f = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    final debutPeriode = _getDebutPeriode();

    // Filtrer les cotisations de la période actuelle
    final cotisationsPeriode = provider.cotisations.where((c) => c.datePaiement.isAfter(debutPeriode)).toList();

    // Calculer les totaux pour la période
    double totalPaye = 0;
    for (var c in cotisationsPeriode) {
      totalPaye += c.montant;
    }
    double objectif = widget.tontine.montant * widget.tontine.membres;
    double progression = objectif > 0 ? (totalPaye / objectif).clamp(0.0, 1.0) : 0;

    String periodeTexte = '';
    switch (widget.tontine.frequence) {
      case 'quotidienne': periodeTexte = "aujourd'hui"; break;
      case 'hebdomadaire': periodeTexte = "cette semaine"; break;
      case 'mensuelle': periodeTexte = "ce mois-ci"; break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tontine.nom} - ${periodeTexte.toUpperCase()}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Barre de progression de la période
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: progression,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(Colors.green),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Objectif: ${f.format(objectif)}', style: const TextStyle(fontSize: 12)),
                        Text('Collecté: ${f.format(totalPaye)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${(progression * 100).toStringAsFixed(1)}%'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Formulaire d'ajout (admin seulement)
            if (widget.isAdmin) Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedMembreId,
                      decoration: const InputDecoration(labelText: 'Membre'),
                      items: provider.membres.map((m) {
                        final cotisationPeriode = _getCotisationPeriode(m.id!);
                        final dejaPaye = cotisationPeriode?.montant ?? 0;
                        final reste = widget.tontine.montant - dejaPaye;
                        return DropdownMenuItem(
                          value: m.id,
                          child: Text('${m.nomComplet} (${reste <= 0 ? "Payé" : "Reste: ${reste.toInt()}"})'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedMembreId = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _montantController,
                      decoration: const InputDecoration(labelText: 'Montant à ajouter (FCFA)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _validerPaiement,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: _isSaving ? const CircularProgressIndicator() : const Text('VALIDER', style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Liste des cotisations de la période
            Text('PAIEMENTS ${periodeTexte.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (cotisationsPeriode.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Aucun paiement pour cette période'))),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cotisationsPeriode.length,
              itemBuilder: (ctx, i) {
                final c = cotisationsPeriode[i];
                final reste = widget.tontine.montant - c.montant;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: reste <= 0 ? Colors.green : Colors.orange,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(c.membreNom),
                  subtitle: Text('Payé: ${f.format(c.montant)} | Reste: ${f.format(reste)}'),
                  trailing: widget.isAdmin ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmerSuppression(c.id!),
                  ) : null,
                );
              },
            )
          ],
        ),
      ),
    );
  }
}