import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  /// Obtener información completa del dispositivo
  static Future<Map<String, String?>> getDeviceData() async {
    String deviceId = '';
    String deviceName = '';
    String? tokenFcm;

    if (Platform.isAndroid) {
      final android = await _deviceInfo.androidInfo;
      deviceId = android.id;
      deviceName = "${android.brand} ${android.model}";
    } else if (Platform.isIOS) {
      final ios = await _deviceInfo.iosInfo;
      deviceId = ios.identifierForVendor ?? '';
      deviceName = ios.name ?? '';
    }

    // Permiso notificaciones
    await _firebaseMessaging.requestPermission();

    // Token FCM
    tokenFcm = await _firebaseMessaging.getToken();

    return {
      "deviceId": deviceId,
      "deviceName": deviceName,
      "tokenFcm": tokenFcm,
    };
  }
}
