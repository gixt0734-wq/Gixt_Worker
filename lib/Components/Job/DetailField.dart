import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/ExpressPage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/pages/ViewJobPage.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailField extends StatelessWidget {
  const DetailField({
    super.key,
    required this.label,
    required this.value,
  });

  final  String label;
  final  String value;
  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: surface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.5,
            color: surface.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
