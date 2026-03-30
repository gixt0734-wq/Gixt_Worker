import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:shimmer/shimmer.dart';

class LocationsOptionsSkeleton extends StatelessWidget {
  const LocationsOptionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorprimario,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Circle icon skeleton
            Container(
              height: 60,
              width: 60,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Street
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 8),

                  // Neighborhood + state + city
                  Container(
                    height: 14,
                    width: MediaQuery.of(context).size.width * 0.6,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 8),

                  // References
                  Container(
                    height: 14,
                    width: MediaQuery.of(context).size.width * 0.4,
                    color: Colors.white24,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

          ],
        ),
      ).animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms)
        .fade(begin: 0.4, end: 1);
    
  }
}
