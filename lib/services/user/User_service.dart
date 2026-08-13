import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON

class User {
  String user_id;
  String username;
  String first_name;
  String last_name;
  String phone;
  String image_url;
  String email;
  String birth_date;
  String gender;
  int workers;
  int services;
  bool is_working;
  double balance;
  bool has_balance;
  
  User({
    required this.user_id,
    required this.username,
    required this.image_url,
    required this.first_name,
    required this.last_name,
    required this.phone,
    required this.email,
    required this.birth_date,
    required this.gender,
    required this.workers,
    required this.services,
    required this.is_working,
    required this.balance,
    required this.has_balance,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      user_id: json['user_id'],
      username: json['username'],
      image_url: json['imagen'],
      first_name: json['first_name'],
      last_name: json['last_name'],
      phone: json['phone'],
      email: json['email'],
      birth_date: json['birth_date'],
      gender: json['gender'],
      balance: json['balance'],
      has_balance: json['has_balance'],
      workers: json['workers']?? 0,
      services: json['services'] ?? 0,
      is_working:json['is_working']??0
    );
  }

  @override
  String toString() {
    return 'Empresa(nombre: $username, url_img: $image_url)';
  }
}

class User_service {
  static final User_service _instance = User_service._internal();
  factory User_service() => _instance;
  User_service._internal();
  List<User> user = []; // Lista de usuarios
  bool isLoading = false;
  bool hasMore = true;
  static const String _cacheKey = 'user_cache';
  static const String _cacheTimeKey = 'user_cache_time';

  set loading(bool loading) {}

  Future<void> updatedata() async {
    print("📦 actualizando user");
    await fetchFromApi();
  }

  Future<bool> fetchUserData() async {
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
      print("📦 Usando cache user");

      final Map<String, dynamic> jsonData = json.decode(cachedData);
      user
        ..clear()
        ..add(User.fromJson(jsonData));

      return true;
    }

    print("🚫 Cache inválido → API user");
    return await fetchFromApi();
  }

  Future<bool> fetchFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    int attempts = 0;
    const int maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        isLoading = true;
        

        final token = prefs.getString('token');
        String? id_user = prefs.getString('id');
        print('🌐 Llamando API user $token');
        final headers = {'Authorization': 'Bearer $token'};
        print(token);

        final response = await http
            .get(
              Uri.parse('${dotenv.env['API_URL']}/api/Workers/id/${id_user}'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          print(jsonResponse);
          user
            ..clear()
            ..add(User.fromJson(jsonResponse));

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
