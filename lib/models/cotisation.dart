class Cotisation {
  final int? id;
  final int tontineId;
  final int membreId;
  final String membreNom;
  final double montant;
  final DateTime datePaiement;
  final String? modePaiement;

  Cotisation({
    this.id,
    required this.tontineId,
    required this.membreId,
    required this.membreNom,
    required this.montant,
    required this.datePaiement,
    this.modePaiement,
  });

  factory Cotisation.fromJson(Map<String, dynamic> json) {
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

    return Cotisation(
      id: parseInt(json['id']),
      tontineId: parseInt(json['tontine_id']),
      membreId: parseInt(json['membre_id']),
      membreNom: '${json['prenom']} ${json['nom']}',
      montant: parseDouble(json['montant']),
      datePaiement: DateTime.parse(json['date_paiement']),
      modePaiement: json['mode_paiement'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'membre_id': membreId,
      'montant': montant,
      'mode_paiement': modePaiement,
    };
  }
}