import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CancelExpressService {
  static Future<Map<String, dynamic>> CancelExpress({
    required String express_id,
    required String reason
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    while (attempts < maxAttempts) {
      try {
        final uri = Uri.parse(
          '${dotenv.env['API_URL']}/api/Expresss/worker',
        );
        print('id enciado ${express_id}');
        final response = await http
            .delete(uri, headers: headers,
            body:  json.encode({
                'id': express_id,
                'reason':reason
              }),
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
          return {'success': false, 'message': 'No autorizado'};
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
