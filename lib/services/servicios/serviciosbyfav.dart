import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON

class ServiciosFav {
  String service_id;
  String service_name;
  String first_name;
  String userImage;
  String category;
  double price;
  String image;
  int rating;
  String description;

  ServiciosFav({
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

  factory ServiciosFav.fromJson(Map<String, dynamic> json) {
    return ServiciosFav(
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
}

class ServiciosFav_service {
  List<ServiciosFav> servicios = []; // Lista de empresas
  bool isLoading = false;
  bool hasMore = true;
  static const String _cacheKey = 'servicios_fav_cache';
  static const String _cacheTimeKey = 'servicios_fav_cache_time';
  set loading(bool loading) {}

  Future<void> updatedata() async {
    print("📦 actualizando servicios");
    await fetchFromApi();
  }

  Future<bool> fetchServicioData() async {
    final prefs = await SharedPreferences.getInstance();

    // config cache
    const cacheDuration = Duration(days: 1);

    // leer cache
    final cachedData = prefs.getString(_cacheKey);
    final cachedTime = prefs.getInt(_cacheTimeKey);

    final now = DateTime.now();

    //  validar cache
    if (cachedData != null &&
        cachedTime != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(cachedTime)) <
            cacheDuration) {
      print("📦 Usando cache favoritos");

      final List<dynamic> jsonData = json.decode(cachedData);
      servicios
        ..clear()
        ..addAll(jsonData.map((e) => ServiciosFav.fromJson(e)));

      return true;
    }

    print("🚫 Cache inválido → API Fav");
    return await fetchFromApi();
  }

  Future<bool> fetchFromApi() async {
    print("🌐 Llamando API fav");

    int attempts = 0;
    const int maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      String? id = prefs.getString('id');
      final headers = {'Authorization': 'Bearer $token'};
        isLoading = true;

        final response = await http
            .get(
              Uri.parse('${dotenv.env['API_URL']}/api/Favorites/id/$id'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          servicios
            ..clear()
            ..addAll(jsonResponse.map((e) => ServiciosFav.fromJson(e)));

          await prefs.setString(_cacheKey, response.body);
          await prefs.setInt(
            _cacheTimeKey,
            DateTime.now().millisecondsSinceEpoch,
          );
          return true;
        }

        if (response.statusCode == 401) {
          print("🔐 Token expirado. Refrescando token...");

          final ok = await RefreshAccesTokenService.refresh();

          if (!ok) {
            print("❌ No se pudo refrescar el token");
            return false;
          }
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
