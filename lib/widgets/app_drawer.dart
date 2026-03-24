import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tontine_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../screens/accueil_screen.dart';
import '../screens/statistiques_screen.dart';
import '../screens/parametres_screen.dart';
import '../screens/profil_screen.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onRefresh;

  const AppDrawer({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TontineProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = AuthService();
    final isAdmin = auth.isAdmin;

    return Drawer(
      child: Container(
        color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.green[50],
        child: Column(
          children: [
            // En-tête du drawer - version compacte
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.wallet,
                          size: 32,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gestion Tontine',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.currentUser?.nom ?? 'Utilisateur',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        isAdmin ? 'Administrateur' : 'Membre',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Liste des items - avec Expanded pour le défilement
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dashboard,
                    title: 'Tableau de bord',
                    count: provider.tontines.length.toString(),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const AccueilScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.bar_chart,
                    title: 'Statistiques',
                    count: '',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StatistiquesScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 16, thickness: 1),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.person,
                    title: 'Mon profil',
                    count: '',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings,
                    title: 'Paramètres',
                    count: '',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ParametresScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 16, thickness: 1),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dark_mode,
                    title: themeProvider.isDarkMode ? 'Mode clair' : 'Mode sombre',
                    count: '',
                    onTap: () {
                      Navigator.pop(context);
                      themeProvider.toggleTheme();
                    },
                  ),
                  const Divider(height: 16, thickness: 1),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.logout,
                    title: 'Déconnexion',
                    count: '',
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Déconnexion'),
                          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Déconnexion'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      '© 2026 Gestion Tontine',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String count,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.green, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: count.isNotEmpty && count != '0'
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          count,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      )
          : null,
      onTap: onTap,
    );
  }
}