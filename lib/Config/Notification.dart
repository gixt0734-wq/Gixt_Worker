import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:gixt_worker/Components/alertExpress.dart';
import 'package:gixt_worker/Config/Notifiers/express_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/main.dart';

void handleNotification(
  BuildContext context,
  Map<String, dynamic> data,
  RemoteNotification? notification,
) {
  print("🔔 Notificación recibida:");
  print("Title: ${notification?.title}");
  print("Body: ${notification?.body}");
  print("Data: $data");

  /// 🔥 EXPRESS
  if (data['serviceType'] == 'express') {
    mostrarDialogExpress(
      id: data['serviceId'],
      title: "Nuevo Servicio ${data['serviceId']}",
      message: "Tienes un nuevo pedido",
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
}

