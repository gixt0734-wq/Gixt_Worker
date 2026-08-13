import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/ExpressPage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/pages/ViewJobPage.dart';
import 'package:google_fonts/google_fonts.dart';

class Imagen extends StatelessWidget {
  const Imagen({
    super.key,
    required this.imagen,
    required this.type,
    required this.icon,
  });

  final String imagen;
  final String type;
  final IconData icon;

  void _showFullImage(String imageUrl, BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.pop(context), // cerrar al tocar
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return SizedBox(
      width: 132,
      height: 164,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          imagen == ''
              ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.07),
                      width: 1,
                    ),
                  ),
                  width: double.infinity,
                  height: double.infinity,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.3),
                    size: 52,
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    _showFullImage(imagen, context);
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CachedNetworkImage(
                            imageUrl: imagen!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Center(child: Indicador()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      // pill superior minimalista
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 11, color: colorWhite),
                              const SizedBox(width: 5),
                              Text(
                                type,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: colorWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
