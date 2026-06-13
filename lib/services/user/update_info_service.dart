import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/config/device.dart';
import 'package:gixt_worker/services/Auth/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfoService {
  static Future<Map<String, dynamic>> Send({
    required String description,
    required String city,
    required double latitude,
    required double longitude,
    required double labor_cost,
    required double range_km,
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;
     final prefs = await SharedPreferences.getInstance();
    String? id_user = prefs.getString('id');

    while (attempts < maxAttempts) {
      print("llamando a crear");
      try {
        final uri = Uri.parse('${dotenv.env['API_URL']}/api/Workers/info');

        // Crear MultipartRequest
        var request = http.MultipartRequest('PUT', uri);

        // Campos de texto
        request.fields['user_id'] = id_user!;
        request.fields['description'] = description;
        request.fields['city'] = city;
        request.fields['latitude'] = latitude.toString();
        request.fields['longitude'] = longitude.toString();
        request.fields['km_cost'] = labor_cost.toString();
        request.fields['range_km'] = range_km.toString();

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
