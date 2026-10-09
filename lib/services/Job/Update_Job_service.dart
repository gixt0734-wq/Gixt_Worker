import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UpdateJobsService {
  static Future<Map<String, dynamic>> Update({
    required String action,
    required String job_id,
    required double? latitude,
    required double? longitude,
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;
    final prefs = await SharedPreferences.getInstance();
    http.Response? response;
    while (attempts < maxAttempts) {
      print("llamando a crear");
      try {
        final token = prefs.getString('token');
        final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
        response = await http
            .patch(
              Uri.parse('${dotenv.env['API_URL']}/api/Jobs/Status'),
              headers: headers,
              body: json.encode({
                'id': job_id,
                'action': action,
                'latitude_worker': latitude,
                'longitude_worker': longitude,
              }),
            )
            .timeout(const Duration(seconds: 30));
        print(response.statusCode);
        print("response body: ${response.body}");
        if (response.statusCode == 200) {
          return {'success': true, 'data': jsonDecode(response.body)};
        }

        else if (response.statusCode == 401) {
          print("🔐 Token expirado. Refrescando token...");

          final ok = await RefreshAccesTokenService.refresh();

          if (!ok) {
            print("❌ No se pudo refrescar el token");
            return {
              'success': false,
              'message': 'Error inesperado',
            };
          }

          print("✅ Token actualizado. Reintentando petición...");

          continue;
        }

        else if (response.statusCode == 400) {
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
    return {'success': false, 'message': 'No se pudo completar el registro'};
  }
}
