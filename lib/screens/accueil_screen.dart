import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tontine_provider.dart';
import '../widgets/carte_tontine.dart';
import '../widgets/app_drawer.dart';
import '../widgets/statistiques_dashboard.dart';
import '../services/auth_service.dart';
import 'creation_tontine_screen.dart';
import 'details_tontine_screen.dart';

class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<TontineProvider>(context, listen: false);
      await provider.chargerTontines();
      await provider.chargerStatistiques();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TontineProvider>(context);
    final auth = AuthService();

    print('🔑 Rôle utilisateur: ${auth.currentUser?.role}');
    print('🔑 isAdmin: ${auth.isAdmin}');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestion Tontine',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // BOUTON AJOUTER DANS LA BARRE D'ACTION
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                print('🟢 Bouton Ajouter cliqué !');
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreationTontineScreen(),
                  ),
                );
                if (result == true) {
                  _chargerDonnees();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerDonnees,
          ),
        ],
      ),
      drawer: AppDrawer(onRefresh: _chargerDonnees),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _chargerDonnees,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: StatistiquesDashboard(stats: provider.statistiques),
          ),
          Expanded(
            child: provider.tontines.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wallet_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune tontine',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auth.isAdmin
                        ? 'Créez votre première tontine'
                        : 'Aucune tontine disponible',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  if (auth.isAdmin)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const CreationTontineScreen(),
                          ),
                        );
                        if (result == true) {
                          _chargerDonnees();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Créer une tontine'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _chargerDonnees,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.tontines.length,
                itemBuilder: (context, index) {
                  final tontine = provider.tontines[index];
                  return CarteTontine(
                    tontine: tontine,
                    onTap: () {
                      provider.selectionnerTontine(tontine);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const DetailsTontineScreen(),
                        ),
                      ).then((_) => _chargerDonnees());
                    },
                    onRefresh: _chargerDonnees,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton(
        onPressed: () async {
          print('🟢 FAB cliqué !');
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreationTontineScreen(),
            ),
          );
          if (result == true) {
            _chargerDonnees();
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}