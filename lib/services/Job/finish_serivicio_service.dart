import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/material/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FinishSerivicioService {
  static Future<Map<String, dynamic>> Send({
    required String job_id,
    required double total,
    required double material,
    required double iva,
    required double? labor_cost,
    required String description,
    required bool isexpress,
    required List<MaterialModel> materials,
  }) async {
    int attempts = 0;
    const int maxAttempts = 2;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = {'Authorization': 'Bearer $token'};
    http.Response? response;
    while (attempts < maxAttempts) {
      print("llamando a crear ${isexpress}");
      try {
        response = await http
            .post(
              Uri.parse('${dotenv.env['API_URL']}/api/Payment'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'job_id': job_id,
                'materials': material,
                'iva': iva,
                'total': total,
                'labor_cost': labor_cost,
                'description': description,
                'isexpress': isexpress,
                'materiales': materials.map((m) => m.toJson()).toList(),
              }),
            )
            .timeout(const Duration(seconds: 30));
        print(response.statusCode);
        if (response.statusCode == 200) {
          return {'success': true, 'data': jsonDecode(response.body)};
        }

        else if (response.statusCode == 401) {
          return {
            'success': false,
            'message': jsonDecode(response.body)['message'],
          };
        }

        else if (response.statusCode == 400) {
          return {
            'success': false,
            'message': jsonDecode(response.body)['message'],
          };
        }
      } on TimeoutException {
        return {'success': false, 'message': 'Tiempo de espera agotado'};
      } on SocketException {
        return {'success': false, 'message': 'No hay conexión a Internet'};
      } catch (e) {
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
