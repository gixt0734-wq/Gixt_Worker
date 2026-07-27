import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DocumentsService {
  static Future<Map<String, dynamic>> Crear({
    required File? image_ine,
    required File? image_ine_reverso,
    required File? image_cd,
    required File? image_canp,
    required String? id,
  }) async {
    if (id == null ||
        image_ine == null ||
        image_ine_reverso == null ||
        image_cd == null ||
        image_canp == null) {
      return {'success': false, 'message': 'Faltan documentos por subir'};
    }

    int attempts = 0;
    const int maxAttempts = 2;

    while (attempts < maxAttempts) {
      print("llamando a crear");
      print(id);
      try {
        final uri = Uri.parse('${dotenv.env['API_URL']}/api/Workers/documents');

        // Crear MultipartRequest
        var request = http.MultipartRequest('POST', uri);

        // Campos de texto
        request.fields['user_id'] = id;
        request.files.add(
          await http.MultipartFile.fromPath(
            'image_ine', // mismo nombre que el DTO
            image_ine.path,
          ),
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            'image_ine_reverso', // mismo nombre que el DTO
            image_ine_reverso.path,
          ),
        );
        request.files.add(
          await http.MultipartFile.fromPath(
            'image_cd', // mismo nombre que el DTO
            image_cd.path,
          ),
        );
        request.files.add(
          await http.MultipartFile.fromPath(
            'image_canp', // mismo nombre que el DTO
            image_canp.path,
          ),
        );

        // for (int i = 0; i < images.length; i++) {
        //   if (images[i] != null) {
        //     request.files.add(
        //       await http.MultipartFile.fromPath(
        //         'images', // mismo nombre que el DTO
        //         images[i]!.path,
        //       ),
        //     );
        //   }
        // }

        // Enviar request
        var streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
        );

        // Convertir la respuesta a String
        final responseString = await streamedResponse.stream.bytesToString();

        print(responseString);

        if (streamedResponse.statusCode == 200) {
          final data = responseString;
          print(data);
          return {'success': true, 'data': data};
        }
        if (streamedResponse.statusCode == 401) {
          return {
            'success': false,
            'message': jsonDecode(responseString)['message'],
          };
        }

        if (streamedResponse.statusCode == 400) {
          return {
            'success': false,
            'message': jsonDecode(responseString)['message'],
          };
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

    return {'success': false, 'message': 'No se pudo completar el registro'};
  }
}
