import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService {
  static Future<Map<String, dynamic>> Crear({
    required String first_name,
    required String last_name,
    final File? image, // ahora es File
    required String phone,
    required String gender,
    required String birth_date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    int attempts = 0;
    const int maxAttempts = 2;

    while (attempts < maxAttempts) {
      print("llamando a crear");
      try {
      
        final token = prefs.getString('token');
        String? id_user = prefs.getString('id');

        final uri = Uri.parse('${dotenv.env['API_URL']}/api/Workers/${id_user}');

        // Crear MultipartRequest
        var request = http.MultipartRequest('PUT', uri);
        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });

        // Campos de texto
        request.fields['user_id'] = id_user!;
        request.fields['first_name'] = first_name;
        request.fields['last_name'] = last_name;
        request.fields['phone'] = phone;
        request.fields['gender'] = gender;
        request.fields['birth_date'] = birth_date;
     

        // Archivo
        if (image!= null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              image!.path,
            ),
          );
        }


        // Enviar request
        var streamedResponse = await request.send().timeout(const Duration(seconds: 30));

        // Convertir la respuesta a String
        final responseString = await streamedResponse.stream.bytesToString();

        print(streamedResponse.request);

        if (streamedResponse.statusCode == 200) {
          return {
            'success': true,
            'data': jsonDecode(responseString),
          };
        }

        if (streamedResponse.statusCode == 401) {
          print("🔐 Token expirado. Refrescando token...");

          final ok = await RefreshAccesTokenService.refresh();

          if (!ok) {
            print("❌ No se pudo refrescar el token");
            return {
              'success': false,
              'message': jsonDecode(responseString)['message'],
            };
          }
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
