import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:gixt_worker/Components/alertExpress.dart';
import 'package:gixt_worker/Config/Notifiers/express_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/reports_notifiers.dart';
import 'package:gixt_worker/main.dart';
import 'package:gixt_worker/services/Notification/ChatCacheService.dart';
import 'package:gixt_worker/services/Notification/Notification.dart';

final List<NotificationModel> _notificationModel = [];
final NotificationCacheService _cache = NotificationCacheService();

void handleNotification(
  BuildContext context,
  Map<String, dynamic> data,
  RemoteNotification? notification,
) {
  print("🔔 Notificación recibida:");
  print("Title: ${notification?.title}");
  print("Body: ${notification?.body}");
  print("Data: $data");

    final botMsg = NotificationModel(
    id: 150,
    text: notification?.title,
    timestamp: DateTime.now(),
    type: '',
  );

  _notificationModel.add(botMsg);
  _cache.saveNotification(_notificationModel);

  /// 🔥 EXPRESS
  if (data['serviceType'] == 'express') {
    mostrarDialogExpress(
      id: data['serviceId'],
      title: "${data['username']} necesita tu ayuda",
      img: data['img'],
      message: "¡Tienes un nuevo servicio express esperándote!",
    );
  }

  if (data['type'] == 'Express') {
    expressNotifier.refresh();
  }

  if (data['type'] == 'Job') {
    jobsStatusNotifier.refresh();
  }

  if (data['type'] == 'cancelation_express') {
    cancelexpressNotifier.refresh();
  }

    if (data['type'] == 'Report')
  {
    reportsNotifier.refresh();
  }
}
