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
      print('✅ ${_tontines.length} tontine(s) chargée(s)');
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur chargerTontines: $e');
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
      final nouvelleTontine = Tontine.fromJson(data);
      _tontines.add(nouvelleTontine);
      _error = null;
      print('✅ Tontine ajoutée: ${nouvelleTontine.nom}');
      // Mettre à jour les statistiques après ajout
      await chargerStatistiques();
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur ajouterTontine: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
      print('✅ ${_membres.length} membre(s) chargé(s) pour tontine $tontineId');
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur chargerMembres: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ajouterMembre(int tontineId, Membre membre) async {
    print('➕ Ajout membre dans provider pour tontine $tontineId');
    try {
      final data = await ApiService.createMembre(tontineId, membre.toJson());
      _membres.add(Membre.fromJson(data));
      _error = null;
      notifyListeners();
      // Mettre à jour les statistiques après ajout
      await chargerStatistiques();
      // Recharger les tontines pour mettre à jour le nombre de membres
      await chargerTontines();
      print('✅ Membre ajouté avec succès');
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur ajout membre: $e');
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
      await chargerTontines();
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
      // Mettre à jour les statistiques après ajout
      await chargerStatistiques();
      await chargerTontines();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> supprimerCotisation(int id) async {
    try {
      await ApiService.deleteCotisation(id);
      _cotisations.removeWhere((c) => c.id == id);
      _error = null;
      notifyListeners();
      await chargerStatistiques();
      await chargerTontines();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ========== STATISTIQUES ==========
  Future<void> chargerStatistiques() async {
    try {
      final data = await ApiService.getStatistiques();
      _statistiques = {
        'totalTontines': data['totalTontines'] ?? 0,
        'totalMembres': data['totalMembres'] ?? 0,
        'totalCotisations': data['totalCotisations'] ?? 0,
        'tauxParticipation': data['tauxParticipation'] ?? 0,
      };
      _error = null;
      print('📊 Statistiques chargées: ${_statistiques}');
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur chargerStatistiques: $e');
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