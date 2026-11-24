import 'dart:async';
import 'dart:io';
import 'package:gixt_worker/services/Express/Job_extra.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:gixt_worker/services/Details/DetailsModel.dart';
import 'package:gixt_worker/services/Express/Express_Id_service.dart';
import 'package:gixt_worker/services/Job/jobs_proposal.dart';
import 'package:gixt_worker/services/Job/payment_model.dart';
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

class Job {
  // IDs
  String job_id;
  String client_id;
  String category;
  int type_category;
  bool is_blocked;

  // client
  String client_first_name;
  String client_username;
  String client_image;

  // location
  String maps_address;
  double latitude;
  double longitude;

  // job
  String job_date;
  String job_time;
  String description;
  String problem;
  double iva;
  double worker_price;
  String payment_method;
  bool is_active;
  String job_status;
  String payment_status;
  double diagnostic_cost;
  double materials;
  double total;
  double garantia;
  double tarifa;
  // images
  String? image;
  List<String> images_evicence;
  List<Jobs_proposal> jobs_proposal;
  List<DetailsModel> listdetails;
  List<PaymentModel> paymentdetails;
  List<Job_extra> extra;
  
  Job({
    required this.job_id,
    required this.client_id,
    required this.category,
    required this.is_blocked,
    required this.type_category,
    required this.client_first_name,
    required this.client_username,
    required this.client_image,
    required this.maps_address,
    required this.latitude,
    required this.longitude,
    required this.job_date,
    required this.job_time,
    required this.description,
    required this.problem,
    required this.diagnostic_cost,
    required this.iva,
    required this.materials,
    required this.total,
    required this.garantia,
    required this.tarifa,
    required this.worker_price,
    required this.payment_method,
    required this.is_active,
    required this.job_status,
    required this.payment_status,
    this.image,
    required this.images_evicence,
    required this.jobs_proposal,
    required this.listdetails,
    required this.extra,
    required this.paymentdetails,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    final location = json['location'] ?? {};
    final service = json['service'] ?? {};

    return Job(
      job_id: json['job_id'] ?? '',
      client_id: json['client_id'] ?? '',
      is_blocked : json['is_blocked'] ?? false,
      // client
      client_first_name: json['client']?['first_name'] ?? '',
      client_username: json['client']?['username'] ?? '',
      client_image: json['client']?['image'] ?? '',

      // location
      latitude: json['latitude'] ?? 0,
      longitude: json['longitude'] ?? 0,
      maps_address: json['maps_address'] ?? '',
      category: json['category']? ['name']?? '',
      type_category : json['category'] ? ['type_id'] ?? 0,

      // worker
      worker_price: (json['worker']?['diagnostic_cost']) ?? 0.0,

      // job
      job_date: formatDate( json['job_date'] ?? ''),
      job_time: formatTime( json['job_time'] ?? ''),
      description: json['description'] ?? '',
      problem: json['problem'] ?? '',
      diagnostic_cost: (json['payment']?['diagnostic_cost']) ?? 0.0,
      payment_method: (json['payment']?['payment_method']) ?? 0.0,
      iva: (json['payment']?['iva']) ?? 0.0,
      materials: (json['payment']?['materials']) ?? 0.0,
      garantia: (json['payment'] ? ['garantia_total']) ?? 0.0,
      tarifa: (json['payment'] ? ['tarifa_total']) ?? 0.0,
      total : (json['payment'] ? ['total']) ?? 0.0,
      is_active: json['is_active'] ?? false,
      job_status: json['job_status'] ?? '',
      payment_status: json['payment_status'] ?? '',
      image: json['image_url'],
      images_evicence: List<String>.from(json['evidence'] ?? []),
      jobs_proposal: (json['proposal'] as List<dynamic>? ?? [])
          .map((e) => Jobs_proposal.fromJson(e))
          .toList(),
      listdetails: (json['details'] as List<dynamic>? ?? [])
              .map((e) => DetailsModel.fromJson(e))
              .toList(),
      paymentdetails: (json['payment_det'] as List<dynamic>? ?? [])
              .map((e) => PaymentModel.fromJson(e))
              .toList(),
      extra: (json['extra'] as List<dynamic>? ?? [])
        .map((e) => Job_extra.fromJson(e))
        .toList(),
    );
  }
}

class JobById_service {
  List<Job> job = []; // Lista de empresas
  int pageNumber = 1;
  bool isLoading = false;
  bool hasMore = true;

  set loading(bool loading) {}

  Future<bool> fetchServicioData(String id, {bool forceRefresh = false}) async {
    print("fetch Job by id");

    final prefs = await SharedPreferences.getInstance();

    int attempts = 0;
    const int maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        final token = prefs.getString('token');
        final headers = {'Authorization': 'Bearer $token'};
        isLoading = true;

        final response = await http
            .get(
              Uri.parse(
                '${dotenv.env['API_URL']}/api/Jobs/worker/id/${id}',
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          print(jsonResponse);
          job
            ..clear()
            ..add(Job.fromJson(jsonResponse));
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
