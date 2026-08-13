import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/ExpressPage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/pages/ViewJobPage.dart';
import 'package:google_fonts/google_fonts.dart';

class Extra extends StatelessWidget {
  const Extra({
    super.key,
    required this.name,
    required this.value,
  });

  final  String name;
  final  double value;
  @override
  Widget build(BuildContext context) {
  final surface = Theme.of(context).colorScheme.surface;
  // Muestra el valor sin ".0" innecesario (12.0 -> "12", 12.5 -> "12.5")
    final valueLabel = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();


    return   Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colorsecundario,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            Icons.tune_rounded,
            size: 16,
            color: colorWhite,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
               fontSize: 14,
            height: 1.5,
            color: surface.withValues(alpha: 0.85),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          valueLabel,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: surface,
          ),
        ),
      ],
    ),
  );
  }
}
