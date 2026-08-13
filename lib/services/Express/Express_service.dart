import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON

class Express {
  // IDs
  String express_id;

  // client
  String client_first_name;
  String client_username;
  String client_image;

  String job_date;
  String job_time;
  String description;
  String problem;
  double price;
  String payment_method;
  bool is_active;
  String job_status;
  String maps_address;
  // images
  String image;

  Express({
    required this.express_id,
    required this.client_first_name,
    required this.client_username,
    required this.client_image,
    required this.job_date,
    required this.job_time,
    required this.description,
    required this.problem,
    required this.price,
    required this.payment_method,
    required this.is_active,
    required this.job_status,
    required this.image,
    required this.maps_address,
  });

  factory Express.fromJson(Map<String, dynamic> json) {
    return Express(
      express_id: json['express_id'] ?? '',

      // client
      client_first_name: json['client']?['first_name'] ?? '',
      client_username: json['client']?['username'] ?? '',
      client_image: json['client']?['image'] ?? '',
      // location

      // job
      job_date: json['job_date'] ?? '',
      job_time: json['job_time'] ?? '',
      description: json['description'] ?? '',
      problem: json['problem'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      payment_method: json['payment_method'] ?? '',
      is_active: json['is_active'] ?? false,
      job_status: json['job_status'] ?? '',
      maps_address: json['maps_address'] ?? '',
      image: json['image'],
    );
  }
}

class Express_service {
  List<Express> express = []; // Lista de empresas
  int pageNumber = 1;
  bool isLoading = false;
  bool hasMore = true;
  static const String _cacheKey = 'express_cache';
  static const String _cacheTimeKey = 'express_cache_time';

  set loading(bool loading) {}
  Future<void> updatedata() async {
    print("📦 actualizando express");
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
      express
        ..clear()
        ..addAll(jsonData.map((e) => Express.fromJson(e)));

      return true;
    }

    print("🚫 Cache inválido → API agenda");
    return await fetchFromApi();
  }

  Future<bool> fetchFromApi() async {
    print("fetch Job by id");

    final prefs = await SharedPreferences.getInstance();

    int attempts = 0;
    const int maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        isLoading = true;
        final token = prefs.getString('token');
        String? id_user = prefs.getString('id');
        final headers = {'Authorization': 'Bearer $token'};

        final response = await http
            .get(
              Uri.parse(
                '${dotenv.env['API_URL']}/api/Expresss/worker/${id_user}',
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          express
            ..clear()
            ..addAll(jsonResponse.map((e) => Express.fromJson(e)));
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
