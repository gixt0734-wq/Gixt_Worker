import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:gixt_worker/config/location.dart';

class GpsTrackingPage extends StatefulWidget {
  const GpsTrackingPage({super.key});

  @override
  State<GpsTrackingPage> createState() => _GpsTrackingPageState();
}

class _GpsTrackingPageState extends State<GpsTrackingPage> {

  bool _tracking = false;
  StreamSubscription? _statusSub;
  /// ================= START =================
  Future<void> _startTracking() async {

    if (!mounted) return;

    setState(() {
      _tracking = true;
    });

    await LocationService.start(
        '019cc48d-1e7a-7515-b273-bf607e66b588');
  }

  /// ================= STOP =================
  Future<void> _stopTracking() async {

    if (!mounted) return;

    setState(() {
      _tracking = false;
    });

    await LocationService.stop();
  }

  /// ================= DISPOSE =================
  @override
  void dispose() {
    // Solo detener servicio, sin setState
    LocationService.stop();
    super.dispose();
      _statusSub?.cancel(); 
  }
  @override
  void initState() {
    super.initState();

    // 👇 Aquí, no en dispose
    _statusSub = FlutterBackgroundService()
        .on("status")
        .listen((event) {
      final state = event?["state"];
      print("✅ Status recibido: $state");
      if (state != null && mounted) {
   
      }
    });
  }


  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GPS en tiempo real"),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _tracking ? _stopTracking : _startTracking,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 20,
            ),
          ),
          child: Text(
            _tracking ? "DETENER" : "EMPEZAR",
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}