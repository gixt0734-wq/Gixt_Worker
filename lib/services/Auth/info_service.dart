import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/config/device.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:gixt_worker/services/Auth/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InfoService {
  static Future<Map<String, dynamic>> Crear({
    required String description,
    required String city,
    required double latitude,
    required double longitude,
    required double labor_cost,
    required double range_km,
    required String? id,
    required String token,
    List<File?> images = const [],
    List<int?> cat = const [],
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;
     final prefs = await SharedPreferences.getInstance();


    while (attempts < maxAttempts) {
      print("llamando a crear");
      try {
        print(id);
        final uri = Uri.parse('${dotenv.env['API_URL']}/api/Workers/info');

        // Crear MultipartRequest
        var request = http.MultipartRequest('POST', uri);
        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });
        // Campos de texto
        request.fields['user_id'] = id!;
        request.fields['description'] = description;
        request.fields['city'] = city;
        request.fields['latitude'] = latitude.toString();
        request.fields['longitude'] = longitude.toString();
        request.fields['diagnostic_cost'] = labor_cost.toString();
        request.fields['service_radius_km'] = range_km.toString();
        
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
        for (File? img in images)
        {
         if (img != null) {
         request.files.add(
              await http.MultipartFile.fromPath(
                'images', // mismo nombre que el DTO
                img!.path,
              ),
            );
         }
        }

        int catIndex = 0;
        for (int? catid in cat) {
          if (catid != null) {
            request.fields['category_id[$catIndex]'] = catid.toString();
            print(catid);
            catIndex++;
          }
        }

        // Enviar request
        var streamedResponse = await request.send().timeout(const Duration(seconds: 30));

        // Convertir la respuesta a String
        final responseString = await streamedResponse.stream.bytesToString();

        print(responseString);

        if (streamedResponse.statusCode == 200) {
            final data = responseString;
            print(data);
            return {
              'success': true,
              'data': data,
            };
        }
        if (streamedResponse.statusCode == 401) {
          print("🔐 Token expirado. Refrescando token...");

      
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
