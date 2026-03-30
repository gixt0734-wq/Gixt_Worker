import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


enum alert_type { exito, error, advertencia }

Future<bool?> mostrarAlerta(
  BuildContext context, {
  required String title,
  required String message,
  required alert_type type,
}) async {
  // Config por tipo
  IconData icon;
  Color color;

  switch (type) {
    case alert_type.exito:
      icon = Icons.check_circle_rounded;
      color = const Color(0xFF30C45E);
      break;
    case alert_type.error:
      icon = Icons.cancel_rounded;
      color = Colors.redAccent;
      break;
    case alert_type.advertencia:
      icon = Icons.warning_amber_rounded;
      color = Colors.orangeAccent;
      break;
  }

  final completer = Completer<bool?>();

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AlertBanner(
      title: title,
      message: message,
      icon: icon,
      color: color,
      type: type,
      onResult: (result) {
        if (!completer.isCompleted) completer.complete(result);
        entry.remove();
      },
    ),
  );

  Overlay.of(context).insert(entry);
  return completer.future;
}

// ── Widget del banner ──────────────────────────────────────────────────────

class _AlertBanner extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final alert_type type;
  final ValueChanged<bool?> onResult;

  const _AlertBanner({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.type,
    required this.onResult,
  });

  @override
  State<_AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<_AlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  Future<void> _dismiss(bool? result) async {
    await _controller.reverse();
    widget.onResult(result);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdvert = widget.type == alert_type.advertencia;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: widget.color.withOpacity(0.22),
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

                      // ── Header ──────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ícono con fondo tenue
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(widget.icon, color: widget.color, size: 22),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.surface,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.message,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // X para cerrar
                          GestureDetector(
                            onTap: () => _dismiss(true),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Botones ─────────────────────────────
                      Row(
                        children: [
                          if (isAdvert) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _dismiss(false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.surface.withOpacity(0.12),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _dismiss(true),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: widget.color.withOpacity(0.12),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: widget.color.withOpacity(0.3),
                                    width: 0.8,
                                  ),
                                ),
                              ),
                              child: Text(
                                isAdvert ? 'Continuar' : 'Entendido',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: widget.color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}