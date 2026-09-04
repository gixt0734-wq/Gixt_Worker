import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gixt_worker/Config/LocalNotificationService.dart';
import 'package:gixt_worker/Config/Notification.dart';
import 'package:gixt_worker/Components/alert_bar.dart';
import 'package:gixt_worker/Pages/ErrorConnectionPage.dart';
import 'package:gixt_worker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';


class SignalRService {
  static HubConnection? hubConnection;

  // Monitor de conexion. NO se cancela nunca, salvo logout.
  static Timer? _monitorTimer;

  // true mientras un bucle de (re)conexion esta corriendo -> evita solapes
  static bool _conectando = false;

  // true cuando el usuario cerro sesion -> corta los bucles infinitos
  static bool _desconectadoManual = false;

  // App en primer plano
  static bool _appEnPrimerPlano = true;

  // Control de la pagina de error para poder quitarla al reconectar
  static bool _errorPageVisible = false;
  static Route<dynamic>? _errorRoute;

  // Cuando es true, NO se muestra la ErrorConnectionPage.
  // Se activa durante flujos que tumban el socket a proposito,
  // p.ej. el confirmSetupIntent/pago de Stripe (abre actividad nativa).
  static bool suppressErrorPage = false;

  // Numero de reintentos fallidos consecutivos antes de mostrar el error.
  static const int _maxIntentosAntesDeError = 3;

  static void setAppEnPrimerPlano(bool value) {
    _appEnPrimerPlano = value;

    // Si volvemos al primer plano y seguimos caidos, mostramos el mensaje
    if (value) {
      final state = hubConnection?.state;
      if (state == null ||
          state == HubConnectionState.Disconnected ||
          state == HubConnectionState.Reconnecting) {
        _mostrarErrorPage();
      }
    }
  }

  // ------------------- CONEXION -------------------

  /// Punto de entrada (login / arranque). Lanza el bucle de conexion.
  static Future<void> connectServer() async {
    _desconectadoManual = false;
    await _intentarConectarLoop();
  }

  /// Bucle infinito: intenta conectar hasta lograrlo.
  /// Reintenta en silencio; solo tras [_maxIntentosAntesDeError] fallos
  /// consecutivos muestra la ErrorConnectionPage.
  /// Al conectar -> la quita y arranca el monitor.
  static Future<void> _intentarConectarLoop() async {
    if (_conectando) return; // ya hay un bucle activo, no abrimos otro
    _conectando = true;

    final prefs = await SharedPreferences.getInstance();
    final String? id_user = prefs.getString('id');

    int intentos = 0; // fallos consecutivos

    while (true) {
      // El usuario cerro sesion -> salimos sin reconectar
      if (_desconectadoManual) {
        _conectando = false;
        return;
      }

      try {
        await _cerrarConexion();

        hubConnection = HubConnectionBuilder()
            .withUrl(
              "${dotenv.env['API_URL']}/notificationHub?userId=$id_user",
              options: HttpConnectionOptions(
                requestTimeout: 30000,
              ),
            )
            .build();

        _registrarHandlers();

        // 60s: si el server deja de responder, lo detecta relativamente rapido
        hubConnection!.serverTimeoutInMilliseconds = 60000;
        hubConnection!.keepAliveIntervalInMilliseconds = 15000;

        await hubConnection!.start();

        if (id_user != null) {
          await hubConnection!.invoke("JoinGroup", args: [id_user]);
        }

        print("✅ SignalR conectado");

        intentos = 0; // reinicio el contador al lograr conexion
        _ocultarErrorPage(); // reconecto -> quitamos el mensaje
        _startMonitor(); // vigila futuras caidas

        _conectando = false;
        return;
      } catch (e) {
        intentos++;
        print(
          "❌ Error conectando SignalR (intento $intentos/$_maxIntentosAntesDeError), reintento en 3s: $e",
        );

        // Solo mostramos el error tras N fallos consecutivos.
        // Asi un corte transitorio (p.ej. pago Stripe) se reconecta
        // sin molestar al usuario con la pantalla de error.
        if (intentos >= _maxIntentosAntesDeError) {
          _mostrarErrorPage();
        }

        await Future.delayed(const Duration(seconds: 3));
        // el while vuelve a intentar -> NUNCA se rinde
      }
    }
  }

  static void _registrarHandlers() {
    hubConnection!.on("ReceiveNotification", (arguments) async {
      print("📩 Datos crudos: $arguments");
      if (arguments == null || arguments.isEmpty) return;

      try {
        final Map<String, dynamic> jsonResponse =
            Map<String, dynamic>.from(arguments[0] as Map);

        final context = NavigationService.navigatorKey.currentContext;
        if (context == null) return;

        await LocalNotificationService.showNotification(
          title: jsonResponse['title']?.toString() ?? 'Notificación',
          body: jsonResponse['body']?.toString() ?? '',
        );

        handleNotification(context, jsonResponse['data'], jsonResponse);
      } catch (e) {
        print("❌ Error parsing notification: $e");
      }
    });

    // Se dispara al instante cuando la conexion se cae -> reconecta ya,
    // sin esperar los 2s del monitor. NO mostramos el error aqui: deja
    // que el bucle decida tras los reintentos.
    hubConnection!.onclose(({error}) async {
      print("🔌 SignalR onclose: $error");
      if (_desconectadoManual) return;
       await  _forzarReconectar();
    });
  }

  // ------------------- MONITOR -------------------

  /// Cada 2s revisa el estado. Si esta caido, dispara el bucle de reconexion.
  /// Este timer NO se cancela nunca (solo en logout).
  static void _startMonitor() {
    _monitorTimer?.cancel();

    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_conectando) return; // ya se esta reconectando
      if (_desconectadoManual) return;

      final state = hubConnection?.state;
      print("🔍 SignalR estado: $state");

      if (state == null ||
          state == HubConnectionState.Disconnected ||
          state == HubConnectionState.Reconnecting) {
        print("⚠️ SignalR caido, reconectando...");
        // No mostramos el error aqui: el bucle lo hara tras los reintentos.
         await _forzarReconectar();

      }
    });
  }

  // ------------------- PAGINA DE ERROR -------------------
  // Se deja comentado el flujo anterior (navegaba a ErrorConnectionPage).
  // No se elimina la pagina ni este codigo por si se necesita reactivar.
  //
  // static void _mostrarErrorPage() {
  //   if (suppressErrorPage) return; // flujo de pago u otro -> no navegar
  //   if (!_appEnPrimerPlano) return; // fuera de la app no molestamos
  //   if (_errorPageVisible) return; // ya esta mostrada, no duplicar
  //   final navigator = NavigationService.navigatorKey.currentState;
  //   if (navigator == null) return;
  //
  //   _errorPageVisible = true;
  //   _errorRoute = MaterialPageRoute(
  //     builder: (_) => const ErrorConnectionPage(),
  //   );
  //
  //   // push (no pushAndRemoveUntil) para que al quitarla el usuario
  //   // regrese exactamente a donde estaba.
  //   navigator.push(_errorRoute!);
  // }
  //
  // static void _ocultarErrorPage() {
  //   if (!_errorPageVisible) return;
  //
  //   final navigator = NavigationService.navigatorKey.currentState;
  //   if (navigator != null && _errorRoute != null) {
  //     navigator.removeRoute(_errorRoute!);
  //   }
  //
  //   _errorRoute = null;
  //   _errorPageVisible = false;
  // }

  // ------------------- ALERTA DE ERROR -------------------
  // Nuevo flujo: en vez de navegar a ErrorConnectionPage, solo se muestra
  // una alerta tipo banner (igual que en alert_bar.dart) sobre la pagina
  // actual, sin mover al usuario de donde esta.

  static void _mostrarErrorPage() {
    if (suppressErrorPage) return; // flujo de pago u otro -> no molestar
    if (!_appEnPrimerPlano) return; // fuera de la app no molestamos
    if (_errorPageVisible) return; // ya hay una alerta mostrandose

    // OJO: navigatorKey.currentContext es el contexto del propio
    // Navigator, y el Overlay vive por debajo de el -> Overlay.of(context)
    // no lo encuentra. Por eso se usa el OverlayState directamente.
    final overlay = NavigationService.navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _errorPageVisible = true;

    ViewAlertBarOverlay(
      overlay,
      title: "Sin conexión, reconectando...",
      isError: true,
    ).then((_) {
      _errorPageVisible = false;
    });
  }

  static void _ocultarErrorPage() {
    // Ya no hay una pagina que remover: la alerta se oculta sola.
    // Solo reseteamos el flag para permitir una nueva alerta si se
    // vuelve a caer la conexion.
    _errorPageVisible = false;
  }

  // ------------------- UTILES -------------------

  static Future<void> _cerrarConexion() async {
    if (hubConnection != null) {
      try {
        await hubConnection!.stop();
      } catch (_) {}
      try {
        hubConnection!.off("ReceiveNotification");
      } catch (_) {}
      hubConnection = null;
    }
  }

static Future<void> _forzarReconectar() async {
  if (_desconectadoManual) return;
  if (_conectando) return;

  print("🔄 Forzando reconexión de SignalR...");

  try {
    final oldConnection = hubConnection;

    // Quitamos la referencia inmediatamente.
    // Así ningún otro proceso seguirá usando esta conexión.
    hubConnection = null;

    // Intentamos cerrar la conexión vieja.
    if (oldConnection != null) {
      try {
        oldConnection.off("ReceiveNotification");
      } catch (_) {}

      try {
        await oldConnection.stop();
      } catch (e) {
        print("⚠️ Error cerrando conexión anterior: $e");
      }
    }
  } catch (e) {
    print("⚠️ Error limpiando conexión anterior: $e");
  }

  // Crear una conexión completamente nueva.
  await _intentarConectarLoop();
}
  /// Logout: corta bucles, monitor y conexion.
static Future<bool> disconnectServer() async {
  // IMPORTANTE:
  // Primero bloqueamos cualquier reconexión automática.
  _desconectadoManual = true;

  print("🔌 Iniciando desconexión de SignalR...");

  // Detener monitor inmediatamente
  _monitorTimer?.cancel();
  _monitorTimer = null;

  // Evitar nuevos intentos de conexión
  _conectando = false;

  // Ocultar pantalla de error
  try {
    _ocultarErrorPage();
  } catch (_) {}

  final connection = hubConnection;

  // Ya no existe conexión
  if (connection == null) {
    print("✅ SignalR ya estaba desconectado");
    return true;
  }

  try {
    final state = connection.state;

    print("🔍 Estado antes de desconectar: $state");

    // Quitar listeners primero
    try {
      connection.off("ReceiveNotification");
    } catch (e) {
      print("⚠️ Error quitando handler: $e");
    }

    // Si ya está desconectado, no hacemos nada
    if (state == HubConnectionState.Disconnected) {
      print("ℹ️ SignalR ya estaba en Disconnected");
      return true;
    }

    // Si ya se está desconectando,
    // NO volvemos a llamar stop().
    if (state == HubConnectionState.Disconnecting) {
      print("⏳ SignalR ya se estaba desconectando...");

      // Esperamos un máximo de 5 segundos
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));

        if (connection.state == HubConnectionState.Disconnected) {
          print("✅ SignalR terminó de desconectarse");
          return true;
        }
      }

      print("⚠️ SignalR no terminó de desconectarse, forzando limpieza");
      return true;
    }

    // Connected / Connecting / Reconnecting
    try {
      await connection.stop();
      print("✅ SignalR stop() completado");
    } catch (e) {
      print("⚠️ Error ejecutando stop(): $e");
    }

    return true;
  } catch (e) {
    print("⚠️ Error desconectando SignalR: $e");
    return true;
  } finally {
    // SIEMPRE limpiamos la referencia.
    hubConnection = null;

    // Nos aseguramos de que no haya reconexión automática.
    _desconectadoManual = true;
    _conectando = false;

    _monitorTimer?.cancel();
    _monitorTimer = null;

    print("🧹 SignalR limpiado");
  }
}

}