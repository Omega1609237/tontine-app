class Membre {
  final int? id;
  final int tontineId;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  final DateTime dateInscription;
  final bool estActif;

  Membre({
    this.id,
    required this.tontineId,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    required this.dateInscription,
    this.estActif = true,
  });

  factory Membre.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.parse(value);
      return 0;
    }

    return Membre(
      id: parseInt(json['id']),
      tontineId: parseInt(json['tontine_id']),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'],
      dateInscription: DateTime.parse(json['date_inscription']),
      estActif: json['est_actif'] == 1 || json['est_actif'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
    };
  }

  String get nomComplet => '$prenom $nom';
}