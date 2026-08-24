import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SessionDiditService {
  static Future<Map<String, dynamic>> crear({
    required String user_id,
    required String token
  }) async {
    int attempts = 0;
    const int maxAttempts = 3;
    http.Response? response;

    while (attempts < maxAttempts) {
      print('llamando a login');
      try {
        response = await http
            .post(
              Uri.parse('${dotenv.env['API_URL']}/api/Didit/session/$user_id'),
              headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token',},
            )
            .timeout(const Duration(seconds: 30));
        print(response.body);
        if (response.statusCode == 200) {
          return {
            'success': true,
            'data': jsonDecode(response.body),
          };
        }

       
      } on TimeoutException {
        return {
          'success': false,
          'message': 'Tiempo de espera agotado',
        };
      } on SocketException {
        return {
          'success': false,
          'message': 'No hay conexión a Internet',
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Error inesperado',
        };
      }

      attempts++;
      if (attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    return {
      'success': false,
      'message': 'No se pudo completar el login',
    };
  }
}
