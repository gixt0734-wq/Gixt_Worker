import 'dart:async';
import 'package:vibration/vibration.dart';

class VibrationService {
  static Timer? _timer;
  static bool _activo = false;

  static Future<void> vibrar() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
      await Future.delayed(const Duration(milliseconds: 300));
      Vibration.vibrate(duration: 200);
    }
  }
  
  // Activar vibración repetitiva
  static void activarVibracion() async {
    if (_activo) return;

    _activo = true;

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) async {
        if (!_activo) {
          timer.cancel();
          return;
        }

        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(
            duration: 500,
          );
        }
      },
    );
  }

  // Desactivar vibración
  static void desactivarVibracion() {
    _activo = false;

    _timer?.cancel();
    _timer = null;

    Vibration.cancel();
  }
}