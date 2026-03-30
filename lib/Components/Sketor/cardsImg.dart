import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';

class CardsImgSkeleton extends StatelessWidget {
  const CardsImgSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
  return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: SizedBox(
        width:250,
        child: Card(
          elevation: 1,
          color: colorprimario,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
           margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: colorprimario,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft:   Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),
            ]
          ),
        ),
      ),
    )
        // 🔥 Skeleton animation
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms)
        .fade(begin: 0.4, end: 1);
  }
}
