import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tarjeta de un trabajo extra: número, problema, precio, descripción e imagen.
class ExtraJobCard extends StatelessWidget {
  const ExtraJobCard({
    super.key,
    required this.index,
    required this.problem,
    required this.description,
    required this.price,
    this.imageUrl = '',
  });

  final int index;
  final String problem;
  final String description;
  final double price;
  final String imageUrl;



  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _badge(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        problem,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: surface,
                        ),
                      ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.5,
                          color: surface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ]
                )
              ),
            ]
          )
        ],
      
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08);
  }

  Widget _badge() {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colorsecundario,
        ),
      ),
    );
  }

 
 
}
