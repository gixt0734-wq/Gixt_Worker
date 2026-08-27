import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeleteUserService {
  static Future<Map<String, dynamic>> delete(
    {required String recoveryToken}
  ) async {
    int attempts = 0;
    const int maxAttempts = 3;
   final prefs = await SharedPreferences.getInstance();
    String? id_user = prefs.getString('id');

    while (attempts < maxAttempts) {
      print("llamando a crear");
      try {
       final uri = Uri.parse('${dotenv.env['API_URL']}/api/Users');
        final token = prefs.getString('token');
        // Crear MultipartRequest
        var response = await http.delete(
          uri,
          headers: {'Content-Type': 'application/json','Authorization': 'Bearer $token'},
          body: json.encode({'user_id': id_user,'recoveryToken' :recoveryToken}),
        );

        if (response.statusCode == 200) {
          return {'success': true, 'data': jsonDecode(response.body)};
        }

        if (response.statusCode == 401) {
          print("🔐 Token expirado. Refrescando token...");

          final ok = await RefreshAccesTokenService.refresh();

          if (!ok) {
            print("❌ No se pudo refrescar el token");
            return {'success': false, 'message': 'Error inesperado'};
          }

          print("✅ Token actualizado. Reintentando petición...");

          continue;
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

    return {'success': false, 'message': 'No se pudo completar la peticion, vuelva a intentarlo'};
  }
}
