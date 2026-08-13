import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/ExpressPage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/pages/ViewJobPage.dart';
import 'package:google_fonts/google_fonts.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel({
    super.key,
    required this.label,
  });

  final  String label;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Row(
      children: [
        // Container(
        //   width: 3,
        //   height: 18,
        //   decoration: BoxDecoration(
        //     color: colorsecundario,
        //     borderRadius: BorderRadius.circular(2),
        //   ),
        // ),
        // const SizedBox(width: 10),
        // Expanded(
        //   child: Text(
        //     label,
        //     style: GoogleFonts.poppins(
        //       fontSize: 16,
        //       fontWeight: FontWeight.w600,
        //       color: Theme.of(context).colorScheme.surface,
        //       letterSpacing: -0.2,
        //     ),
        //   ),
        // ),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
      ],
    );
  }
}
