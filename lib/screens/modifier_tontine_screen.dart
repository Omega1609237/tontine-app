import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tontine.dart';
import '../providers/tontine_provider.dart';

class ModifierTontineScreen extends StatefulWidget {
  final Tontine tontine;
  final VoidCallback? onRefresh;

  const ModifierTontineScreen({
    super.key,
    required this.tontine,
    this.onRefresh,
  });

  @override
  State<ModifierTontineScreen> createState() => _ModifierTontineScreenState();
}

class _ModifierTontineScreenState extends State<ModifierTontineScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _montantController;
  late TextEditingController _membresController;
  late TextEditingController _descriptionController;
  late String _frequence;
  bool _isLoading = false;
  final List<String> _frequences = ['quotidienne', 'hebdomadaire', 'mensuelle'];

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.tontine.nom);
    _montantController = TextEditingController(text: widget.tontine.montant.toString());
    _membresController = TextEditingController(text: widget.tontine.membres.toString());
    _descriptionController = TextEditingController(text: widget.tontine.description ?? '');
    _frequence = widget.tontine.frequence;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _montantController.dispose();
    _membresController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _modifierTontine() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final tontineModifiee = Tontine(
        id: widget.tontine.id,
        nom: _nomController.text,
        montant: double.parse(_montantController.text),
        frequence: _frequence,
        membres: int.parse(_membresController.text),
        dateDebut: widget.tontine.dateDebut,
        dateCreation: widget.tontine.dateCreation,
        statut: widget.tontine.statut,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        montantTotal: widget.tontine.montantTotal,
      );

      final provider = Provider.of<TontineProvider>(context, listen: false);
      await provider.modifierTontine(widget.tontine.id!, tontineModifiee);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tontine modifiée'), backgroundColor: Colors.green),
        );
        widget.onRefresh?.call();
        Navigator.pop(context);
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier Tontine'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
                  validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _montantController,
                  decoration: const InputDecoration(labelText: 'Montant (FCFA)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _membresController,
                  decoration: const InputDecoration(labelText: 'Nombre de membres', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  value: _frequence,
                  decoration: const InputDecoration(labelText: 'Fréquence', border: OutlineInputBorder()),
                  items: _frequences.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _frequence = v as String),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _modifierTontine,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('MODIFIER'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}