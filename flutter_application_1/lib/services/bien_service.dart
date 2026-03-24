import 'package:http/http.dart' as http;
import 'package:flutter/material.dart' show DateTimeRange;
import 'dart:convert';
import '../models/bien.dart';

class BienService {
  static const String _baseUrl =
      'http://localhost/TS2/meuble_flutter/mobile_meuble/flutter_application_1/api';

  static const String _mediaUrl =
      'http://localhost/TS2/meuble_flutter/mobile_meuble/flutter_application_1/';

  static Future<Map<String, dynamic>> fetchBiens({
    int page = 1,
    int perPage = 10,
    double prixMin = 0,
    double prixMax = 10000,
    int nbCouchageMin = 0,
    String? animaux,
    List<int> prestations = const [],
  }) async {
    try {
      // Construire les paramètres de requête
      var params = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        'prix_min': prixMin.toInt().toString(),
        'prix_max': prixMax.toInt().toString(),
      };

      if (nbCouchageMin > 0) {
        params['nb_couchage'] = nbCouchageMin.toString();
      }

      if (animaux != null && animaux.isNotEmpty) {
        params['animaux'] = animaux;
      }

      if (prestations.isNotEmpty) {
        params['prestations'] = prestations.join(',');
      }

      final uri = Uri.parse(
        '$_baseUrl/biens.php',
      ).replace(queryParameters: params);

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          return {
            'success': true,
            'biens':
                (jsonResponse['data'] as List)
                    .map((bien) {
                      final b = bien as Map<String, dynamic>;
                      if ((b['photo_url'] as String? ?? '').isNotEmpty) {
                        b['photo_url'] = _mediaUrl + b['photo_url'];
                      }
                      return Bien.fromJson(b);
                    })
                    .toList(),
            'page': jsonResponse['page'],
            'total': jsonResponse['total'],
            'pages': jsonResponse['pages'],
          };
        } else {
          throw Exception(jsonResponse['error'] ?? 'Erreur serveur inconnue');
        }
      } else {
        throw Exception(
          'Erreur serveur: ${response.statusCode} - ${response.body}',
        );
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur de connexion au serveur: $e');
    } catch (e) {
      throw Exception('Erreur lors du chargement des biens: $e');
    }
  }

  static Future<Map<String, dynamic>> verifierDisponibilite({
    required int idBien,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse('$_baseUrl/verifier_disponibilite.php').replace(
      queryParameters: {
        'id_bien':    idBien.toString(),
        'date_debut': fmt(dateDebut),
        'date_fin':   fmt(dateFin),
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<DateTimeRange>> fetchPeriodesReservees(int idBien) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/disponibilite.php?id_bien=$idBien'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          return (json['periodes'] as List).map((p) {
            final debut = DateTime.parse(p['date_debut']);
            final fin = DateTime.parse(p['date_fin']);
            return DateTimeRange(start: debut, end: fin);
          }).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> creerReservation({
    required int idBien,
    required DateTime dateDebut,
    required DateTime dateFin,
    int idLocataire = 19,
    int idTarif = 29,
  }) async {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final response = await http
        .post(
          Uri.parse('$_baseUrl/reserver.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id_bien':      idBien,
            'date_debut':   fmt(dateDebut),
            'date_fin':     fmt(dateFin),
            'id_locataire': idLocataire,
            'id_tarif':     idTarif,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Bien> fetchBienDetail(int idBien) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/bien.php?id=$idBien'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'] as Map<String, dynamic>;
          // Préfixer les URLs des photos
          if ((data['photo_url'] as String? ?? '').isNotEmpty) {
            data['photo_url'] = _mediaUrl + data['photo_url'];
          }
          if (data['photos'] != null) {
            data['photos'] = (data['photos'] as List)
                .map((p) => _mediaUrl + p.toString())
                .toList();
          }
          return Bien.fromJson(data);
        } else {
          throw Exception(jsonResponse['error'] ?? 'Erreur serveur inconnue');
        }
      } else {
        throw Exception(
          'Erreur serveur: ${response.statusCode} - ${response.body}',
        );
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur de connexion au serveur: $e');
    } catch (e) {
      throw Exception('Erreur lors du chargement du bien: $e');
    }
  }
}
