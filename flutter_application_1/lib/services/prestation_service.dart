import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/prestation.dart';

class PrestationService {
  // Adresse du serveur local - Chemin correct vers l'API
  static const String _baseUrl =
      'http://localhost/TS2/meuble_flutter/mobile_meuble/flutter_application_1/api';

  /// Récupérer toutes les prestations från l'API
  static Future<List<Prestation>> fetchPrestations() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/prestations.php'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Délai d\'expiration dépassé');
            },
          );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          final List<dynamic> prestationsJson = jsonData['data'];
          return prestationsJson
              .map((p) => Prestation.fromJson(p as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(jsonData['error'] ?? 'Erreur inconnue');
        }
      } else {
        throw Exception(
          'Erreur serveur: ${response.statusCode}\n${response.body}',
        );
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur de connexion au serveur: $e');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }
}
