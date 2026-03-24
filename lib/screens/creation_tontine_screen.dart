import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tontine.dart';
import '../providers/tontine_provider.dart';

class CreationTontineScreen extends StatefulWidget {
  const CreationTontineScreen({super.key});

  @override
  State<CreationTontineScreen> createState() => _CreationTontineScreenState();
}

class _CreationTontineScreenState extends State<CreationTontineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _montantController = TextEditingController();
  final _membresController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _frequence = 'hebdomadaire';
  DateTime _dateDebut = DateTime.now();
  bool _isLoading = false;
  final List<String> _frequences = ['quotidienne', 'hebdomadaire', 'mensuelle'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Tontine'),
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
                  decoration: const InputDecoration(
                    labelText: 'Nom de la tontine *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _montantController,
                  decoration: const InputDecoration(
                    labelText: 'Montant (FCFA) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _membresController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de membres *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Requis';
                    if (int.tryParse(v!) == null) return 'Nombre invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  value: _frequence,
                  decoration: const InputDecoration(
                    labelText: 'Fréquence',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  items: _frequences.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _frequence = v as String),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dateDebut,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => _dateDebut = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date de début',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    child: Text('${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year}'),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _creerTontine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('CRÉER LA TONTINE', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _creerTontine() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final tontine = Tontine(
          nom: _nomController.text,
          montant: double.parse(_montantController.text),
          frequence: _frequence,
          membres: int.parse(_membresController.text),
          dateDebut: _dateDebut,
          dateCreation: DateTime.now(),
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        );

        final provider = Provider.of<TontineProvider>(context, listen: false);
        await provider.ajouterTontine(tontine);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tontine créée avec succès!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}