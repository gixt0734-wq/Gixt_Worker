import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@pragma('vm:entry-point')
class LocationService {
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
      iosConfiguration: IosConfiguration(),
    );
  }

  /// START (envía el id al servicio)
  static Future<void> start(String id) async {
    final service = FlutterBackgroundService();

    await service.startService();
    await Future.delayed(const Duration(seconds: 8));

    service.invoke("setId", {"id": id});
  }

  /// STOP
  static Future<void> stop() async {
    FlutterBackgroundService().invoke("stop");
  }

  /// ================= BACKGROUND =================

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
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

      print("🆔 ID recibido: $userId");
    });

    /// ================= SIGNALR =================

   Future<void> initSignalR() async {
    print("🆔");
  hubConnectionGps = HubConnectionBuilder()
      .withUrl(hubUrl)
      .withAutomaticReconnect(retryDelays: [
        0, 2000, 5000, 10000, 15000, 30000, 30000, 30000, // ← reintenta indefinido
      ])
      .build();

  // ← Estos dos son los más importantes
  hubConnectionGps!.serverTimeoutInMilliseconds = 60000;
  hubConnectionGps!.keepAliveIntervalInMilliseconds = 15000;

hubConnectionGps!.onreconnecting(({Exception? error}) {
  print("🔄 SignalR GPS reconectando...");
  service.invoke("status", {"state": "reconectando"});   // 👈
});

hubConnectionGps!.onreconnected(({String? connectionId}) {
  print("✅ SignalR GPS reconectado: $connectionId");
  service.invoke("status", {"state": "conectado"});      // 👈
});

hubConnectionGps!.onclose(({Exception? error}) {
  print("❌ SignalR GPS desconectado");
  service.invoke("status", {"state": "error"});          // 👈
});


  try {
    await hubConnectionGps!.start();
    print("✅ SignalR GPS conectado (2do plano)");
     service.invoke("status", {"state": "conectado"});
     
  } catch (e) {
    print("🚫 Error SignalR GPS : $e");
    await Future.delayed(const Duration(seconds: 5));
    FlutterBackgroundService().invoke("stop");
    service.invoke("status", {"state": "ubicando"});  
  }
}

Future<void> _reconnectManual() async {
  await Future.delayed(const Duration(seconds: 5));
  try {
    await hubConnectionGps!.start();
    print("✅ Reconectado GPS manual");
  } catch (e) {
    print("🚫 Fallo reconexión  GPS manual: $e");
    await _reconnectManual();
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
              distanceFilter: 1,
            ),
          ).listen((position) async {
            try {
              if (hubConnectionGps?.state == HubConnectionState.Connected &&
                  userId != null) {
                await hubConnectionGps!.invoke(
                  "SendLocation",
                  args: [userId!, position.latitude, position.longitude],
                );
                service.invoke("status", {"state": "enviando ubicación"});
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

    /// ================= INICIO =================

    await initSignalR();

    await startTracking();

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

