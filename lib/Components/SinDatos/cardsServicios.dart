import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
class CardsSN extends StatelessWidget {
  const CardsSN({super.key, required this.img});
  final String img;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child:
          Container(
                height: 130,
                width: 360,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    img,
                    fit: BoxFit.cover, // 🔥 respeta tamaño sin zoom
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(
                begin: 0.3,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutQuart,
              ),
    );
  }
}
