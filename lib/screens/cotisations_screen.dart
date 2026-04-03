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
  final String _modePaiement = 'Espèces';
  bool _isSaving = false;

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

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
    final cotisationPeriode = _getCotisationPeriode(_selectedMembreId!);
    final dejaPaye = cotisationPeriode?.montant ?? 0.0;
    final nouveauTotal = dejaPaye + montantSaisi;

    if (nouveauTotal > widget.tontine.montant) {
      return _showMessage('Impossible ! Max: ${widget.tontine.montant.toInt()} FCFA', Colors.red);
    }

    setState(() => _isSaving = true);
    try {
      if (cotisationPeriode != null) {
        await provider.modifierCotisation(cotisationPeriode.id!, nouveauTotal, _modePaiement);
      } else {
        await provider.ajouterCotisation(widget.tontine.id!, _selectedMembreId!, montantSaisi, _modePaiement);
      }
      _montantController.clear();
      setState(() => _selectedMembreId = null);
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
    final f = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    final debutPeriode = _getDebutPeriode();

    final cotisationsPeriode = provider.cotisations.where((c) => c.datePaiement.isAfter(debutPeriode)).toList();

    double totalPaye = 0;
    for (var c in cotisationsPeriode) {
      totalPaye += c.montant;
    }
    double objectif = widget.tontine.montant * widget.tontine.membres;
    double progression = objectif > 0 ? (totalPaye / objectif).clamp(0.0, 1.0) : 0;

    String periodeTexte = '';
    switch (widget.tontine.frequence) {
      case 'quotidienne': periodeTexte = "Aujourd'hui"; break;
      case 'hebdomadaire': periodeTexte = "Semaine"; break;
      case 'mensuelle': periodeTexte = "Mois"; break;
    }

    return Scaffold(
      // SOLUTION 1: resizeToAvoidBottomInset permet de gérer le clavier proprement
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('${widget.tontine.nom} - $periodeTexte'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // Utilisation de BouncingScrollPhysics pour une sensation plus fluide sur mobile
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                    // SOLUTION 2: Utiliser Wrap au lieu de Row pour éviter les pixels qui dépassent
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 10,
                      runSpacing: 5,
                      children: [
                        Text('Obj: ${f.format(objectif)}', style: const TextStyle(fontSize: 11)),
                        Text('Reçu: ${f.format(totalPaye)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        Text('${(progression * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (widget.isAdmin) Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      isExpanded: true, // Évite que le texte ne déborde dans le bouton
                      value: _selectedMembreId,
                      decoration: const InputDecoration(labelText: 'Membre'),
                      items: provider.membres.map((m) {
                        final cotisationPeriode = _getCotisationPeriode(m.id!);
                        final dejaPaye = cotisationPeriode?.montant ?? 0;
                        final reste = widget.tontine.montant - dejaPaye;
                        return DropdownMenuItem(
                          value: m.id,
                          child: Text(
                            '${m.nomComplet} (${reste <= 0 ? "PAYÉ" : "Reste: ${reste.toInt()}"})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedMembreId = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _montantController,
                      decoration: const InputDecoration(
                        labelText: 'Montant à ajouter (FCFA)',
                        hintText: 'Ex: 5000',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _validerPaiement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('VALIDER LE PAIEMENT'),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text('HISTORIQUE DES PAIEMENTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            ),
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: reste <= 0 ? Colors.green : Colors.orange,
                      child: Icon(reste <= 0 ? Icons.check : Icons.access_time, color: Colors.white, size: 20),
                    ),
                    title: Text(c.membreNom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Reçu: ${f.format(c.montant)} | Reste: ${f.format(reste)}', style: const TextStyle(fontSize: 12)),
                    trailing: widget.isAdmin ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _confirmerSuppression(c.id!),
                    ) : null,
                  ),
                );
              },
            ),
            // Ajout d'un petit espace en bas pour ne pas coller au bord
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}