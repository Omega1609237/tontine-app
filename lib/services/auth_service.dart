import 'package:shared_preferences/shared_preferences.dart';
import '../models/utilisateur.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Utilisateur? _currentUser;

  Utilisateur? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      try {
        final userData = await ApiService.getCurrentUser();
        _currentUser = Utilisateur.fromJson(userData);
        print('✅ Utilisateur chargé: ${_currentUser?.email} (${_currentUser?.role})');
      } catch (e) {
        print('Erreur chargement utilisateur: $e');
        await prefs.remove('token');
        _currentUser = null;
      }
    }
  }

  Future<bool> register(String nom, String email, String password, {String role = 'membre'}) async {
    try {
      // Passer le rôle à l'API
      final data = await ApiService.register(nom, email, password, null, role: role);
      if (data != null && data['user'] != null) {
        _currentUser = Utilisateur.fromJson(data['user']);
        print('✅ Inscription réussie: ${_currentUser?.email} (${_currentUser?.role})');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur inscription: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final Map<String, dynamic> data = await ApiService.login(email, password);

      print('📦 Données reçues: $data');

      if (data.containsKey('user')) {
        final userData = data['user'];
        if (userData is Map<String, dynamic>) {
          _currentUser = Utilisateur.fromJson(userData);
          final isAdmin = _currentUser?.isAdmin ?? false;
          print('✅ Connexion réussie: ${_currentUser?.email} (${_currentUser?.role})');
          return true;
        } else {
          print('❌ userData n\'est pas une Map: ${userData.runtimeType}');
          return false;
        }
      } else {
        print('❌ Pas de champ "user" dans la réponse');
        return false;
      }
    } catch (e) {
      print('❌ Erreur connexion: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _currentUser = null;
  }
}