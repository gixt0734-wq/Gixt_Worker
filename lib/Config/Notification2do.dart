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

void handleNotification2do(
  BuildContext context,
  Map<String, dynamic> data,
) {
  print("🔔 Notificación recibida por firebase:");
  print("Data: ${data}");




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
