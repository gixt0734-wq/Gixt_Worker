import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON

class Catalog {
  String job_id;
  String type;
  String category;
  // worker
  String client_user_id;
  String client_first_name;
  String client_username;
  String client_image;

  // location
  String maps_address;

  String image_url;

  // job
  String job_date;
  String job_time;
  String description;
  String problem;

  bool is_active;
  String job_status;
  double price;
  

  Catalog({
    required this.job_id,
    required this.type,
    required this.category,
    required this.client_user_id,
    required this.client_first_name,
    required this.client_username,
    required this.client_image,
    required this.maps_address,
    required this.image_url,
    required this.job_date,
    required this.job_time,
    required this.description,
    required this.problem,
    required this.is_active,
    required this.job_status,
    required this.price,

  });

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      job_id: json['id'] ?? '',
      type :json['type'] ?? '',
      category : json['category' ]?? '',
      client_user_id: json['client']?['user_id'] ?? '',
      client_first_name: json['client']?['first_name'] ?? '',
      client_username: json['client']?['username'] ?? '',
      client_image: json['client']?['image'] ?? '',

      maps_address: json['location']?['maps_address'] ?? '',


      job_date: json['job_date'] ?? '',
      job_time: json['job_time'] ?? '',
      description: json['description'] ?? '',
      problem: json['problem'] ?? '',
      image_url : json['image_url'] ?? '',
      is_active: json['is_active'] ?? false,
      job_status: json['job_status'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
     
    );
  }
}

class Catalog_service {
  List<Catalog> catalog = []; // Lista de empresas
  int pageNumber = 1;
  bool isLoading = false;
  bool hasMore = true;

  set loading(bool loading) {}


  Future<bool> fetchFromApi() async {
    print("🌐 Llamando API agenda");
    final prefs = await SharedPreferences.getInstance();
    int attempts = 0;
    const int maxAttempts = 2;

    while (attempts < maxAttempts) {
      try {
      
      final token = prefs.getString('token');
      String? id_user = prefs.getString('id');
      final headers = {'Authorization': 'Bearer $token'};
        isLoading = true;

        final response = await http
            .get(Uri.parse('${dotenv.env['API_URL']}/api/Jobs?iduser=${id_user}&latitude=2&longitude=2'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          catalog
            ..clear()
            ..addAll(jsonResponse.map((e) => Catalog.fromJson(e)));


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
        print(" Error HTTP: ${response.statusCode}");
        return false;
      } on TimeoutException {
        print(" Timeout de la API");
        return false;
      } on SocketException {
        print(" Sin conexión a internet");
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
