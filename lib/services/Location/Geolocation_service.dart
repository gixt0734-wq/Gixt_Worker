import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Components/alert.dart';

class GeoLocationService {
  static Future<Position> obtenerUbicacion(BuildContext context) async {
    bool servicioHabilitado;
    LocationPermission permiso;

    // Verificar GPS
    servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      return Future.error('Activa el GPS');
    }

    while (true) {
      permiso = await Geolocator.checkPermission();

      // Si está denegado → pedir permiso
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.deniedForever) {
        bool irAConfiguracion =
            await mostrarAlerta(
              context,
              title: "Permiso requerido",
              message:
                  "La ubicación está desactivada permanentemente.\n¿Deseas ir a configuración?",
              type: alert_type.advertencia,
            ) ??
            false;

        if (irAConfiguracion) {
          await Geolocator.openAppSettings();

          // Esperar un poco y reintentar
          await Future.delayed(Duration(seconds: 2));
          continue;
        } else {
          return Future.error('Permiso requerido para continuar');
        }
      }

      // Si el usuario vuelve a negar
      if (permiso == LocationPermission.denied) {
        return Future.error('Permiso denegado');
      }

      // Si ya está permitido → salir del loop
      if (permiso == LocationPermission.whileInUse ||
          permiso == LocationPermission.always) {
        break;
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
