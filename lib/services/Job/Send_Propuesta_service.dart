import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SendPropuestaService {
  static Future<Map<String, dynamic>> Update({
    required double km_cost,
    required String labor_price,
    required String express_id
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;
      final prefs = await SharedPreferences.getInstance();
    String? id_user = prefs.getString('id');

    while (attempts < maxAttempts) {
      print("llamando a crear");
      print(id_user);
      try {
        final uri = Uri.parse('${dotenv.env['API_URL']}/api/Expresss/Send');

        // Crear MultipartRequest
        var request = http.MultipartRequest('POST', uri);

        // Campos de texto
        request.fields['worker'] = id_user!;
        request.fields['id'] = express_id;
        request.fields['km_cost'] = km_cost.toString();
        request.fields['labor_price'] = labor_price.toString();
        print(request.fields);
        // Enviar request
        var streamedResponse = await request.send().timeout(const Duration(seconds: 30));

        // Convertir la respuesta a String
        final responseString = await streamedResponse.stream.bytesToString();

        print('Error :${responseString}');

        if (streamedResponse.statusCode == 200) {
          return {
            'success': true,
            'data': jsonDecode(responseString),
          };
        }

        if (streamedResponse.statusCode == 401) {
          return {
            'success': false,
            'message': jsonDecode(responseString)['message'],
          };
        }

        if(streamedResponse.statusCode == 400)
        {
          return {
            'success': false,
            'message': jsonDecode(responseString)['message'],
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
        print(e);
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
      'message': 'No se pudo completar el registro',
    };
  }
}
