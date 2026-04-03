import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/utilisateur.dart';
import '../providers/theme_provider.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUploading = false;

  File? _selectedImage;
  String? _currentPhotoUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _chargerDonneesUtilisateur();
  }

  void _chargerDonneesUtilisateur() {
    final user = AuthService().currentUser;
    _nomController = TextEditingController(text: user?.nom ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _telephoneController = TextEditingController(text: user?.telephone ?? '');
    _currentPhotoUrl = user?.photoUrl;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la sélection : $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = AuthService();
    final currentUser = auth.currentUser;

    if (currentUser != null) {
      try {
        String? photoUrl = _currentPhotoUrl;

        // 1. Gérer l'upload si une nouvelle image est sélectionnée
        if (_selectedImage != null) {
          setState(() => _isUploading = true);
          final uploadedUrl = await ApiService.uploadImage(_selectedImage!);
          setState(() => _isUploading = false);

          if (uploadedUrl != null) {
            // Si l'URL renvoyée est partielle, on peut la compléter ici
            photoUrl = uploadedUrl.startsWith('http')
                ? uploadedUrl
                : "${ApiService.baseUrl.replaceAll('/api', '')}/uploads/$uploadedUrl";
          }
        }

        // 2. Préparer l'objet utilisateur mis à jour
        final updatedUser = Utilisateur(
          id: currentUser.id,
          nom: _nomController.text.trim(),
          email: _emailController.text.trim(),
          password: currentUser.password,
          telephone: _telephoneController.text.trim().isNotEmpty ? _telephoneController.text.trim() : null,
          role: currentUser.role,
          dateCreation: currentUser.dateCreation,
          photoUrl: photoUrl,
        );

        // 3. Envoyer les modifications au serveur
        final success = await ApiService.updateUser(updatedUser);

        if (success && mounted) {
          // IMPORTANT : Re-synchroniser le service d'authentification avec les nouvelles infos
          await auth.init();

          setState(() {
            _isEditing = false;
            _currentPhotoUrl = auth.currentUser?.photoUrl;
            _selectedImage = null;
          });

          _showSnackBar('Profil mis à jour avec succès', Colors.green);
        } else {
          _showSnackBar('Échec de la mise à jour sur le serveur', Colors.red);
        }
      } catch (e) {
        _showSnackBar('Erreur : $e', Colors.red);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = AuthService().currentUser;
    final isAdmin = user?.isAdmin ?? false;

    // Générer un timestamp pour forcer le rafraîchissement du cache de l'image
    final String cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) _chargerDonneesUtilisateur();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green, width: 3),
                        image: _selectedImage != null
                            ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                            : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage('$_currentPhotoUrl?t=$cacheBuster'),
                          fit: BoxFit.cover,
                        )
                            : null),
                        color: Colors.green[100],
                      ),
                      child: (_selectedImage == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty))
                          ? const Center(
                        child: Icon(Icons.person, size: 60, color: Colors.green),
                      )
                          : null,
                    ),
                    if (_isEditing && !_isUploading)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    if (_isUploading)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoField(
                        label: 'Nom',
                        controller: _nomController,
                        enabled: _isEditing,
                        icon: Icons.person,
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoField(
                        label: 'Email',
                        controller: _emailController,
                        enabled: _isEditing,
                        icon: Icons.email,
                        themeProvider: themeProvider,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoField(
                        label: 'Téléphone',
                        controller: _telephoneController,
                        enabled: _isEditing,
                        icon: Icons.phone,
                        themeProvider: themeProvider,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.admin_panel_settings, 'Rôle', isAdmin ? 'Administrateur' : 'Membre'),
                      const Divider(),
                      _buildInfoRow(Icons.calendar_today, 'Membre depuis', _formatDate(user?.dateCreation)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('ENREGISTRER LES MODIFICATIONS'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    required ThemeProvider themeProvider,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
      ),
      keyboardType: keyboardType,
      validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 16),
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non disponible';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}