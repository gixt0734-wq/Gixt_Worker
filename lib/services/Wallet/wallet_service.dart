import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/services/Auth/RefreshTokenAccess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON
import 'package:intl/intl.dart';

String formatDateTime(String? date) {
  if (date == null || date.isEmpty) return '';

  final parsed = DateTime.parse(date);

  return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
}


class WalletTransaction {
  String paymentMethod;
  double currentBalance;
  double previousBalance;
  double amount;
  String reason;
  String transactionType;
  String createdAt;

  WalletTransaction({
    required this.paymentMethod,
    required this.currentBalance,
    required this.previousBalance,
    required this.amount,
    required this.reason,
    required this.transactionType,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      paymentMethod: json['payment_method'] ?? '',
      currentBalance: (json['current_balance'] ?? 0).toDouble(),
      previousBalance: (json['previous_balance'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      createdAt: formatDateTime(json['created_at']),
    );
  }
}

class WorkerWallet {
  double balance;
  bool hasBalance;
  List<WalletTransaction> transactions;

  WorkerWallet({
    required this.balance,
    required this.hasBalance,
    required this.transactions,
  });

  factory WorkerWallet.fromJson(Map<String, dynamic> json) {
    return WorkerWallet(
      balance: (json['balance'] ?? 0).toDouble(),
      hasBalance: json['has_balance'] ?? false,
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((e) => WalletTransaction.fromJson(e))
          .toList(),
    );
  }
}

class WorkerWallet_service {
  static final WorkerWallet_service _instance =
      WorkerWallet_service._internal();
  factory WorkerWallet_service() => _instance;
  WorkerWallet_service._internal();
  List<WorkerWallet> workerWallet = []; // Lista de empresas
  bool isLoading = false;
  bool hasMore = true;

  set loading(bool loading) {}


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
              Uri.parse(
                '${dotenv.env['API_URL']}/api/Workers/wallet/${id_user}',
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          print(jsonResponse);
          workerWallet
            ..clear()
            ..add(WorkerWallet.fromJson(jsonResponse));

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
