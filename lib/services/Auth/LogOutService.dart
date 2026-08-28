import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LogOutService {
  static Future<Map<String, dynamic>> logout() async {
    int attempts = 0;
    final prefs = await SharedPreferences.getInstance();
    const int maxAttempts = 2;
    http.Response? response;
    while (attempts < maxAttempts) {
      print("llamando a validar token");
       final token = prefs.getString('token');
      try {
        response = await http
            .post(
              Uri.parse('${dotenv.env['API_URL']}/api/Auth/logout'),
              headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token',},
            )
            .timeout(const Duration(seconds: 30));
        print(response.body);
        final data = jsonDecode(response.body);
        if (response.statusCode == 200) {
          // f
          return {'success': true};
        } else {
          return {'success': false, 'message': data['message']};
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

    return {'success': false, 'message': 'No se pudo completar el registro'};
  }
}
