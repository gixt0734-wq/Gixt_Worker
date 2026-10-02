import 'dart:async';

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

// ------------------- REFRESH DE ESTATUS -------------------
// El mismo cambio llega por SignalR y por Firebase casi al mismo tiempo.
// Se juntan en una sola recarga (debounce) y se repite una vez despues,
// por si el servidor aviso antes de guardar el cambio en la BD.

const Duration _debounce = Duration(milliseconds: 300);
const Duration _reintento = Duration(milliseconds: 1500);

final Set<String> _tiposPendientes = {};
final Set<String> _tiposReintento = {};
Timer? _debounceTimer;
Timer? _reintentoTimer;

void programarRefreshEstatus(String? type) {
  if (type == null || type.isEmpty) return;

  _tiposPendientes.add(type);
  _debounceTimer?.cancel();
  _debounceTimer = Timer(_debounce, () {
    final tipos = Set<String>.of(_tiposPendientes);
    _tiposPendientes.clear();
    _refrescarEstatus(tipos, reintento: false);

    // Las cancelaciones NO se reintentan: cierran la pagina y muestran toast.
    _tiposReintento.addAll(tipos.where((t) => !t.startsWith('cancelation')));
    if (_tiposReintento.isEmpty) return;

    _reintentoTimer?.cancel();
    _reintentoTimer = Timer(_reintento, () {
      final tiposR = Set<String>.of(_tiposReintento);
      _tiposReintento.clear();
      _refrescarEstatus(tiposR, reintento: true);
    });
  });
}

/// Recarga todo lo que muestra estatus. Se usa al (re)conectar SignalR,
/// para recuperar los eventos que se perdieron mientras estaba caido.
void refrescarTodoEstatus() {
  expressNotifier.refresh();
  jobsStatusNotifier.refresh();
  homeNotifier.refresh();
}

void _refrescarEstatus(Set<String> tipos, {required bool reintento}) {
  print("🔄 Refresh estatus ${reintento ? '(reintento)' : ''}: $tipos");
  for (final type in tipos) {
    try {
      switch (type) {
        case 'Express':
          expressNotifier.refresh();
          homeNotifier.refresh();
          break;
        case 'Job':
          jobsStatusNotifier.refresh();
          homeNotifier.refresh();
          break;
        case 'cancelation_express':
          cancelexpressNotifier.refresh();
          homeNotifier.refresh();
          break;
        case 'cancelation_job':
          canceljobNotifier.refresh();
          homeNotifier.refresh();
          break;
        case 'Report':
          reportsNotifier.refresh();
          break;
      }
    } catch (e) {
      print("❌ Error refrescando estatus ($type): $e");
    }
  }
}

void handleNotification(
  BuildContext context,
  Map<String, dynamic> data,
  Map<String, dynamic>notification,
) {
  print("🔔 Notificación recibida:");
  print("Title: ${notification['title']}");
  print("Body: ${notification['body']}");
  print("Data: ${data}");

  // Primero el estatus: si algo de abajo falla, esto ya quedo programado.
  programarRefreshEstatus(data['type']?.toString());

  try {
    VibrationService.vibrar();

    final botMsg = NotificationModel(
      id: 150,
      text: notification['title'],
      timestamp: DateTime.now(),
      type: '',
    );

    _notificationModel.add(botMsg);
    _cache.saveNotification(_notificationModel);
  } catch (e) {
    print("❌ Error guardando notificación: $e");
  }

  try {
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
  } catch (e) {
    print("❌ Error mostrando nuevo trabajo: $e");
  }
}
