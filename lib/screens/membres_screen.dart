import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/membre.dart';
import '../providers/tontine_provider.dart';

class MembresScreen extends StatefulWidget {
  final int tontineId;
  final String tontineNom;
  final bool isAdmin;

  const MembresScreen({
    super.key,
    required this.tontineId,
    required this.tontineNom,
    required this.isAdmin,
  });

  @override
  State<MembresScreen> createState() => _MembresScreenState();
}

class _MembresScreenState extends State<MembresScreen> {
  final _searchController = TextEditingController();
  List<Membre> _membresFiltres = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrerMembres);
    _chargerMembres();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chargerMembres() async {
    final provider = Provider.of<TontineProvider>(context, listen: false);
    await provider.chargerMembres(widget.tontineId);
    _filtrerMembres();
  }

  void _filtrerMembres() {
    final provider = Provider.of<TontineProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _membresFiltres = provider.membres;
      } else {
        _membresFiltres = provider.membres.where((m) {
          return m.nomComplet.toLowerCase().contains(query) ||
              m.telephone.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _ajouterMembre() async {
    final result = await showDialog<Membre>(
      context: context,
      builder: (context) => AjoutMembreDialog(tontineId: widget.tontineId),
    );

    if (result != null) {
      final provider = Provider.of<TontineProvider>(context, listen: false);
      try {
        await provider.ajouterMembre(widget.tontineId, result);
        await _chargerMembres();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membre ajouté'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _supprimerMembre(Membre membre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Supprimer ${membre.nomComplet} ?'),
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
      await provider.supprimerMembre(membre.id!);
      await _chargerMembres();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membre supprimé'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TontineProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Membres - ${widget.tontineNom}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerMembres,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un membre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filtrerMembres();
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _membresFiltres.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Aucun membre'
                        : 'Aucun résultat',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  if (widget.isAdmin)
                    ElevatedButton.icon(
                      onPressed: _ajouterMembre,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Ajouter un membre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _membresFiltres.length,
              itemBuilder: (context, index) {
                final membre = _membresFiltres[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(
                        membre.prenom[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(membre.nomComplet),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📞 ${membre.telephone}'),
                        if (membre.email != null) Text('✉️ ${membre.email}'),
                      ],
                    ),
                    trailing: widget.isAdmin
                        ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _supprimerMembre(membre),
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
        onPressed: _ajouterMembre,
        backgroundColor: Colors.green,
        child: const Icon(Icons.person_add),
      )
          : null,
    );
  }
}

// ========== DIALOGUE D'AJOUT DE MEMBRE ==========
class AjoutMembreDialog extends StatefulWidget {
  final int tontineId;

  const AjoutMembreDialog({super.key, required this.tontineId});

  @override
  State<AjoutMembreDialog> createState() => _AjoutMembreDialogState();
}

class _AjoutMembreDialogState extends State<AjoutMembreDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau Membre'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Champ requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Champ requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Champ requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optionnel)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final membre = Membre(
                tontineId: widget.tontineId,
                nom: _nomController.text,
                prenom: _prenomController.text,
                telephone: _telephoneController.text,
                email: _emailController.text.isNotEmpty ? _emailController.text : null,
                dateInscription: DateTime.now(),
                estActif: true,
              );
              Navigator.pop(context, membre);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}