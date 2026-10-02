import 'package:flutter/material.dart';
import 'package:gixt_worker/Config/Notification.dart';

void handleNotification2do(
  BuildContext context,
  Map<String, dynamic> data,
) {
  print("🔔 Notificación recibida por firebase:");
  print("Data: ${data}");

  // Mismo debounce que SignalR: si llegan los dos, se recarga una sola vez.
  programarRefreshEstatus(data['type']?.toString());
}
