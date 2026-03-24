import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/tontine.dart';
import '../providers/tontine_provider.dart';
import '../services/auth_service.dart';

class CotisationsScreen extends StatefulWidget {
  final Tontine tontine;
  final bool isAdmin; // Ajouter ce paramètre

  const CotisationsScreen({
    super.key,
    required this.tontine,
    required this.isAdmin, // Ajouter
  });

  @override
  State<CotisationsScreen> createState() => _CotisationsScreenState();
}

class _CotisationsScreenState extends State<CotisationsScreen> {
  final _montantController = TextEditingController();
  int? _selectedMembreId;
  String _modePaiement = 'Espèces';
  bool _isLoading = false;
  final List<String> _modesPaiement = ['Espèces', 'Mobile Money', 'Virement'];

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<TontineProvider>(context, listen: false);
    await provider.chargerMembres(widget.tontine.id!);
    await provider.chargerCotisations(widget.tontine.id!);
    setState(() => _isLoading = false);
  }

  Future<void> _ajouterCotisation() async {
    if (_selectedMembreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un membre'), backgroundColor: Colors.orange),
      );
      return;
    }

    final montant = double.tryParse(_montantController.text);
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = Provider.of<TontineProvider>(context, listen: false);
    await provider.ajouterCotisation(
      widget.tontine.id!,
      _selectedMembreId!,
      montant,
      _modePaiement,
    );

    _montantController.clear();
    _selectedMembreId = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cotisation ajoutée'), backgroundColor: Colors.green),
    );

    await _chargerDonnees();
    setState(() => _isLoading = false);
  }

  Future<void> _supprimerCotisation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Supprimer cette cotisation ?'),
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
      await provider.supprimerCotisation(id);
      await _chargerDonnees();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TontineProvider>(context);
    final formatteur = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    double totalPaye = provider.cotisations.fold(0, (sum, c) => sum + c.montant);
    double objectifTotal = widget.tontine.montant * widget.tontine.membres;
    double progression = objectifTotal > 0 ? (totalPaye / objectifTotal * 100) : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cotisations - ${widget.tontine.nom}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barre de progression
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progression: ${progression.toStringAsFixed(1)}%'),
                    Text('${provider.cotisations.length} cotisations'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progression / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 8,
                ),
              ],
            ),
          ),
          const Divider(),

          // Formulaire d'ajout (UNIQUEMENT POUR LES ADMINS)
          if (widget.isAdmin)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedMembreId,
                      decoration: const InputDecoration(
                        labelText: 'Membre *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: provider.membres.map((membre) {
                        return DropdownMenuItem(
                          value: membre.id,
                          child: Text(membre.nomComplet),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedMembreId = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _montantController,
                      decoration: const InputDecoration(
                        labelText: 'Montant (FCFA) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _modePaiement,
                      decoration: const InputDecoration(
                        labelText: 'Mode de paiement',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: _modesPaiement.map((mode) {
                        return DropdownMenuItem(value: mode, child: Text(mode));
                      }).toList(),
                      onChanged: (value) => setState(() => _modePaiement = value!),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _ajouterCotisation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('AJOUTER LA COTISATION'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Liste des cotisations
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.cotisations.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune cotisation'),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.cotisations.length,
              itemBuilder: (context, index) {
                final c = provider.cotisations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(
                        c.membreNom[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(c.membreNom),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${formatteur.format(c.montant)}'),
                        Text('Le ${c.datePaiement.day}/${c.datePaiement.month}/${c.datePaiement.year}'),
                        if (c.modePaiement != null)
                          Text('Mode: ${c.modePaiement}'),
                      ],
                    ),
                    // Le bouton Supprimer n'apparaît que pour les admins
                    trailing: widget.isAdmin
                        ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _supprimerCotisation(c.id!),
                    )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
        onPressed: () {
          // Rien, le formulaire est déjà visible
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}