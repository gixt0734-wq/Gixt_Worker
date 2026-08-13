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
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;
    final prefs = await SharedPreferences.getInstance();

    while (attempts < maxAttempts) {
      print("llamando a crear");
      try {
        final token = prefs.getString('token');
        final uri = Uri.parse('${dotenv.env['API_URL']}/api/Jobs/Status');

        // Crear MultipartRequest
        var request = http.MultipartRequest('PATCH', uri);
        request.headers.addAll({'Authorization': 'Bearer $token'});

        // Campos de texto
        request.fields['id'] = job_id;
        request.fields['action'] = action;

        // Enviar request
        var streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
        );

        // Convertir la respuesta a String
        final responseString = await streamedResponse.stream.bytesToString();

        print('Error :${responseString}');

        if (streamedResponse.statusCode == 200) {
          return {'success': true, 'data': jsonDecode(responseString)};
        }

        if (streamedResponse.statusCode == 401) {
          print("🔐 Token expirado. Refrescando token...");

          final ok = await RefreshAccesTokenService.refresh();

          if (streamedResponse.statusCode == 401) {
            print("🔐 Token expirado. Refrescando token...");

            final ok = await RefreshAccesTokenService.refresh();

            if (!ok) {
              print("❌ No se pudo refrescar el token");
              return {'success': false, 'message': 'Error inesperado'};
            }

            print("✅ Token actualizado. Reintentando petición...");

            continue;
          }
        }

        if (streamedResponse.statusCode == 400) {
          return {
            'success': false,
            'message': jsonDecode(responseString)['message'],
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
