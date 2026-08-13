import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON

class Jobs {
  String job_id;
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
  

  Jobs({
    required this.job_id,
    required this.client_user_id,
    required this.client_first_name,
    required this.client_username,
    required this.client_image,
    required this.maps_address,
    required this.image_url,
    required this.job_date,
    required this.job_time,
    required this.category,
    required this.description,
    required this.problem,
    required this.is_active,
    required this.job_status,
    required this.price,

  });

  factory Jobs.fromJson(Map<String, dynamic> json) {
    return Jobs(
      job_id: json['job_id'] ?? '',

      client_user_id: json['client']?['user_id'] ?? '',
      client_first_name: json['client']?['first_name'] ?? '',
      client_username: json['client']?['username'] ?? '',
      client_image: json['client']?['image'] ?? '',
    category: json['category'] ?? '',
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

class Jobs_service {
  List<Jobs> jobs = []; // Lista de empresas
  int pageNumber = 1;
  bool isLoading = false;
  bool hasMore = true;
  static const String _cacheKey = 'agenda_cache';
  static const String _cacheTimeKey = 'agenda_cache_time';

  set loading(bool loading) {}
  Future<void> updatedata() async {
    print("📦 actualizando agenda");
    await fetchFromApi();
  }

  Future<bool> fetchAgendaData() async {
    final prefs = await SharedPreferences.getInstance();

    // config cache
    const cacheDuration = Duration(seconds: 1);

    // leer cache
    final cachedData = prefs.getString(_cacheKey);
    final cachedTime = prefs.getInt(_cacheTimeKey);

    final now = DateTime.now();

    //  validar cache
    if (cachedData != null &&
        cachedTime != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(cachedTime)) <
            cacheDuration) {
      print("📦 Usando cache agenda");

      final List<dynamic> jsonData = json.decode(cachedData);
      jobs
        ..clear()
        ..addAll(jsonData.map((e) => Jobs.fromJson(e)));

      return true;
    }

    print("🚫 Cache inválido → API agenda");
    return await fetchFromApi();
  }

  Future<bool> fetchFromApi() async {
    print("🌐 Llamando API agenda");

    int attempts = 0;
    const int maxAttempts = 2;
    final prefs = await SharedPreferences.getInstance();

    while (attempts < maxAttempts) {
      try {
      
      final token = prefs.getString('token');
      String? id_user = prefs.getString('id');
      final headers = {'Authorization': 'Bearer $token'};
        isLoading = true;

        final response = await http
            .get(
              Uri.parse('${dotenv.env['API_URL']}/api/Jobs?iduser=${id_user}&latitude=2&longitude=2'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          jobs
            ..clear()
            ..addAll(jsonResponse.map((e) => Jobs.fromJson(e)));

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
