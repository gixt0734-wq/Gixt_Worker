import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Components/Job/SectionCard.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/ExpressPage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/pages/ViewJobPage.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.text,
    required this.icon
  });

  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorsecundario),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                height: 1.5,
                color: surface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
