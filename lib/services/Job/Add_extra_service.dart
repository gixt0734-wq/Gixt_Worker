import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddExtraService {

  static Future<Map<String, dynamic>> Send({
    required String job_id,
    required bool is_express,
    required String problem,
    required String description,
    required double price,
    required String idempotency_key,
    File? image,
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;
    final prefs = await SharedPreferences.getInstance();

    while (attempts < maxAttempts) {
      try {
        final token = prefs.getString('token');
        final uri = Uri.parse('${dotenv.env['API_URL']}/api/AddWork');

        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll({'Authorization': 'Bearer $token'});
        request.fields['job_id'] = job_id;
        request.fields['idempotency_key'] = idempotency_key;
        request.fields['isexpress'] = is_express.toString();
        request.fields['problem'] = problem;
        request.fields['description'] = description;
        request.fields['labor_cost'] = price.toString();
        print("request fields: ${request.fields}");

        if (image != null) {
          request.files.add(
            await http.MultipartFile.fromPath('image', image.path),
          );
        }

        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 60),
        );
        final responseString = await streamedResponse.stream.bytesToString();
        print("respuesta: ${responseString}");
        if (streamedResponse.statusCode == 200) {
          return {'success': true, 'message': 'creado correctamente'};
        }

        if (streamedResponse.statusCode == 401) {
          final ok = await RefreshAccesTokenService.refresh();
          if (!ok) {
            return {'success': false, 'message': 'Error inesperado'};
          }
          continue;
        }

        if (streamedResponse.statusCode == 400) {
          String message = 'No se pudo agregar el extra';
          try {
            message = jsonDecode(responseString)['message'] ?? message;
          } catch (_) {}
          return {'success': false, 'message': message};
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
