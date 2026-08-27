import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ValidarOtpService {
  static Future<Map<String, dynamic>> Crear({
    required String email,
    required String otp
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;
    http.Response? response;
    while (attempts < maxAttempts) {
      print("llamando a validar token");
      try {
 
        response = await http
            .post(
              Uri.parse('${dotenv.env['API_URL']}/api/Verfication/reset-otp'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'email': email,
                'otp': otp,
              }),
            )
            .timeout(const Duration(seconds: 30));
        print(response.body);
        final data = jsonDecode(response.body);
        if (response.statusCode == 200) {
          // f
          return {
            'success': true,
            'data': data['recoveryToken'],
          };
        }

        else
        { return {
            'success': false,
            'message': data['message'],
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
