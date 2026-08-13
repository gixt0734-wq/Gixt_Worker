import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CardsTransactionSkeleton extends StatelessWidget {
  const CardsTransactionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.surface;
    final baseColor = onSurface.withValues(alpha: 0.08);

    Widget box({
      required double width,
      required double height,
      double radius = 8,
    }) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(22),
        
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Placeholder del ícono
              box(width: 48, height: 48, radius: 15),
              const SizedBox(width: 14),
              // Placeholder de texto y motivo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(width: 90, height: 14),
                    const SizedBox(height: 6),
                    box(width: 140, height: 11),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Placeholder de monto y fecha
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  box(width: 60, height: 15),
                  const SizedBox(height: 6),
                  box(width: 44, height: 10),
                ],
              ),
            ],
          ),
          // Divisor + fila de saldo
          const SizedBox(height: 12),
        
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color: onSurface.withValues(alpha: 0.12),
        );
  }
}