import 'package:flutter/material.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/main.dart';
import 'package:gixt_worker/pages/ExpressPage.dart';
import 'package:google_fonts/google_fonts.dart';

/// =======================
/// CONTROL GLOBAL ALERTAS
/// =======================

final List<_AlertaData> _alertas = [];
OverlayEntry? _overlayEntry;

class _AlertaData {
  final String id;
  final String title;
  final String message;

  _AlertaData({required this.id, required this.title, required this.message});
}

/// MOSTRAR ALERTA
Future<void> mostrarDialogExpress({
  required String id,
  required String title,
  required String message,
}) async {
  final overlayState = navigatorKey.currentState?.overlay;

  if (overlayState == null) return;

  // Evitamos duplicados
  if (_alertas.any((a) => a.id == id)) return;

  _alertas.add(_AlertaData(id: id, title: title, message: message));

  // Si ya existe overlay, solo actualizamos el widget
  if (_overlayEntry != null) {
    _AlertaExpressState.update();
    return;
  }

  _overlayEntry = OverlayEntry(builder: (context) => const AlertaExpress());

  overlayState.insert(_overlayEntry!);
}

/// CERRAR TODAS
void cerrarTodasAlertas() {
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

class _AlertaExpressState extends State<AlertaExpress> {
  static _AlertaExpressState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
  }

  @override
  void dispose() {
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
    _alertas.removeWhere((a) => a.id == id);
    if (_alertas.isEmpty) {
      cerrarTodasAlertas();
    } else {
      setState(() {});
    }
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
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// HEADER
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.flash_on_rounded,
                                      color: Colors.green,
                                      size: 22,
                                    ),
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
                                    onTap: () => _cerrarAlerta(alerta.id),
                                    behavior: HitTestBehavior.translucent,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface.withOpacity(0.3),
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
                                        _alertas.removeWhere(
                                          (a) => a.id == alerta.id,
                                        );
                                        if (_alertas.isEmpty) {
                                          _overlayEntry?.remove();
                                          _overlayEntry = null;
                                        } else {
                                          update();
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                        cerrarTodasAlertas();
                                          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpressPage(express_id: alerta.id,),
              ),
            );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
