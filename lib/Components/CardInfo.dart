import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CardInfo extends StatelessWidget {
  final String title;
  final String description;
  final int? paso;
  final int? total;
  final ValueChanged<int> onSelected;

  const CardInfo({
    super.key,
    required this.title,
    required this.description,
    required this.onSelected,
    this.paso,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 330,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          Hero(
            tag: 'logo',
            child: Image.asset(
              'assets/chamb_ia.png',
              width: 62,
              height: 62,
              fit: BoxFit.contain,
            ),
          )
              .animate()
              .fadeIn(
                duration: 350.ms,
                curve: Curves.easeOut,
              )
              .scale(
                begin: const Offset(.8, .8),
                end: const Offset(1, 1),
                duration: 450.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 12),

          // Título
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: colorWhite,
            ),
          )
              .animate()
              .fadeIn(
                delay: 80.ms,
                duration: 300.ms,
              )
              .slideY(
                begin: .15,
                end: 0,
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 7),

          // Descripción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w400,
                color: colorWhite.withValues(alpha: .82),
              ),
            ),
          )
              .animate()
              .fadeIn(
                delay: 140.ms,
                duration: 350.ms,
              )
              .slideY(
                begin: .10,
                end: 0,
                curve: Curves.easeOut,
              ),

          if (paso != null && total != null) ...[
            const SizedBox(height: 15),

            _puntitos()
                .animate()
                .fadeIn(
                  delay: 200.ms,
                  duration: 300.ms,
                )
                .scale(
                  begin: const Offset(.9, .9),
                  end: const Offset(1, 1),
                ),
          ],

          const SizedBox(height: 16),

          _botonSiguiente()
              .animate()
              .fadeIn(
                delay: 230.ms,
                duration: 350.ms,
              )
              .slideY(
                begin: .15,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
        )
        .slideY(
          begin: .08,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _botonSiguiente() {
    final esUltimo =
        paso != null &&
        total != null &&
        paso! >= total!;

    return SizedBox(
      width: 145,
      height: 42,
      child: FilledButton(
        onPressed: () {
          onSelected((paso ?? 0) + 1);
        },
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: colorsecundario,
          foregroundColor: colorWhite,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              esUltimo ? 'Entendido' : 'Siguiente',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 6),

            Icon(
              esUltimo
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  Widget _puntitos() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= total!; i++) ...[
          AnimatedContainer(
            duration: const Duration(
              milliseconds: 300,
            ),
            curve: Curves.easeOutCubic,
            width: i == paso ? 17 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == paso
                  ? colorsecundario
                  : colorWhite.withValues(
                      alpha: .20,
                    ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          if (i != total)
            const SizedBox(width: 5),
        ],
      ],
    );
  }
}