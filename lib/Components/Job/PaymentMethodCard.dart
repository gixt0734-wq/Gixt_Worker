import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/ExpressPage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/pages/ViewJobPage.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentMethod extends StatelessWidget {
  const PaymentMethod({
    super.key,
    required this.payment_method,
  });

  final  String payment_method;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final primary = Theme.of(context).colorScheme.primary;

    final isCash = payment_method == 'cash';
    return Container(
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 21),
      child: Row(
          children: [
            SizedBox(width: 15),
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color:isCash? const Color(0xFF16A46E) : colorsecundario,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                 isCash ? Icons.payments_outlined : Icons.credit_card_rounded,
                size: 25,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                     isCash ? 'Efectivo' : 'Tarjeta',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: surface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                     isCash  ? 'Se te pagará vía efectivo'
                      : 'Verás reflejadas tus ganancias en tu wallet',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                      color: surface.withOpacity(0.7),
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
