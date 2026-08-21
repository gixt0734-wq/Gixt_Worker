import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON

class Worker_Category {
  int id;
  String name;
  String image;

  Worker_Category({required this.id, required this.name, required this.image});

  factory Worker_Category.fromJson(Map<String, dynamic> json) {
    return Worker_Category(
      name: json['name'] ?? '',
      id: json['category_id'] ?? 0,
      image: (json['image_url'] ?? ''),
    );
  }
}
class Worker {
  String description;
  String city;
  double longitude;
  double latitude;
  int range_km;
  double km_cost;
  List<Worker_Category> listcatworker;
  Worker({
    required this.description,
    required this.longitude,
    required this.latitude,
    required this.km_cost,
    required this.range_km,
    required this.city,
    required this.listcatworker
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
   
      description: json['description'],
      km_cost: json['diagnostic_cost'],
      range_km: json['service_radius_km'],
      city: json['city'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      listcatworker: (json['categories'] as List<dynamic>? ?? [])
              .map((e) => Worker_Category.fromJson(e))
              .toList(),

    );
  }

  @override
  String toString() {
    return 'Empresa(nombre: $description, url_img: $city)';
  }
}

class Worker_service {
    static final Worker_service _instance = Worker_service._internal();
  factory Worker_service() => _instance;
  Worker_service._internal();
  List<Worker> worker = []; // Lista de empresas
  bool isLoading = false;
  bool hasMore = true;
  static const String _cacheKey = 'worker_cache';
  static const String _cacheTimeKey = 'worker_cache_time';

  set loading(bool loading) {}

  Future<void> updatedata() async {
    print("📦 actualizando user");
    await fetchFromApi();
  }

  Future<bool> fetchUserData() async {
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
      print("📦 Usando cache user");

      final Map<String, dynamic> jsonData = json.decode(cachedData);
      worker
        ..clear()
        ..add(Worker.fromJson(jsonData));

      return true;
    }

    print("🚫 Cache inválido → API user");
    return await fetchFromApi();
  }

  Future<bool> fetchFromApi() async {
    print("🌐 Llamando API user");
    final prefs = await SharedPreferences.getInstance();
    int attempts = 0;
    const int maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
      final token = prefs.getString('token');
      String? id_user = prefs.getString('id');
      final headers = {'Authorization': 'Bearer $token'};
      isLoading = true;

        final response = await http
            .get(
              Uri.parse('${dotenv.env['API_URL']}/api/Workers/info/${id_user}'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          print(jsonResponse);
          worker
            ..clear()
            ..add(Worker.fromJson(jsonResponse));

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
