import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/utilisateur.dart';

class ApiService {
  static const String baseUrl = 'https://tontine-backend-1-5fe3.onrender.com/api';
  static String? _token;

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    return _token;
  }

  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // ========== AUTHENTIFICATION ==========
  static Future<Map<String, dynamic>> register(
      String nom, String email, String password, String? telephone, {String role = 'membre'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nom': nom,
        'email': email,
        'password': password,
        'telephone': telephone,
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    }
    throw Exception(jsonDecode(response.body)['error']);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    }
    throw Exception(jsonDecode(response.body)['error']);
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ========== UTILISATEUR ==========
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement utilisateur');
  }

  // ========== UPLOAD IMAGE ==========
  static Future<String?> uploadImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      final token = await getToken();
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data['imageUrl'];
      }
      return null;
    } catch (e) {
      print('❌ Erreur upload: $e');
      return null;
    }
  }

  static Future<bool> updateUser(Utilisateur user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/${user.id}'),
      headers: _getHeaders(),
      body: jsonEncode({
        'nom': user.nom,
        'email': user.email,
        'telephone': user.telephone,
        'photo_url': user.photoUrl,
      }),
    );
    return response.statusCode == 200;
  }

  // ========== TONTINES ==========
  static Future<List<dynamic>> getTontines() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tontines'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement tontines');
  }

  static Future<Map<String, dynamic>> createTontine(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tontines'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur création tontine');
  }

  static Future<Map<String, dynamic>> updateTontine(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tontines/$id'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur modification tontine');
  }

  static Future<void> deleteTontine(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tontines/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression tontine');
    }
  }

  // ========== MEMBRES ==========
  static Future<List<dynamic>> getMembres(int tontineId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tontines/$tontineId/membres'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement membres');
  }

  static Future<Map<String, dynamic>> createMembre(int tontineId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tontines/$tontineId/membres'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur création membre');
  }

  static Future<void> deleteMembre(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/membres/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression membre');
    }
  }

  // ========== COTISATIONS ==========
  static Future<List<dynamic>> getCotisations(int tontineId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tontines/$tontineId/cotisations'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement cotisations');
  }

  static Future<Map<String, dynamic>> createCotisation(int tontineId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tontines/$tontineId/cotisations'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur création cotisation');
  }

  static Future<Map<String, dynamic>> updateCotisation(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cotisations/$id'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        print("📊 Statut Erreur: ${response.statusCode}");
        print("📝 Réponse Serveur: ${response.body}");
        throw 'Erreur ${response.statusCode}';
      }
    } catch (e) {
      print('❌ Erreur détaillée dans updateCotisation: $e');
      rethrow;
    }
  }

  static Future<void> deleteCotisation(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cotisations/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression cotisation');
    }
  }

  // ========== STATISTIQUES ==========
  static Future<Map<String, dynamic>> getStatistiques() async {
    final response = await http.get(
      Uri.parse('$baseUrl/statistiques'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur chargement statistiques');
  }
}