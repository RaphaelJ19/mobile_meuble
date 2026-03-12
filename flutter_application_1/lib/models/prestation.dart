class Prestation {
  final int id;
  final String nom;
  final String icon;

  Prestation({required this.id, required this.nom, required this.icon});

  /// Créer un objet Prestation à partir d'une map JSON
  factory Prestation.fromJson(Map<String, dynamic> json) {
    return Prestation(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      icon: json['icon'] ?? 'check_circle',
    );
  }

  /// Convertir l'objet en map JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'nom': nom, 'icon': icon};
  }

  @override
  String toString() => 'Prestation(id: $id, nom: $nom, icon: $icon)';
}
