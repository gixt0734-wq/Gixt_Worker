import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CancelJobService {
  static Future<Map<String, dynamic>> CancelJob({
    required String jop_id,
    required String reason,
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;
    final prefs = await SharedPreferences.getInstance();

    while (attempts < maxAttempts) {
      try {
        final token = prefs.getString('token');

        final headers = {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        };

        final uri = Uri.parse('${dotenv.env['API_URL']}/api/Jobs/worker');

        final response = await http
            .delete(
              uri,
              headers: headers,
              body: json.encode({'id': jop_id, 'reason': reason}),
            )
            .timeout(const Duration(seconds: 30));

        print("respuesta: ${response.body}");

        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Servicio cancelado correctamente',
          };
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

        if (response.statusCode == 400) {
          return {'success': false, 'message': 'Error al cancelar el servicio'};
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

    return {'success': false, 'message': 'No se pudo completar la cancelación'};
  }
}
