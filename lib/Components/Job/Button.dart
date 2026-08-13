import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/ExpressPage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/pages/ViewJobPage.dart';
import 'package:google_fonts/google_fonts.dart';

class Button extends StatelessWidget {
  const Button({
    super.key,
    required this.text,
    required this.icon,
    this.action,
    required this.bgColor,
  });

  final IconData icon;
  final String text;
  final Color bgColor;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return ElevatedButton(
      onPressed: action,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: surface.withValues(alpha: 0.12),
        disabledForegroundColor: surface.withValues(alpha: 0.4),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
