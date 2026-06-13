import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gixt_worker/Components/CircleImage.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/main.dart';
import 'package:gixt_worker/pages/ExpressPage.dart';
import 'package:google_fonts/google_fonts.dart';

/// =======================
/// CONTROL GLOBAL ALERTAS
/// =======================

final List<_AlertaData> _alertas = [];
OverlayEntry? _overlayEntry;

/// 👇 Duración total antes del auto-cierre (usada por el timer y la barra)
const Duration _kDuracionAlerta = Duration(seconds: 30);

class _AlertaData {
  final String id;
  final String title;
  final String message;
  final String img;
  Timer? autoCloseTimer;
  // 👇 Momento en que se creó la alerta, para calcular el progreso de la barra
  final DateTime createdAt;
  _AlertaData({
    required this.id,
    required this.title,
    required this.message,
    required this.img,
  }) : createdAt = DateTime.now();
}

/// MOSTRAR ALERTA
Future<void> mostrarDialogExpress({
  required String id,
  required String title,
  required String message,
  required String img,
}) async {
  final overlayState = navigatorKey.currentState?.overlay;

  if (overlayState == null) return;

  // Evitamos duplicados
  if (_alertas.any((a) => a.id == id)) return;

  final alerta = _AlertaData(id: id, title: title, message: message, img: img);

  // Timer de auto-cierre
  alerta.autoCloseTimer = Timer(_kDuracionAlerta, () {
    _cerrarAlertaPorId(id);
  });

  _alertas.add(alerta);
  // Si ya existe overlay, solo actualizamos el widget
  if (_overlayEntry != null) {
    _AlertaExpressState.update();
    return;
  }

  _overlayEntry = OverlayEntry(builder: (context) => const AlertaExpress());

  overlayState.insert(_overlayEntry!);
}

void _cerrarAlertaPorId(String id) {
  final index = _alertas.indexWhere((a) => a.id == id);
  if (index == -1) return;

  _alertas[index].autoCloseTimer?.cancel();
  _alertas.removeAt(index);

  if (_alertas.isEmpty) {
    cerrarTodasAlertas();
  } else {
    _AlertaExpressState.update();
  }
}

/// CERRAR TODAS
void cerrarTodasAlertas() {
  for (final a in _alertas) {
    a.autoCloseTimer?.cancel(); // 👈 evita timers huérfanos
  }
  _alertas.clear();
  _overlayEntry?.remove();
  _overlayEntry = null;
  _AlertaExpressState.reset();
}

/// =======================
/// WIDGET ALERTAS
/// =======================

class AlertaExpress extends StatefulWidget {
  const AlertaExpress({super.key});

  @override
  State<AlertaExpress> createState() => _AlertaExpressState();
}

class _AlertaExpressState extends State<AlertaExpress>
    with SingleTickerProviderStateMixin {
  static _AlertaExpressState? _instance;

  // 👇 Ticker que repinta la barra ~60fps mientras haya alertas vivas
  Ticker? _ticker;

  @override
  void initState() {
    super.initState();
    _instance = this;
    _ticker = createTicker((_) {
      if (mounted && _alertas.isNotEmpty) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    if (_instance == this) _instance = null;
    super.dispose();
  }

  static void update() {
    _instance?.setState(() {});
  }

  static void reset() {
    _instance?.setState(() {});
  }

  void _cerrarAlerta(String id) {
    final index = _alertas.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alertas[index].autoCloseTimer?.cancel(); // 👈 cancela su timer
      _alertas.removeAt(index);
    }
    if (_alertas.isEmpty) {
      cerrarTodasAlertas();
    } else {
      setState(() {});
    }
  }

  /// 👇 Calcula el progreso restante (1.0 → lleno, 0.0 → se acabó)
  double _progresoRestante(_AlertaData alerta) {
    final transcurrido = DateTime.now().difference(alerta.createdAt);
    final restante =
        1.0 - (transcurrido.inMilliseconds / _kDuracionAlerta.inMilliseconds);
    return restante.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_alertas.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _alertas.map((alerta) {
                      final double progreso = _progresoRestante(alerta);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.22),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          // 👇 clip para que la barra respete el radio superior
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// ===== BARRA DE TIEMPO (30s) =====
                                LinearProgressIndicator(
                                  value: progreso,
                                  minHeight: 4,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.08),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    // Verde mientras hay tiempo, ámbar/rojo al final
                                    progreso > 0.5
                                        ? Colors.green
                                        : progreso > 0.2
                                            ? Colors.orange
                                            : Colors.red,
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    16,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      /// HEADER
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Circleimage(
                                            image_url: alerta.img,
                                            w: 50,
                                            h: 50,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  alerta.title,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.surface,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  alerta.message,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    height: 1.5,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surface
                                                        .withOpacity(0.55),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          /// CERRAR
                                          GestureDetector(
                                            onTap: () =>
                                                _cerrarAlerta(alerta.id),
                                            behavior:
                                                HitTestBehavior.translucent,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              child: Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      /// BOTONES
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                _cerrarAlerta(alerta.id);
                                              },
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: Text(
                                                'Cancelar',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                final expressId = alerta.id;
                                                cerrarTodasAlertas();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ExpressPage(
                                                      express_id: expressId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                elevation: 0,
                                                backgroundColor: Colors.green,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: Text(
                                                'Ver Detalles',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorWhite,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}