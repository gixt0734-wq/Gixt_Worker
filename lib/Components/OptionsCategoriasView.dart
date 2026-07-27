import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/components/CircleImage.dart';
import 'package:google_fonts/google_fonts.dart';

class OptionsCategoriasView extends StatelessWidget {
  final String name;
  final String img;


  const OptionsCategoriasView({
    super.key,
    required this.name,
    required this.img,

  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 10,
        height: 10,
        child:  AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,

        decoration: BoxDecoration(
          color:Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:Theme.of(context).colorScheme.surface.withOpacity(0.07),
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

          

            /// TEXT
            Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorsecundario,
                      borderRadius: BorderRadius.circular(10),
                    ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                  ),
                ),
           
          ],
        ),
        )
    );
  }
}