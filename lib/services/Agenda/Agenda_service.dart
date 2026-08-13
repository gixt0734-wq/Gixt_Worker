import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON

String formatDate(String? date) {
  if (date == null || date.isEmpty) return '';

  final parsed = DateTime.parse(date);

  return DateFormat('dd-MM-yyyy').format(parsed);
}

String formatTime(String? time) {
  if (time == null || time.isEmpty) return '';

  try {
    final parsed = DateFormat('HH:mm:ss').parse(time);
     return DateFormat('hh:mm a').format(parsed);
  } catch (_) {
    return '';
  }
}

class Agenda {
  String job_id;
  String type;
  // worker
  String client_user_id;
  String client_first_name;
  String client_username;
  String client_image;

  // location
  String maps_address;

  String image;

  // job
  String job_date;
  String job_time;
  String description;
  String problem;

  bool is_active;
  String job_status;
  double labor_cost;
  

  Agenda({
    required this.job_id,
    required this.type,
    required this.client_user_id,
    required this.client_first_name,
    required this.client_username,
    required this.client_image,
    required this.maps_address,
    required this.image,
    required this.job_date,
    required this.job_time,
    required this.description,
    required this.problem,
    required this.is_active,
    required this.job_status,
    required this.labor_cost,

  });

  factory Agenda.fromJson(Map<String, dynamic> json) {
    return Agenda(
    job_id: json['id'] ?? '',
      type :json['type'] ?? '',
      client_user_id: json['client']?['user_id'] ?? '',
      client_first_name: json['client']?['first_name'] ?? '',
      client_username: json['client']?['username'] ?? '',
      client_image: json['client']?['image'] ?? '',

      maps_address: json['location']?['maps_address'] ?? '',


      job_date: formatDate(json['job_date'] ?? ''),
      job_time: formatTime(json['job_time'] ?? ''),
      description: json['description'] ?? '',
      problem: json['problem'] ?? '',
      image : json['image_url'] ?? '',
      is_active: json['is_active'] ?? false,
      job_status: json['job_status'] ?? '',
      labor_cost: (json['price'] as num?)?.toDouble() ?? 0.0,
     
    );
  }
}

class Agenda_service {
  static final Agenda_service _instance = Agenda_service._internal();
  factory Agenda_service() => _instance;
  Agenda_service._internal();

  List<Agenda> agenda = []; // Lista de empresas
  int pageNumber = 1;
  bool isLoading = false;
  bool hasMore = true;
  static const String _cacheKey = 'agenda_cache';
  static const String _cacheTimeKey = 'agenda_cache_time';

  set loading(bool loading) {}

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
      agenda
        ..clear()
        ..addAll(jsonData.map((e) => Agenda.fromJson(e)));

      return true;
    }

    print("🚫 Cache inválido → API agenda");
    return await fetchFromApi(1);
  }

  Future<bool> fetchFromApi(int page) async {

    print("🌐 Llamando API agenda");
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
              Uri.parse('${dotenv.env['API_URL']}/api/Jobs/worker/$id_user'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);

          final List<dynamic> jsonResponse =
              decoded['data'] is List ? decoded['data'] as List<dynamic> : [];
          print(jsonResponse);

          if(page == 1)
          {
            print('guardando los primeros');
            agenda
            ..clear()
            ..addAll(jsonResponse.map((e) => Agenda.fromJson(e)));

            await prefs.setString(_cacheKey,  json.encode(jsonResponse),);
            await prefs.setInt(
              _cacheTimeKey,
              DateTime.now().millisecondsSinceEpoch,
            );
            
          }
          else
          {
             print('📦 Agregando página $page');

             agenda
            ..addAll(jsonResponse.map((e) => Agenda.fromJson(e)));
          }
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
