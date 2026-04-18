import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON

class Job {
  // IDs
  String job_id;
  String client_id;
  
  // client
  String client_first_name;
  String client_username;
  String client_image;

  // location
  String location_id;
  String street;
  String neighborhood;
  String house_number;
  String state;
  String maps_address;
  String reference;
  String location_image;
  double latitude;
  double longitude;

  // service
  String service_id;
  String service_name;
  String service_description;
  String service_image;

  // job
  String job_date;
  String job_time;
  String description;
  String problem;
  double labor_cost;
  double km_cost;
  String payment_method;
  bool is_active;
  String job_status;
  String payment_status;

  // images
  String? image_1;
  String? image_2;
  List<String> images_evicence;

  Job({
    required this.job_id,
    required this.client_id,
    required this.client_first_name,
    required this.client_username,
    required this.client_image,
    required this.location_id,
    required this.street,
    required this.neighborhood,
    required this.house_number,
    required this.state,
    required this.maps_address,
    required this.reference,
    required this.location_image,
    required this.latitude,
    required this.longitude,
    required this.service_id,
    required this.service_name,
    required this.service_description,
    required this.service_image,
    required this.job_date,
    required this.job_time,
    required this.description,
    required this.problem,
    required this.labor_cost,
    required this.km_cost,
    required this.payment_method,
    required this.is_active,
    required this.job_status,
    required this.payment_status,
    this.image_1,
    this.image_2,
    required this.images_evicence,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    final location = json['location'] ?? {};
    final service = json['service'] ?? {};

    return Job(
      job_id: json['job_id'] ?? '',
      client_id: json['client_id'] ?? '',

      // client
      client_first_name: json['client']?['first_name'] ?? '',
      client_username: json['client']?['username'] ?? '',
      client_image: json['client']?['image'] ?? '',
      // location
      location_id: location['location_id'] ?? '',
      street: location['street'] ?? '',
      neighborhood: location['neighborhood'] ?? '',
      house_number: location['house_number'] ?? '',
      state: location['state'] ?? '',
      latitude:  location['latitude'] ?? 0,
      longitude: location['longitude'] ??0 ,
      maps_address: location['maps_address'] ?? '',
      reference: location['reference'] ?? '',
      location_image: location['image'] ?? '',

      // service
      service_id: service['service_id'] ?? '',
      service_name: service['service_name'] ?? '',
      service_description: service['description'] ?? '',
      service_image: service['image'] ?? '',

      // job
      job_date: json['job_date'] ?? '',
      job_time: json['job_time'] ?? '',
      description: json['description'] ?? '',
      problem: json['problem'] ?? '',
      labor_cost: (json['payment']?['labor_cost']  as num?)?.toDouble() ?? 0.0,
      payment_method: json['payment']?['payment_method'] ?? '',
      km_cost: (json['payment']?['km_cost']  as num?)?.toDouble() ?? 0.0,
      is_active: json['is_active'] ?? false,
      job_status: json['job_status'] ?? '',
      payment_status: json['payment_status'] ?? '',

      image_1: json['image_1'],
      image_2: json['image_2'],
      images_evicence: List<String>.from(json['evidence'] ?? []),
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
    final token = prefs.getString('token');

    final headers = {'Authorization': 'Bearer $token'};

    try {
      isLoading = true;

      final response = await http
          .get(
            Uri.parse('${dotenv.env['API_URL']}/api/Jobs/worker/id/${id}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        job
          ..clear()
          ..add(Job.fromJson(jsonResponse));
        return true;
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
}
