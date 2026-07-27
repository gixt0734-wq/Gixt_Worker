import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeleteUserService {
  static Future<Map<String, dynamic>> delete(
  ) async {
    int attempts = 0;
    const int maxAttempts = 3;
   final prefs = await SharedPreferences.getInstance();
    String? id_user = prefs.getString('id');

    while (attempts < maxAttempts) {
      print("llamando a crear");
      try {
       final uri = Uri.parse('${dotenv.env['API_URL']}/api/Users/${id_user}');

        // Crear MultipartRequest
        var response = await http.delete(
          uri,
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          return {'success': true, 'data': jsonDecode(response.body)};
        }

        if (response.statusCode == 401) {
          return {
            'success': false,
            'message': jsonDecode(response.body)['message'],
          };
        }
      } on TimeoutException {
        return {'success': false, 'message': 'Tiempo de espera agotado'};
      } on SocketException {
        return {'success': false, 'message': 'No hay conexión a Internet'};
      } catch (e) {
        return {'success': false, 'message': 'Error inesperado'};
      }

      attempts++;
      if (attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    return {'success': false, 'message': 'No se pudo completar el login'};
  }
}
