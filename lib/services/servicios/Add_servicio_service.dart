import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddServicioService {
  static Future<Map<String, dynamic>> Crear({
    required String name,
    required String description,
    required int time,
    required double price,
    required int category_id,
    List<File?> images = const [],
    required File image,
  }) async {
    
    int attempts = 0;
    const int maxAttempts = 2;
    final prefs = await SharedPreferences.getInstance();
    String? id_user = prefs.getString('id');
    final token = prefs.getString('token');
    final headers = {'Authorization': 'Bearer $token'};

    while (attempts < maxAttempts) {
      print("llamando a crear");
      try {
        final uri = Uri.parse('${dotenv.env['API_URL']}/api/Services');

        // Crear MultipartRequest
        var request = http.MultipartRequest('POST', uri);

        // Campos de texto
        request.fields['user_id'] = id_user!;
        request.fields['service_name'] = name;
        request.fields['description'] = description;
        request.fields['labor_price'] = price.toString();
        request.fields['duration_hours'] = time.toString();
        request.fields['category_id'] = category_id.toString();

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
        // Archivo
         request.files.add(
          await http.MultipartFile.fromPath(
            'image', // nombre del campo que espera el backend
            image.path,
          ),
        );

       
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
          return {
            'success': false,
            'message': 'error al crear servicio',
          };
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
