import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/bien.dart';

class BienService {
  static const String _baseUrl =
      'http://localhost/TS2/meuble_flutter/mobile_meuble/flutter_application_1/api';

  static Future<Map<String, dynamic>> fetchBiens({
    int page = 1,
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

      final uri = Uri.parse('$_baseUrl/biens.php').replace(queryParameters: params);

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          return {
            'success': true,
            'biens': (jsonResponse['data'] as List)
                .map((bien) => Bien.fromJson(bien as Map<String, dynamic>))
                .toList(),
            'page': jsonResponse['page'],
            'total': jsonResponse['total'],
            'pages': jsonResponse['pages'],
          };
        } else {
          throw Exception(
              jsonResponse['error'] ?? 'Erreur serveur inconnue');
        }
      } else {
        throw Exception(
            'Erreur serveur: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur de connexion au serveur: $e');
    } catch (e) {
      throw Exception('Erreur lors du chargement des biens: $e');
    }
  }

  static Future<Bien> fetchBienDetail(int idBien) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/bien.php?id=$idBien'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          return Bien.fromJson(jsonResponse['data'] as Map<String, dynamic>);
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
