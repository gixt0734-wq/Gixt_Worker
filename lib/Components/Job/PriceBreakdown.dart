import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Components/Job/SectionCard.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/ExpressPage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/pages/ViewJobPage.dart';
import 'package:google_fonts/google_fonts.dart';

class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown({
    super.key,
    required this.labor,
    required this.diagnostic,
    required this.materials,
    required this.iva,
    required this.total,
  });

  final double labor;
  final double diagnostic;
  final double materials;
  final double iva;
  final double total;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return  SectionCard(
      title: 'Pago y método de pago',
      child: Column(
        children: [
          if(diagnostic != 0.0)
          _priceLine(context, 'Visita / diagnóstico ', diagnostic),
          if(diagnostic != 0.0)
          const SizedBox(height: 12),
          _priceLine(context, 'Mano de obra ', labor),
          const SizedBox(height: 12),
          if(materials != 0.0)
          _priceLine(context, 'Materiales', materials),
          if(materials != 0.0)
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 0.7,
            color: surface.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Total estimado',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: surface,
                  ),
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colorsecundario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildIvaNote(context),
        ],
      ),
    );
  }
  
   Widget _buildIvaNote(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 13,
          color: surface.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Los precios mostrados ya incluyen IVA (16%) y comisiones.',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              height: 1.3,
              color: surface.withValues(alpha: 0.45),
            ),
          ),
        ),
      ],
    );
  }

   Widget _priceLine( BuildContext context,String label, double value) {
    final surface = Theme.of(context).colorScheme.surface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: surface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: surface.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }



}
