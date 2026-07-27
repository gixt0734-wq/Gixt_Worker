import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Express/Express_proposal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON

class Express {
  // IDs
  String express_id;
  String client_id;
  String category;
  // client
  String client_first_name;
  String client_username;
  String client_image;

  String maps_address;
  double latitude;
  double longitude;

  // job
  String job_date;
  String job_time;
  String description;
  String problem;
  double price;
  String payment_method;
  bool is_active;
  String job_status;
  String payment_status;
  double worker_price;
  double diagnostic_cost;
  double labor_cost;
  double materials;
  List<String> images_evicence;
  List<Express_proposal> express_proposal;
  // images
  String? image;

  Express({
    required this.express_id,
    required this.client_id,
    required this.client_first_name,
    required this.client_username,
    required this.client_image,
    required this.category,
    required this.maps_address,
    required this.latitude,
    required this.longitude,
    required this.job_date,
    required this.job_time,
    required this.description,
    required this.problem,
    required this.price,
    required this.payment_method,
    required this.is_active,
    required this.job_status,
    required this.payment_status,
    required this.worker_price,
    required this.diagnostic_cost,
    required this.labor_cost,
    required this.materials,
    required this.images_evicence,
    this.image,
    required this.express_proposal,
  });

  factory Express.fromJson(Map<String, dynamic> json) {
    return Express(
      express_id: json['express_id'] ?? '',
      client_id: json['client_id'] ?? '',
      category: json['category'] ?? '',
      // client
      client_first_name: json['client']?['first_name'] ?? '',
      client_username: json['client']?['username'] ?? '',
      client_image: json['client']?['image'] ?? '',

      // location
      latitude: json['latitude'],
      longitude: json['longitude'],
      maps_address: json['maps_address'],
      worker_price : (json['worker'] ? ['diagnostic_cost']) ?? 0.0,

      diagnostic_cost : (json['payment'] ? ['diagnostic_cost']) ?? 0.0,
      payment_method: (json['payment'] ? ['payment_method']) ?? 0.0,
      labor_cost: (json['payment'] ? ['labor_cost']) ?? 0.0,
      materials: (json['payment'] ? ['materials']) ?? 0.0,
      // job
      job_date: json['job_date'] ?? '',
      job_time: json['job_time'] ?? '',
      description: json['description'] ?? '',
      problem: json['problem'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      is_active: json['is_active'] ?? false,
      job_status: json['job_status'] ?? '',
      payment_status: json['payment_status'] ?? '',
      images_evicence: List<String>.from(json['evidence'] ?? []),
      express_proposal: (json['proposal'] as List<dynamic>? ?? [])
        .map((e) => Express_proposal.fromJson(e))
        .toList(),
      image: json['image'],

    );
  }
}


class ExpressById_service {
  List<Express> express = []; // Lista de empresas
  int pageNumber = 1;
  bool isLoading = false;
  bool hasMore = true;

  set loading(bool loading) {}

  Future<bool> fetchServicioData(String id, {bool forceRefresh = false}) async {
    print("fetch Job by id");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    String? id_user = prefs.getString('id');
    print("id user: ${id_user}");
    final headers = {'Authorization': 'Bearer $token'};
    int attempts = 0;
    const int maxAttempts = 2;
    while (attempts < maxAttempts) {
      try {
        isLoading = true;

        final response = await http
            .get(
              Uri.parse('${dotenv.env['API_URL']}/api/Expresss/review/${id}?idworker=${id_user}'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
        print('response : ${response.statusCode}');
        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          express
            ..clear()
            ..add(Express.fromJson(jsonResponse));
          return true;
        }

        print(" Error HTTP: ${response.statusCode}");
        return false;
      } on TimeoutException {
        print("Timeout de la API");
        return false;
      } on SocketException {
        print("Sin conexión a internet");
        return false;
      } catch (e) {
        print(" Error inesperado: $e");
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
