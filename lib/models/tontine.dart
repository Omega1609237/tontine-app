class Tontine {
  final int? id;
  final String nom;
  final double montant;
  final String frequence;
  final int membres;
  final double montantTotal;
  final DateTime dateDebut;
  final String statut;
  final String? description;
  final DateTime dateCreation;

  Tontine({
    this.id,
    required this.nom,
    required this.montant,
    required this.frequence,
    required this.membres,
    this.montantTotal = 0,
    required this.dateDebut,
    this.statut = 'active',
    this.description,
    required this.dateCreation,
  });

  factory Tontine.fromJson(Map<String, dynamic> json) {
    // Convertir les valeurs qui peuvent être des strings ou des nombres
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.parse(value);
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.parse(value);
      return 0;
    }

    return Tontine(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nom: json['nom'] ?? '',
      montant: parseDouble(json['montant']),
      frequence: json['frequence'] ?? 'hebdomadaire',
      membres: parseInt(json['membres']),
      montantTotal: parseDouble(json['montant_total']),
      dateDebut: DateTime.parse(json['date_debut']),
      statut: json['statut'] ?? 'active',
      description: json['description'],
      dateCreation: DateTime.parse(json['date_creation']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'montant': montant,
      'frequence': frequence,
      'membres': membres,
      'date_debut': dateDebut.toIso8601String(),
      'description': description,
    };
  }

  String get frequenceLibelle {
    switch (frequence) {
      case 'quotidienne':
        return 'Quotidienne';
      case 'hebdomadaire':
        return 'Hebdomadaire';
      case 'mensuelle':
        return 'Mensuelle';
      default:
        return frequence;
    }
  }

  double get montantRestant => (montant * membres) - montantTotal;
  double get progression => (montantTotal / (montant * membres) * 100).clamp(0, 100);
}