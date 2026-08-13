import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/ExpressPage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/pages/ViewJobPage.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionsButton extends StatelessWidget {
  const ActionsButton({
    super.key,
    required this.title,
    required this.text,
    required this.icon,
    required this.action,
    required this.color,
    
  });

  final IconData icon;
  final String text;
  final String title;
  final Color color;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: action,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorWhite, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: surface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: surface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: surface.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
