import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:google_fonts/google_fonts.dart';

class OptionsButton extends StatelessWidget {
  const OptionsButton({
    super.key,
    required this.seleccionado,
    required this.motivo,
    required this.action,
  });


  final String motivo;
  final bool seleccionado;

  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap:action,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: seleccionado
                                    ? colorsecundario
                                    : surface.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: seleccionado
                                      ? colorsecundario
                                      : surface.withValues(alpha: 0.12),
                                  width: seleccionado ? 1.6 : 0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      motivo,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: seleccionado
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: seleccionado
                                            ? colorWhite
                                            : surface.withValues(alpha: 0.8),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  // 👇 Indicador tipo radio
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: seleccionado
                                          ? colorWhite
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: seleccionado
                                            ? colorWhite
                                            : surface.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: seleccionado
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: colorsecundario,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
  }
}
