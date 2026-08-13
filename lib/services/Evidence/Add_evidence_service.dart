import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddEvidenceService {
  static Future<Map<String, dynamic>> Send({
    required String job_id,
    required bool is_express,
    List<File?> images = const [],
  }) async {

    int attempts = 0;
    const int maxAttempts = 2;
    final prefs = await SharedPreferences.getInstance();
    while (attempts < maxAttempts) {
      print("llamando a crear ${is_express}");
      try {
      
      final token = prefs.getString('token');
   
      String? id_user = prefs.getString('id');
        final uri = Uri.parse('${dotenv.env['API_URL']}/api/Evidence');

        // Crear MultipartRequest
        var request = http.MultipartRequest('POST', uri);
        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });
        // Campos de texto
        request.fields['job_id'] = job_id!;
        request.fields['user_id'] = id_user!;
        request.fields['is_express'] = is_express.toString();

        for (int i = 0; i < images.length; i++) {
          if (images[i] != null) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'images', // mismo nombre que el DTO
                images[i]!.path,
              ),
            );
          }
        }
       

       
        // Enviar request
        var streamedResponse = await request.send().timeout(const Duration(seconds: 60));

        // Convertir la respuesta a String
        final responseString = await streamedResponse.stream.bytesToString();

        print(responseString);

        if (streamedResponse.statusCode == 200) {
            return {
              'success': true,
              'message': 'creado correctamente',
            };
        }
        if (streamedResponse.statusCode == 401) {
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

        if(streamedResponse.statusCode == 400)
        {
          return {
            'success': false,
            'message': 'error al crear servicio',
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
