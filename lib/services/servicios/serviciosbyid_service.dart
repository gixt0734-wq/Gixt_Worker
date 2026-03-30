import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON

class Servicios {
  String service_name;
  String service_id;
  String worker_name;
  String worker_img;
  int worker_rating;
  String category;
  double price;
  String image;
  int rating;
  String description;
  String des_trabajador;
  bool favorite;
  List<String> images;

  Servicios({
    required this.service_name,
    required this.service_id,
    required this.worker_name,
    required this.worker_img,
    required this.worker_rating,
    required this.category,
    required this.price,
    required this.image,
    required this.rating,
    required this.description,
    required this.images,
    required this.des_trabajador,
    required this.favorite,
  });

  factory Servicios.fromJson(Map<String, dynamic> json) {
    final workerJson = json['worker'];

    return Servicios(
      service_id: json['service_id'] ?? '',
      service_name: json['service_name'] ?? '',
      category: json['category'] ?? '',
      price: (json['labor_price'] as num?)?.toDouble() ?? 0.0,
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      rating: json['rating'] ?? 0,
      favorite: json['favorite'] ?? false,

      // Datos del worker
      worker_name: workerJson != null ? workerJson['username'] ?? '' : '',
      worker_img: workerJson != null ? workerJson['image'] ?? '' : '',
      worker_rating: workerJson != null ? workerJson['rating'] ?? 0 : 0,
      des_trabajador: workerJson != null ? workerJson['description'] ?? '' : '',

      images: List<String>.from(json['images'] ?? []),
    );
  }
}

class ServiciosById_service {
  List<Servicios> servicios = []; // Lista de empresas
  int pageNumber = 1;
  bool isLoading = false;
  bool hasMore = true;

  set loading(bool loading) {}

  Future<bool> fetchServicioData(String id, {bool forceRefresh = false}) async {
    print("fetch servicios by id");

    final prefs = await SharedPreferences.getInstance();
    String? id_user = prefs.getString('id');
    final token = prefs.getString('token');

    final headers = {'Authorization': 'Bearer $token'};
    int attempts = 0;
    const int maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        isLoading = true;

        final response = await http
            .get(
              Uri.parse(
                '${dotenv.env['API_URL']}/api/Services/id/$id?userId=$id_user',
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          servicios
            ..clear()
            ..add(Servicios.fromJson(jsonResponse));
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
    attempts++;

    if (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 2));
    }

    return false;
  }
}
