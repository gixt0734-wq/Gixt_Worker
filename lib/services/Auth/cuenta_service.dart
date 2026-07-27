import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/config/device.dart';
import 'package:gixt_worker/services/Auth/auth_service.dart';
import 'package:http/http.dart' as http;

class CuentaService {
  static Future<Map<String, dynamic>> Crear({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required File image, // ahora es File
    required String phone,
    required String gender,
    required String  birth_date,
    required bool terms,
    required String deviceId,
    required String deviceName,
    required String tokenFcm,
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;

    while (attempts < maxAttempts) {
      print("llamando a crear");
      try {
        final uri = Uri.parse('${dotenv.env['API_URL']}/api/Workers');

        // Crear MultipartRequest
        var request = http.MultipartRequest('POST', uri);

        // Campos de texto
        request.fields['email'] = email;
        request.fields['password'] = password;
        request.fields['first_name'] = firstName;
        request.fields['last_name'] = lastName;
        request.fields['phone'] = phone;
        request.fields['gender'] = gender;
        request.fields['deviceId'] = deviceId;
        request.fields['deviceName'] = deviceName;
        request.fields['tokenFcm'] = tokenFcm;
       final parts = birth_date.split('/');

request.fields['birth_date'] =
    '${parts[2]}-${parts[1]}-${parts[0]}';
        request.fields['terms'] = terms.toString();

        // Archivo
        request.files.add(
          await http.MultipartFile.fromPath(
            'imagen', // nombre del campo que espera el backend
            image.path,
          ),
        );

        // Enviar request
        var streamedResponse = await request.send().timeout(const Duration(seconds: 30));

        // Convertir la respuesta a String
        final responseString = await streamedResponse.stream.bytesToString();

        print(responseString);

        if (streamedResponse.statusCode == 200) {
          final result = jsonDecode(responseString);
          if (result['success'] == true) {
            return {
              'success': true,
              'data':  jsonDecode(responseString),
            };
          } else {
            return {
            'success': false,
            'message': result['message'],
            };
          }
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
