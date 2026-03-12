class Bien {
  final int idBien;
  final String nomBien;
  final String rueBien;
  final String descriptionBien;
  final String superficieBien;
  final String animauxBien;
  final int nbCouchage;
  final String ville;
  final double latitude;
  final double longitude;
  final int prixNuit;
  final double noteMoyenne;
  final int nbAvis;
  final String photoUrl;
  final List<Prestation>? prestations;
  final List<Avis>? avis;

  Bien({
    required this.idBien,
    required this.nomBien,
    required this.rueBien,
    required this.descriptionBien,
    required this.superficieBien,
    required this.animauxBien,
    required this.nbCouchage,
    required this.ville,
    required this.latitude,
    required this.longitude,
    required this.prixNuit,
    required this.noteMoyenne,
    required this.nbAvis,
    required this.photoUrl,
    this.prestations,
    this.avis,
  });

  factory Bien.fromJson(Map<String, dynamic> json) {
    int parseIntValue(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDoubleValue(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Bien(
      idBien: parseIntValue(json['id_bien']),
      nomBien: (json['nom_bien'] as String?)?.trim() ?? '',
      rueBien: (json['rue_bien'] as String?)?.trim() ?? '',
      descriptionBien: (json['description_bien'] as String?)?.trim() ?? '',
      superficieBien: (json['superficie_bien'] as String?)?.trim() ?? '',
      animauxBien: (json['animaux_bien'] as String?)?.trim() ?? 'Non',
      nbCouchage: parseIntValue(json['nb_couchage']),
      ville: (json['ville'] as String?)?.trim() ?? '',
      latitude: parseDoubleValue(json['latitude']),
      longitude: parseDoubleValue(json['longitude']),
      prixNuit: parseIntValue(json['prix_nuit']),
      noteMoyenne: parseDoubleValue(json['note_moyenne']),
      nbAvis: parseIntValue(json['nb_avis']),
      photoUrl: (json['photo_url'] as String?)?.trim() ?? '',
      prestations:
          json['prestations'] != null
              ? (json['prestations'] as List)
                  .map((p) => Prestation.fromJson(p as Map<String, dynamic>))
                  .toList()
              : null,
      avis:
          json['avis'] != null
              ? (json['avis'] as List)
                  .map((a) => Avis.fromJson(a as Map<String, dynamic>))
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_bien': idBien,
      'nom_bien': nomBien,
      'rue_bien': rueBien,
      'description_bien': descriptionBien,
      'superficie_bien': superficieBien,
      'animaux_bien': animauxBien,
      'nb_couchage': nbCouchage,
      'ville': ville,
      'latitude': latitude,
      'longitude': longitude,
      'prix_nuit': prixNuit,
      'note_moyenne': noteMoyenne,
      'nb_avis': nbAvis,
      'photo_url': photoUrl,
      'prestations': prestations?.map((p) => p.toJson()).toList(),
      'avis': avis?.map((a) => a.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'Bien(id: $idBien, nom: $nomBien, ville: $ville, prix: $prixNuit€, note: $noteMoyenne/5)';
}

class Prestation {
  final int id;
  final String nom;

  Prestation({required this.id, required this.nom});

  factory Prestation.fromJson(Map<String, dynamic> json) {
    return Prestation(
      id: json['id'] as int? ?? 0,
      nom: json['nom'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nom': nom};
  }
}

class Avis {
  final int id;
  final int note;
  final String commentaire;
  final String date;

  Avis({
    required this.id,
    required this.note,
    required this.commentaire,
    required this.date,
  });

  factory Avis.fromJson(Map<String, dynamic> json) {
    return Avis(
      id: json['id'] as int? ?? 0,
      note: json['note'] as int? ?? 0,
      commentaire: json['commentaire'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'note': note, 'commentaire': commentaire, 'date': date};
  }
}
