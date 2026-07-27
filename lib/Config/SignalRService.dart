import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/Config/LocalNotificationService.dart';
import 'package:gixt_worker/Config/Notification.dart';
import 'package:gixt_worker/Pages/ErrorConnectionPage.dart';
import 'package:gixt_worker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

class SignalRService {
  static HubConnection? hubConnection;

  // Numero maximo de reintentos antes de mostrar la ErrorConnectionPage
  // (lo tenias en 2 para pruebas, ajustalo aqui)
  static const int _maxIntentos = 1;

  // Monitor de conexion
  static Timer? _monitorTimer;
  static bool _reconectando = false;

  // Indica si la app esta en primer plano (resumed). Si el usuario salio
  // de la app (paused/inactive/detached), no mostramos la ErrorConnectionPage
  // aunque la reconexion falle; seguimos reintentando en segundo plano.
  static bool _appEnPrimerPlano = true;

  static void setAppEnPrimerPlano(bool value) {
    _appEnPrimerPlano = value;
  }

  static Future<bool> connectServer() async {
    final prefs = await SharedPreferences.getInstance();
    String? id_user = prefs.getString('id');

    int intentos = 0;

    while (intentos < _maxIntentos) {
      try {
        // Cerrar conexion anterior si existe para no dejar fugas
        if (hubConnection != null) {
          try {
            await hubConnection!.stop();
          } catch (_) {}
          hubConnection = null;
        }

        // Sin withAutomaticReconnect(): el monitor de abajo se encarga
        // de reconectar, asi no hay hueco de 40s esperando a la libreria
        hubConnection = HubConnectionBuilder()
            .withUrl(
              "${dotenv.env['API_URL']}/notificationHub?userId=$id_user",
              options: HttpConnectionOptions(
                requestTimeout: 30000,
              ),
            )
            .build();

        hubConnection!.on("ReceiveNotification", (arguments) async {
          print("📩 Datos crudos: $arguments");

          if (arguments == null || arguments.isEmpty) return;

          try {
            final Map<String, dynamic> jsonResponse =
                Map<String, dynamic>.from(arguments[0] as Map);

            final context = navigatorKey.currentContext;
            if (context == null) return;

            await LocalNotificationService.showNotification(
              title: jsonResponse['title']?.toString() ?? 'Notificación',
              body: jsonResponse['body']?.toString() ?? '',
            );

            handleNotification(
              context,
              jsonResponse['data'],
              jsonResponse,
            );
          } catch (e) {
            print("❌ Error parsing notification: $e");
          }
        });

        hubConnection!.serverTimeoutInMilliseconds = 600000;
        hubConnection!.keepAliveIntervalInMilliseconds = 15000;

        await hubConnection!.start();

        if (id_user != null) {
          await hubConnection!.invoke(
            "JoinGroup",
            args: [id_user],
          );
        }

        print("✅ SignalR conectado");

        // Inicia el chequeo de conexion cada 2 segundos
        _startMonitor();

        return true;
      } catch (e) {
        intentos++;
        print(
          "❌ Error conectando SignalR (intento $intentos): $e",
        );

        await Future.delayed(
          const Duration(seconds: 3),
        );
      }
    }

    // Se acabaron los intentos -> mostrar pagina de error
    _mostrarErrorPage();
    return false;
  }

  /// Revisa cada 2 segundos el estado de la conexion.
  /// Si quedo en Disconnected, corre el while de reintentos.
  /// Si tambien falla, connectServer() muestra la ErrorConnectionPage.
  static void _startMonitor() {
    _monitorTimer?.cancel();

    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      // Evita correr dos reconexiones al mismo tiempo
      if (_reconectando) return;

      final state = hubConnection?.state;
      print("🔍 SignalR estado: $state");

      if (state == null || state == HubConnectionState.Disconnected||
        state == HubConnectionState.Reconnecting) {
        print("⚠️ SignalR desconectado, corriendo reintentos...");

        _reconectando = true;
        final ok = await connectServer();
        _reconectando = false;

        if (!ok) {
          // Ya se mostro la ErrorConnectionPage, paramos el monitor
          _monitorTimer?.cancel();
          _monitorTimer = null;
        }
      }
    });
  }

  static void _mostrarErrorPage() {
    // Si el usuario ya no esta en la app, no tiene sentido navegar a la
    // pantalla de error: solo confundiria al volver.
    if (!_appEnPrimerPlano) return;

    final context = navigatorKey.currentContext;

    if (context != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const ErrorConnectionPage(),
        ),
        (route) => false,
      );
    }
  }

  static Future<bool> disconnectServer() async {
    try {
      // Paramos el monitor para que no intente reconectar
      _monitorTimer?.cancel();
      _monitorTimer = null;
      _reconectando = false;

      if (hubConnection != null) {
        await hubConnection!.stop();
        hubConnection!.off("ReceiveNotification");
        hubConnection = null;

        print("🔌 SignalR desconectado correctamente");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error al desconectar SignalR: $e");
      return false;
    }
  }
}