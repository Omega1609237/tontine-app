import 'package:flutter/material.dart';
import '../models/tontine.dart';
import '../models/membre.dart';
import '../models/cotisation.dart';
import '../services/api_service.dart';

class TontineProvider extends ChangeNotifier {
  List<Tontine> _tontines = [];
  List<Membre> _membres = [];
  List<Cotisation> _cotisations = [];
  Tontine? _tontineSelectionnee;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _statistiques = {};

  List<Tontine> get tontines => _tontines;
  List<Membre> get membres => _membres;
  List<Cotisation> get cotisations => _cotisations;
  Tontine? get tontineSelectionnee => _tontineSelectionnee;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get statistiques => _statistiques;

  TontineProvider() {
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    await chargerTontines();
    await chargerStatistiques();
  }

  // ========== TONTINES ==========
  Future<void> chargerTontines() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getTontines();
      _tontines = data.map((json) => Tontine.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ajouterTontine(Tontine tontine) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.createTontine(tontine.toJson());
      _tontines.add(Tontine.fromJson(data));
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
      await chargerStatistiques();
    }
  }

  Future<void> modifierTontine(int id, Tontine tontine) async {
    try {
      final data = await ApiService.updateTontine(id, tontine.toJson());
      final index = _tontines.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tontines[index] = Tontine.fromJson(data);
      }
      _error = null;
      notifyListeners();
      await chargerStatistiques();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> supprimerTontine(int id) async {
    try {
      await ApiService.deleteTontine(id);
      _tontines.removeWhere((t) => t.id == id);
      _error = null;
      notifyListeners();
      await chargerStatistiques();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ========== MEMBRES ==========
  Future<void> chargerMembres(int tontineId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getMembres(tontineId);
      _membres = data.map((json) => Membre.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ajouterMembre(int tontineId, Membre membre) async {
    try {
      final data = await ApiService.createMembre(tontineId, membre.toJson());
      _membres.add(Membre.fromJson(data));
      _error = null;
      notifyListeners();
      await chargerStatistiques();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> supprimerMembre(int id) async {
    try {
      await ApiService.deleteMembre(id);
      _membres.removeWhere((m) => m.id == id);
      _error = null;
      notifyListeners();
      await chargerStatistiques();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ========== COTISATIONS ==========
  Future<void> chargerCotisations(int tontineId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getCotisations(tontineId);
      _cotisations = data.map((json) => Cotisation.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ajouterCotisation(int tontineId, int membreId, double montant, String modePaiement) async {
    try {
      final data = await ApiService.createCotisation(tontineId, {
        'membre_id': membreId,
        'montant': montant,
        'mode_paiement': modePaiement,
      });
      _cotisations.add(Cotisation.fromJson(data));
      _error = null;
      notifyListeners();
      await chargerTontines();
      await chargerStatistiques();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ========== NOUVELLE MÉTHODE ==========
  // Modifier une cotisation existante (supprimer + recréer)
  Future<void> modifierCotisation(int id, double nouveauMontant, String modePaiement) async {
    try {
      // 1. Récupérer l'ancienne cotisation
      final ancienne = _cotisations.firstWhere((c) => c.id == id);

      // 2. Supprimer l'ancienne cotisation
      await ApiService.deleteCotisation(id);

      // 3. Créer une nouvelle cotisation avec le nouveau montant
      await ApiService.createCotisation(ancienne.tontineId, {
        'membre_id': ancienne.membreId,
        'montant': nouveauMontant,
        'mode_paiement': modePaiement,
      });

      // 4. Recharger les données
      await chargerCotisations(ancienne.tontineId);
      await chargerTontines();
      await chargerStatistiques();

      _error = null;
      notifyListeners();
      print('✅ Cotisation modifiée avec succès');

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      print('❌ Erreur modification cotisation: $e');
    }
  }

  Future<void> supprimerCotisation(int id) async {
    try {
      await ApiService.deleteCotisation(id);
      _cotisations.removeWhere((c) => c.id == id);
      _error = null;
      notifyListeners();
      await chargerTontines();
      await chargerStatistiques();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ========== STATISTIQUES ==========
  Future<void> chargerStatistiques() async {
    try {
      final data = await ApiService.getStatistiques();
      _statistiques = data;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // ========== UTILITAIRES ==========
  void selectionnerTontine(Tontine tontine) {
    _tontineSelectionnee = tontine;
    chargerMembres(tontine.id!);
    chargerCotisations(tontine.id!);
    notifyListeners();
  }
}