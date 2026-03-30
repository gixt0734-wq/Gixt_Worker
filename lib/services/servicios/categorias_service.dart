import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON

class Categorias {
  String name;
  int category_id;
  String image_url;

  Categorias({
    required this.name,
    required this.category_id,
    required this.image_url,
  });

  factory Categorias.fromJson(Map<String, dynamic> json) {
    return Categorias(
      name: json['name'],
      image_url: json['image'],
      category_id: json['category_id'],
    );
  }

  @override
  String toString() {
    return 'Empresa(nombre: $name,)';
  }
}

class Categorias_service {
  List<Categorias> categorias = []; // Lista de empresas
  bool isLoading = false;
  bool hasMore = true;
  static const String _cacheKey = 'categorias_cache';
  static const String _cacheTimeKey = 'categorias_cache_time';

  set loading(bool loading) {}
  Future<void> updatedata() async {
    print("📦 actualizando categorias");
    await fetchFromApi();
  }

  Future<bool> fetchCategoriasData() async {
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
      print("📦 Usando cache categorias");

      final List<dynamic> jsonData = json.decode(cachedData);
      categorias
        ..clear()
        ..addAll(jsonData.map((e) => Categorias.fromJson(e)));

      return true;
    }

    print("🚫 Cache inválido → API categorias");
    return await fetchFromApi();
  }

  Future<bool> fetchFromApi() async {
    final prefs = await SharedPreferences.getInstance();

    print("🌐 Llamando API categorias");

    final token = prefs.getString('token');
    String? id = prefs.getString('id');

    final headers = {'Authorization': 'Bearer $token'};
    int attempts = 0;
    const int maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        isLoading = true;

        final response = await http
            .get(
              Uri.parse('${dotenv.env['API_URL']}/api/Categories'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(
            response.body,
          ); // Decodifica como una lista
          categorias.clear();
          categorias.addAll(
            jsonResponse.map((item) => Categorias.fromJson(item)).toList(),
          );
          categorias
            ..clear()
            ..addAll(jsonResponse.map((e) => Categorias.fromJson(e)));

          //  guardar cache
          await prefs.setString(_cacheKey, response.body);
          await prefs.setInt(
            _cacheTimeKey,
            DateTime.now().millisecondsSinceEpoch,
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
