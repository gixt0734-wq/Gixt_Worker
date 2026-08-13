import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Config/SignalRService.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/main.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RefreshAccesTokenService {
  static Future<bool> refresh() async {
    int attempts = 0;
    const int maxAttempts = 2;
    http.Response? response;
    final PreferencesService _preferencesService = PreferencesService();
    final prefs = await SharedPreferences.getInstance();
    String? refreshtoken = prefs.getString('refreshtoken');

    while (attempts < maxAttempts) {
      print('llamando a refresh');
      try {
        response = await http
            .post(
              Uri.parse(
                '${dotenv.env['API_URL']}/api/Auth/refresh-access-token',
              ),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'refreshToken': refreshtoken}),
            )
            .timeout(const Duration(seconds: 30));
        print('response token ${response.statusCode}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print(data);
          await _preferencesService.savePreferencesToken(data['token']);
          return true;
        }

        if (response.statusCode == 401) {
          await _logout();
          return false;
        }
        return false;
      } on TimeoutException {
        return false;
      } on SocketException {
        return false;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  static Future<void> _logout() async {
    print('🚪 Cerrando sesión...');
    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      bool ok = await SignalRService.disconnectServer();
      if (ok) {
        await prefs.clear();
        NavigationService.goToLogin();
      }
    });
  }
}
