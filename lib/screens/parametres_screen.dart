import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tontine_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';

class ParametresScreen extends StatelessWidget {
  const ParametresScreen({super.key});

  Future<void> _exporterDonnees(BuildContext context) async {
    // Récupérer le provider correctement
    final provider = Provider.of<TontineProvider>(context, listen: false);
    final tontines = provider.tontines;

    if (tontines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune donnée à exporter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Exporter la première tontine en PDF
    await ExportService.exportRapportTontine(
      tontine: tontines.first,
      membres: provider.membres,
      cotisations: provider.cotisations,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = AuthService();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // Section Préférences
          _buildSection(
            context,
            'Préférences',
            [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode, color: Colors.green),
                title: const Text('Mode sombre'),
                subtitle: const Text('Activer le thème sombre'),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications, color: Colors.green),
                title: const Text('Notifications'),
                subtitle: const Text('Recevoir des rappels de paiement'),
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),

          // Section Monnaie
          _buildSection(
            context,
            'Monnaie',
            [
              RadioListTile<String>(
                secondary: const Icon(Icons.money, color: Colors.green),
                title: const Text('Franc CFA (FCFA)'),
                value: 'FCFA',
                groupValue: 'FCFA',
                onChanged: (value) {},
              ),
              RadioListTile<String>(
                secondary: const Icon(Icons.money, color: Colors.green),
                title: const Text('Euro (€)'),
                value: 'EUR',
                groupValue: 'FCFA',
                onChanged: (value) {},
              ),
            ],
          ),

          // Section Données (visible uniquement pour admin)
          if (isAdmin)
            _buildSection(
              context,
              'Données',
              [
                ListTile(
                  leading: const Icon(Icons.backup, color: Colors.blue),
                  title: const Text('Sauvegarder les données'),
                  subtitle: const Text('Exporter toutes les données'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sauvegarde en cours...')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('Exporter en PDF'),
                  subtitle: const Text('Générer un rapport PDF'),
                  onTap: () => _exporterDonnees(context),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Réinitialiser'),
                  subtitle: const Text('Effacer toutes les données'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmation'),
                        content: const Text('Effacer toutes les données ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Effacer'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité à venir')),
                      );
                    }
                  },
                ),
              ],
            ),

          // Section À propos
          _buildSection(
            context,
            'À propos',
            [
              const ListTile(
                leading: Icon(Icons.info, color: Colors.green),
                title: Text('Version'),
                subtitle: Text('2.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.update, color: Colors.green),
                title: const Text('Vérifier les mises à jour'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vous utilisez la dernière version')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String titre, List<Widget> enfants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            titre,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: enfants),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}