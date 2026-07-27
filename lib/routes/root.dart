import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:gixt_worker/Config/SignalRService.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/routes/BottomNavigationBar.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class RootPage extends StatefulWidget  {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> with WidgetsBindingObserver {
  int _backPressedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('Entro a la app ');
    switch (state) {
      case AppLifecycleState.resumed:
        // El usuario volvió a la app (otra app, bloqueo de pantalla, etc.)
        // sin que el widget se reconstruya: verificamos y reconectamos.
        SignalRService.setAppEnPrimerPlano(true);
        SignalRService.connectServer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // La app pasó a segundo plano: mantenemos la conexión abierta para
        // no perder notificaciones mientras el SO no la mate, pero evitamos
        // mostrar la pantalla de "sin conexión" mientras el usuario no la ve.
        SignalRService.setAppEnPrimerPlano(false);
        break;
      case AppLifecycleState.detached:
        // La app se está cerrando por completo: cerramos el hub de forma
        // ordenada (best-effort, el proceso puede terminar antes de que
        // esta llamada asíncrona complete).
        SignalRService.setAppEnPrimerPlano(false);
        SignalRService.hubConnection?.stop();
        break;
      case AppLifecycleState.hidden:
        SignalRService.setAppEnPrimerPlano(false);
        break;
    }
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _backPressedCount++;
        if (_backPressedCount == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presione nuevamente para salir', style: TextStyle(color: colorWhite),),
              backgroundColor: colorprimario,
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            setState(() {
              _backPressedCount = 0;
            });
          });
          return Future.value(false);
        } else {
          SystemNavigator.pop();
          return Future.value(true);
        }
      },
      child: KeyboardDismisser(
        child: Scaffold(
          backgroundColor: colorfondo,
          body: const AppBottomNavigation(index: 0,),
        ),
      ),
    );
  }
}
