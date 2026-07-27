import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ValidarAccounthService {
  static Future<Map<String, dynamic>> Crear({
    required String email,
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;

    while (attempts < maxAttempts) {
      print("llamando a crear");
      try {
      final uri = Uri.parse('${dotenv.env['API_URL']}/api/Users/verification/user');

        var request = http.MultipartRequest('POST', uri);

        // Campos de texto
        request.fields['email'] = email;

        var streamedResponse = await request.send().timeout(const Duration(seconds: 30));

        // Convertir la respuesta a String
        final response = await streamedResponse.stream.bytesToString();

        if (streamedResponse.statusCode == 200) {
          
            final data = jsonDecode(response)['message'];
            print(data);
            return {
              'success': true,
              'data': data,
            };
          
        }
        if (streamedResponse.statusCode == 401) {
          return {
            'success': false,
            'message': jsonDecode(response)['message'],
          };
        }

        if(streamedResponse.statusCode == 400)
        {
          return {
            'success': false,
            'message': jsonDecode(response)['message'],
          };
        }
        if(streamedResponse.statusCode == 500)
        {
          return {
            'success': false,
            'message': jsonDecode(response)['message'],
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
