class Utilisateur {
  final int? id;
  final String nom;
  final String email;
  final String password;
  final String? telephone;
  String role;
  final DateTime dateCreation;
  String? photoUrl;

  Utilisateur({
    this.id,
    required this.nom,
    required this.email,
    required this.password,
    this.telephone,
    this.role = 'membre',
    required this.dateCreation,
    this.photoUrl,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nom: json['nom'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      telephone: json['telephone'],
      role: json['role'] ?? 'membre',
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'])
          : DateTime.now(),
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'password': password,
      'telephone': telephone,
      'role': role,
      'date_creation': dateCreation.toIso8601String(),
      'photo_url': photoUrl,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isMembre => role == 'membre';
}