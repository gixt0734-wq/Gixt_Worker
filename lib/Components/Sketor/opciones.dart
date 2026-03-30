import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';

class OptionsSkeleton extends StatelessWidget {
  const OptionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: SizedBox(
        width: 150,
        height: 180,
        child: Card(
          color: colorprimario,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          
            
          ),
        )
      )
    )
    .animate(onPlay: (c) => c.repeat())
    .shimmer(
      duration: 1200.ms, 
      color: Colors.white.withOpacity(0.5),
    )
    .fade(duration: 800.ms, begin: 0.4, end: 0.8);
  }
}