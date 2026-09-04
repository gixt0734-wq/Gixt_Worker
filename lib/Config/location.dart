import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@pragma('vm:entry-point')
class LocationService {

  /// Estado de conexión a nivel de app (isolate principal):
  /// idle -> connecting -> connected (o de vuelta a idle si falla/se detiene)
  static String _connectionState = 'idle';
  static Completer<void>? _pendingStart;
  static StreamSubscription? _statusSubscription;

  static void _listenStatusOnce() {
    _statusSubscription ??= FlutterBackgroundService().on("status").listen((
      event,
    ) {
      final state = event?["state"];

      if (state == "conectado" || state == "enviando ubicación") {
        _connectionState = 'connected';
        if (_pendingStart != null && !_pendingStart!.isCompleted) {
          _pendingStart!.complete();
        }
      } else if (state == "error" || state == "detenido") {
        _connectionState = 'idle';
        if (_pendingStart != null && !_pendingStart!.isCompleted) {
          _pendingStart!.complete();
        }
      }
    });
  }

  /// INITIALIZE
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Detener cualquier servicio que haya quedado activo de una sesión anterior
    if (await service.isRunning()) {
      service.invoke("stop");
      await Future.delayed(const Duration(milliseconds: 800));
    }

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'tracking_channel',
      'Tracking Service',
      description: 'Servicio de ubicación',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'tracking_channel',
        initialNotificationTitle: 'Tracking activo',
        initialNotificationContent: 'Enviando ubicación...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
        
      ),
    );
  }

  /// Callback de iOS cuando la app pasa a segundo plano.
  /// DEBE ser static (o top-level) para poder pasarse como tear-off
  /// dentro de un método estático; si no, no compila.
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    return true;
  }

  /// START (envía el id al servicio)
  static Future<void> start(String id) async {
    if (_connectionState == 'connected') {
      print("📡 Ya conectado, se ignora nueva solicitud de start");
      return;
    }

    if (_connectionState == 'connecting') {
      print("⏳ Ya hay una conexión en curso, esperando resultado...");
      await _pendingStart?.future;
      return;
    }

    _connectionState = 'connecting';
    _pendingStart = Completer<void>();
    _listenStatusOnce();

    final service = FlutterBackgroundService();

    await service.startService();
    await Future.delayed(const Duration(seconds: 8));

    service.invoke("setId", {"id": id});
  }

  /// STOP
  static Future<void> stop() async {
    _connectionState = 'idle';
    if (_pendingStart != null && !_pendingStart!.isCompleted) {
      _pendingStart!.complete();
    }
    FlutterBackgroundService().invoke("stop");
  }

  /// ================= BACKGROUND =================

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {

     bool isactive = false;
    DartPluginRegistrant.ensureInitialized();
    await dotenv.load(fileName: ".env");

    HubConnection? hubConnectionGps;
    StreamSubscription<Position>? positionStream;

    final String hubUrl = "${dotenv.env['API_URL']}/gpsHub";

    print("🚀 Servicio iniciado");

    String? userId;

    /// RECIBIR ID
    service.on("setId").listen((event) {
      userId = event?["id"];
      service.invoke("status", {"state": "conectado",  "id": userId,});
      print("🆔 ID recibido: $userId");
    });

    /// ================= SIGNALR =================

    Future<void> initSignalR() async {
      print("🆔");
      hubConnectionGps = HubConnectionBuilder()
          .withUrl(hubUrl)
          .withAutomaticReconnect(
            retryDelays: [
              0,
              2000,
              5000,
              10000,
              15000,
              30000,
              30000,
              30000, // ← reintenta indefinido
            ],
          )
          .build();

      // ← Estos dos son los más importantes
      hubConnectionGps!.serverTimeoutInMilliseconds = 60000;
      hubConnectionGps!.keepAliveIntervalInMilliseconds = 15000;

      hubConnectionGps!.onreconnecting(({Exception? error}) {
        print("🔄 SignalR GPS reconectando...");
        isactive = false;
        service.invoke("status", {"state": "reconectando",  "id": userId,}); // 👈
      });

      hubConnectionGps!.onreconnected(({String? connectionId}) {
        print("✅ SignalR GPS reconectado: $connectionId");
         isactive = false;
        service.invoke("status", {"state": "conectado",  "id": userId,}); // 👈
      });

      hubConnectionGps!.onclose(({Exception? error}) {
        print("❌ SignalR GPS desconectado");
         isactive = false;
        service.invoke("status", {"state": "error",  "id": userId,}); // 👈
      

      });

      try {
        await hubConnectionGps!.start();
        print("✅ SignalR GPS conectado (2do plano)");
         isactive = true;
        service.invoke("status", {"state": "conectado",  "id": userId,});
      } catch (e) {
        print("🚫 Error SignalR GPS : $e");
        await Future.delayed(const Duration(seconds: 5));
        FlutterBackgroundService().invoke("stop");
        service.invoke("status", {"state": "ubicando",  "id": userId,});
      }
    }

    /// ================= GPS =================

    Future<void> startTracking() async {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        print("❌ GPS apagado");

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        print("❌ Permiso GPS bloqueado");

        return;
      }

      positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 0,
            ),
          ).listen((position) async {
            try {
              if (hubConnectionGps?.state == HubConnectionState.Connected &&
                  userId != null) {
                await hubConnectionGps!.send(
                  "SendLocation",
                  args: [userId!, position.latitude, position.longitude],
                );
                service.invoke("status", {"state": "enviando ubicación" ,  "id": userId});
                print(
                  "📍 Ubicación enviada: $userId ${position.latitude}, ${position.longitude}",
                );
              }
            } catch (e) {
              FlutterBackgroundService().invoke("stop");
              print("❌ Error enviando ubicación: $e");
            }
          });

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Tracking activo GPS",
          content: "Enviando ubicación en tiempo real...",
        );
      }
    }

    
    Future<void> start() async {
          FlutterBackgroundService().invoke("stop");
         await startTracking();

    }

    /// ================= INICIO =================

    await initSignalR();

    await start();

    /// ================= STOP EVENT =================


    service.on("stop").listen((event) {
      print("🛑 Servicio detenido");
      positionStream?.cancel();
      hubConnectionGps?.stop();
      service.invoke("status", {"state": "detenido"});
      service.stopSelf();
    });
  }

  
}
