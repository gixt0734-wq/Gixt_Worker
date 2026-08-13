import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FavoritoService {
  static Future<Map<String, dynamic>> Crear({
    required String service_id,
  }) async {

    int attempts = 0;
    const int maxAttempts = 2;

    while (attempts < maxAttempts) {
      print("llamando a crear");
      try {
      final prefs = await SharedPreferences.getInstance();
      String? id_user = prefs.getString('id');
      final token = prefs.getString('token');
      final headers = {'Authorization': 'Bearer $token'};
        final response = await http.put(
          Uri.parse('${dotenv.env['API_URL']}/api/Favorites?id=${service_id}&userId=${id_user}'),
          headers: headers,
        );
        print(response);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': jsonDecode(response.body)['message'],
          };
        }
        if (response.statusCode == 401) {
          print("🔐 Token expirado. Refrescando token...");

          final ok = await RefreshAccesTokenService.refresh();

          if (!ok) {
            print("❌ No se pudo refrescar el token");
            return {
              'success': false,
              'message': jsonDecode(response.body)['message'],
            };
          }
        }

        if (response.statusCode == 400) {
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
        print(e);
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
