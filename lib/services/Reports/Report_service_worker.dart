import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON
import 'package:intl/intl.dart';

String formatDateTime(String? date) {
  if (date == null || date.isEmpty) return '';

  final parsed = DateTime.parse(date);

  return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
}

class ReportWorker {
  String report_id;
  String description;
  String reason;
  String status_report;
  String type;
  String created_at;
  String updated_at;
  String solution;
  String? type_job;
  String evidence_image;
  String client_id;
  String username;
  String client_image;

  ReportWorker({
    required this.report_id,
    required this.description,
    required this.reason,
    required this.status_report,
    required this.type,
    required this.solution,
    required this.created_at,
    required this.updated_at,
    required this.type_job,
    required this.evidence_image,
    required this.client_id,
    required this.username,
    required this.client_image,
  });

  factory ReportWorker.fromJson(Map<String, dynamic> json) {
    return ReportWorker(
      report_id: json['report_id'] ?? '',
      description: json['description'] ?? '',
      reason: json['reason'] ?? '',
      status_report: json['status_report'] ?? '',
      solution: json['solution'] ?? '',
      type: json['type'] ?? '',
      type_job: json['type_job'] ?? '',
      created_at: formatDateTime(json['created_at']),
      updated_at: formatDateTime(json['updated_at']),
      evidence_image: json['image_url'] ?? '',
      client_id: json['client']?['user_id'] ?? '',
      username: json['client']?['username'] ?? '',
      client_image: json['client']?['image_url'] ?? '',
    );
  }
}

class ReportsServiceClient {
  List<ReportWorker> report = []; // Lista de empresas
  int pageNumber = 1;
  bool isLoading = false;
  bool hasMore = true;

  set loading(bool loading) {}

  Future<bool> fetchData(String id, {bool forceRefresh = false}) async {
    print("fetch servicios");

    int attempts = 0;
    const int maxAttempts = 2;
    final prefs = await SharedPreferences.getInstance();
    while (attempts < maxAttempts) {
      try {
        print("🌐 Llamando API");
        final token = prefs.getString('token');
        final headers = {'Authorization': 'Bearer $token'};
        isLoading = true;
        final response = await http
            .get(
              Uri.parse('${dotenv.env['API_URL']}/api/Report/User/${id}'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
        ;

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          print(jsonResponse);
          report
            ..clear()
            ..add(ReportWorker.fromJson(jsonResponse));

          return true;
        }

        if (response.statusCode == 401) {
          print("🔐 Token expirado. Refrescando token...");

          final ok = await RefreshAccesTokenService.refresh();

          if (!ok) {
            print("❌ No se pudo refrescar el token");
            return false;
          }

          print("✅ Token actualizado. Reintentando petición...");

          continue;
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
    attempts++;

    if (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 2));
    }

    return false;
  }
}
