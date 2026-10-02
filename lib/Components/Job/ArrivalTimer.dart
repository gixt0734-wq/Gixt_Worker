import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ArrivalTimer extends StatelessWidget {
  const ArrivalTimer({
    super.key,
    required this.timeRemaining,
    this.expiresAt,
    required this.times,
  });

  /// Tiempo restante para llegar.
  final Duration timeRemaining;

  /// Tiempo máximo permitido para llegar, en minutos.
  /// Ejemplo: tiempo de Google Maps + 30 minutos.
  final int times;

  /// Hora exacta en la que se cancela automáticamente.
  ///
  /// Si no mandas este valor, se calcula con:
  /// DateTime.now() + timeRemaining
  final DateTime? expiresAt;

  String _formatArrival(Duration duration) {
    final safeDuration =
        duration.isNegative ? Duration.zero : duration;

    final hours = safeDuration.inHours;
    final minutes = safeDuration.inMinutes.remainder(60);
    final seconds = safeDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // El límite ahora es dinámico.
    final Duration arrivalLimit = Duration(
      minutes: times,
    );

    final remaining =
        timeRemaining.isNegative
            ? Duration.zero
            : timeRemaining;

    // Evitamos división entre 0.
    final double progress;

    if (arrivalLimit.inSeconds <= 0) {
      progress = 0.0;
    } else {
      progress =
          (remaining.inSeconds / arrivalLimit.inSeconds)
              .clamp(0.0, 1.0)
              .toDouble();
    }

    final bool critical = remaining.inMinutes < 5;
    final bool warning =
        !critical && remaining.inMinutes < 15;

    final Color accent =
        critical
            ? colorError
            : warning
                ? Colors.orange
                : colorsecundario;

    final DateTime limitTime =
        expiresAt ??
        DateTime.now().add(remaining);

    final String hint =
        critical
            ? '¡Date prisa! Se cancelará al llegar a 0'
            : warning
                ? 'Queda poco tiempo'
                : 'Llega antes de las '
                    '${TimeOfDay.fromDateTime(
                      limitTime.toLocal(),
                    ).format(context)}';

    Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        14,
        12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child:
                          TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          end: progress,
                        ),
                        duration: const Duration(
                          milliseconds: 900,
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 4,
                            strokeCap:
                                StrokeCap.round,
                            backgroundColor:
                                accent.withValues(
                              alpha: 0.15,
                            ),
                            valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(
                              accent,
                            ),
                          );
                        },
                      ),
                    ),
                    Icon(
                      critical
                          ? Icons.warning_amber_rounded
                          : Icons
                              .delivery_dining_rounded,
                      size: 20,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TIEMPO PARA LLEGAR',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _formatArrival(remaining),
                  style: GoogleFonts.dmSans(
                    fontSize: 25,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color:
                        critical
                            ? accent
                            : theme.colorScheme.surface,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  hint,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.surface
                        .withValues(alpha: 0.62),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    card = card
        .animate()
        .fadeIn(
          duration: 350.ms,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.10,
          end: 0,
          duration: 350.ms,
        );

    if (critical) {
      card = card
          .animate(
            onPlay:
                (controller) =>
                    controller.repeat(reverse: true),
          )
          .scaleXY(
            begin: 1,
            end: 1.025,
            duration: 700.ms,
            curve: Curves.easeInOut,
          );
    }

    return card;
  }
}