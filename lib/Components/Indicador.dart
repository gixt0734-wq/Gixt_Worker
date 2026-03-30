import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gixt_worker/config/colors.dart';

class Indicador extends StatefulWidget {
  const Indicador({super.key});

  @override
  State<Indicador> createState() => _IndicadorState();
}

class _IndicadorState extends State<Indicador>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final int dotCount = 8;
  final double radius = 18;
  final double dotSize = 6;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return SizedBox(
            width: radius * 2 + dotSize,
            height: radius * 2 + dotSize,
            child: Stack(
              children: List.generate(dotCount, (i) {
                final angle =
                    (2 * pi / dotCount) * i + (_controller.value * 2 * pi);

                return Positioned(
                  left: radius + radius * cos(angle),
                  top: radius + radius * sin(angle),
                  child: Opacity(
                    opacity: (i + 1) / dotCount,
                    child: Container(
                      width: dotSize,
                      height: dotSize,
                      decoration:  BoxDecoration(
                        color: colorsecundario,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
