import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ValidarEmailService {
  static Future<Map<String, dynamic>> Crear({
    required String email,
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;

    while (attempts < maxAttempts) {
      print("llamando a crear");
      try {
        final uri = Uri.parse('${dotenv.env['API_URL']}/api/Verfication/email');

        var response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json',},
          body: json.encode({'email': email,}),
        );

        if (response.statusCode == 200) {
            print(response.body);
            final data = jsonDecode(response.body)['message'];
            print(data);
            return {
              'success': true,
              'data': data,
            };
          
        }
        if (response.statusCode == 401) {
          return {
            'success': false,
            'message': jsonDecode(response.body)['message'],
          };
        }

        if(response.statusCode == 400)
        {
          return {
            'success': false,
            'message': jsonDecode(response.body)['message'],
          };
        }
        if(response.statusCode == 500)
        {
          return {
            'success': false,
            'message': jsonDecode(response.body)['message'],
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
      'message': 'No se pudo completar el proceso',
    };
  }
}
