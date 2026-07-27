import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/components/CircleImage.dart';
import 'package:google_fonts/google_fonts.dart';

class OptionsCategorias extends StatelessWidget {
  final String nombre;
  final int id;
  final String img;
  final bool isSelected;
  final ValueChanged<int> onSelected;

  const OptionsCategorias({
    super.key,
    required this.nombre,
    required this.id,
    required this.img,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,

        decoration: BoxDecoration(
          color: isSelected
              ? colorsecundario.withOpacity(0.12)
              : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorsecundario
                : Theme.of(context).colorScheme.surface.withOpacity(0.07),
            width: isSelected ? 1.8 : 1,
          ),
        ),

        child: Stack(
          fit: StackFit.expand,
          children: [
            /// IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: img,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 100),

                placeholder: (context, url) => Container(
                  color: Colors.black12,
                ),

                errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image),
              ),
            ),

            // /// DARK OVERLAY (mejora legibilidad)
            // Container(
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(14),
            //     gradient: LinearGradient(
            //       begin: Alignment.topCenter,
            //       end: Alignment.bottomCenter,
            //       colors: [
            //         Colors.transparent,
            //         Colors.black.withOpacity(0.55),
            //       ],
            //     ),
            //   ),
            // ),

            /// TEXT
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Text(
                nombre,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:  Theme.of(context).colorScheme.surface,
                ),
              ),
            ),

            /// CHECK INDICATOR
            if (isSelected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check_circle,
                  color: colorsecundario,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}