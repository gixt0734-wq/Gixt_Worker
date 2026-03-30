import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON

class ServiciosByCat {
  String service_id;
  String service_name;
  String first_name;
  String userImage;
  String category;
  double price;
  String image;
  int rating;
  String description;

  ServiciosByCat({
    required this.service_id,
    required this.service_name,
    required this.first_name,
    required this.userImage,
    required this.category,
    required this.price,
    required this.image,
    required this.rating,
    required this.description,
  });

  factory ServiciosByCat.fromJson(Map<String, dynamic> json) {
    return ServiciosByCat(
      service_id: json['service_id'],
      service_name: json['service_name'],
      first_name: json['first_name'],
      userImage: json['userImage'],
      category: json['category'],
      price: (json['labor_price'] as num).toDouble(),
      image: json['image'],
      rating: json['rating'],
      description: json['description'],
    );
  }

  @override
  String toString() {
    return 'Servicio(service_name: $service_name, category: $category, price: $price)';
  }
}

class ServiciosByCat_service {
  List<ServiciosByCat> servicios = []; // Lista de empresas
  bool isLoading = false;
  bool hasMore = true;
  set loading(bool loading) {}

  Future<bool> fetchServicioCatData(
    int id,
    int pageNumber, {
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

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
                '${dotenv.env['API_URL']}/api/Services/category/${id}?pageNumber=${pageNumber}',
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          final List<dynamic> data = jsonResponse['data'];
          print(pageNumber);
          servicios..addAll(
            data.map((item) => ServiciosByCat.fromJson(item)).toList(),
          );
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
