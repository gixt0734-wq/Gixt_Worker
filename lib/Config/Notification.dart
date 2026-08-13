import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:gixt_worker/Components/alertExpress.dart';
import 'package:gixt_worker/Config/Notifiers/catalog_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/express_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/home_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/reports_notifiers.dart';
import 'package:gixt_worker/Config/vibration.dart';
import 'package:gixt_worker/main.dart';
import 'package:gixt_worker/services/Notification/ChatCacheService.dart';
import 'package:gixt_worker/services/Notification/Notification.dart';

final List<NotificationModel> _notificationModel = [];
final NotificationCacheService _cache = NotificationCacheService();

void handleNotification(
  BuildContext context,
  Map<String, dynamic> data,
  Map<String, dynamic>notification,
) {
  print("🔔 Notificación recibida:");
  print("Title: ${notification['title']}");
  print("Body: ${notification['body']}");
  print("Data: ${data}");

  VibrationService.vibrar();
  
    final botMsg = NotificationModel(
    id: 150,
    text: notification['title'],
    timestamp: DateTime.now(),
    type: '',
  );

  _notificationModel.add(botMsg);
  _cache.saveNotification(_notificationModel);

/// 🔥 TRABAJO EXPRESS
if (data['serviceType'] == 'express') {
  mostrarDialogNewjob(
    id: data['id'],
    type: 'express',
    title: "¡Nueva solicitud express!",
    img: data['img'],
    message:
        "${data['username']} necesita ayuda urgente. Envía tu propuesta y sé de los primeros en responder.",
  );
  catalogNotifier.refresh();
}

/// 🔥 TRABAJO NORMAL
if (data['serviceType'] == 'job') {
  mostrarDialogNewjob(
    id: data['id'],
    type:'job',
    title: "¡Nuevo trabajo disponible!",
    img: data['img'],
    message:
        "${data['username']} está buscando un profesional. Envía tu propuesta y consigue este trabajo.",
  );
  catalogNotifier.refresh();
}


  if (data['type'] == 'Express') {
    expressNotifier.refresh();
        homeNotifier.refresh();
  }

  if (data['type'] == 'Job') {
    jobsStatusNotifier.refresh();
        homeNotifier.refresh();
  }

  if (data['type'] == 'cancelation_express') {
    cancelexpressNotifier.refresh();
        homeNotifier.refresh();
  }

    if (data['type'] == 'cancelation_job') {
    canceljobNotifier.refresh();
        homeNotifier.refresh();
  }
    if (data['type'] == 'Report')
  {
    reportsNotifier.refresh();
  }
}
