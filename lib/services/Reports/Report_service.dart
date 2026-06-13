import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON
class Reports {
  String report_id;
  String description;
  String reason;
  String status_report;
  String type;
  String created_at;
  String? type_job;

  Reports({
    required this.report_id,
    required this.description,
    required this.reason,
    required this.status_report,
    required this.type,
    required this.created_at,
    required this.type_job

  });

  factory Reports.fromJson(Map<String, dynamic> json) {
    return Reports(
      report_id: json['report_id'] ?? '',
      description: json['description'] ?? '',
      reason: json['reason'] ?? '',
      status_report: json['status_report'] ?? '',
      type: json['type'] ?? '',
      type_job : json['type_job'] ?? '',
      created_at: json['created_at'] ?? '',
    );
  }
}


class ReportsService {
  List<Reports> reports = []; // Lista de empresas
  int pageNumber = 1;
  bool isLoading = false;
  bool hasMore = true;

  set loading(bool loading) {}

  Future<bool> fetchData({bool forceRefresh = false}) async {
    print("fetch servicios");

    final prefs = await SharedPreferences.getInstance();
    print("🌐 Llamando API");
    String? id_user = prefs.getString('id');
    final token = prefs.getString('token');
    final headers = {'Authorization': 'Bearer $token'};

    try {
      isLoading = true;

      final response = await http
          .get(
            Uri.parse(
              '${dotenv.env['API_URL']}/api/Report/Worker?id_user=${id_user}',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));
      ;

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        print(jsonResponse);
        reports
          ..clear()
          ..addAll(jsonResponse.map((e) => Reports.fromJson(e)));

        return true;
      }
      print("❌ Error HTTP: ${response.statusCode}");
      return false;
    } on TimeoutException {
      print("⏱️ Timeout de la API");
      return false;
    } on SocketException {
      print("🌐 Sin conexión a internet");
      return false;
    } catch (e) {
      print("❌ Error inesperado: $e");
      return false;
    } finally {
      isLoading = false;
    }
  }
}
