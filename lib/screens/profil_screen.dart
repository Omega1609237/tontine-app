import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
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
  File? _selectedImage;
  String? _currentPhotoUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final auth = AuthService();
      final currentUser = auth.currentUser;

      if (currentUser != null) {
        final updatedUser = Utilisateur(
          id: currentUser.id,
          nom: _nomController.text,
          email: _emailController.text,
          password: currentUser.password,
          telephone: _telephoneController.text.isNotEmpty ? _telephoneController.text : null,
          role: currentUser.role,
          dateCreation: currentUser.dateCreation,
          photoUrl: _selectedImage?.path ?? _currentPhotoUrl,
        );

        // Ici vous devrez implémenter la mise à jour via API
        // Pour l'instant, on simule
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
          if (_selectedImage != null) {
            _currentPhotoUrl = _selectedImage!.path;
            _selectedImage = null;
          }
        });
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = AuthService().currentUser;
    final isAdmin = user?.isAdmin ?? false;

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
                if (!_isEditing) {
                  // Réinitialiser les valeurs
                  _nomController.text = user?.nom ?? '';
                  _emailController.text = user?.email ?? '';
                  _telephoneController.text = user?.telephone ?? '';
                  _selectedImage = null;
                }
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
              // Avatar avec photo
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
                          image: FileImage(File(_currentPhotoUrl!)),
                          fit: BoxFit.cover,
                        )
                            : null),
                        color: Colors.green[100],
                      ),
                      child: (_selectedImage == null && _currentPhotoUrl == null)
                          ? const Center(
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.green,
                        ),
                      )
                          : null,
                    ),
                    if (_isEditing)
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
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Informations
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

              // Informations supplémentaires
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

              // Bouton de sauvegarde
              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'ENREGISTRER LES MODIFICATIONS',
                      style: TextStyle(fontSize: 16),
                    ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (label == 'Nom' && (value == null || value.isEmpty)) {
          return 'Champ requis';
        }
        if (label == 'Email' && (value == null || value.isEmpty)) {
          return 'Champ requis';
        }
        return null;
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non disponible';
    return '${date.day}/${date.month}/${date.year}';
  }
}