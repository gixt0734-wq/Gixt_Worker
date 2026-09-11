import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/ExpressPage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/pages/ViewJobPage.dart';
import 'package:google_fonts/google_fonts.dart';

class CardsTransaction extends StatelessWidget {
  const CardsTransaction({
    super.key,
    required this.paymentMethod,
    required this.transactionType,
    required this.amount,
    required this.date,
    required this.currentBalance,
    required this.previousBalance,
    required this.reason,
  });

  final String paymentMethod;
  final double currentBalance;
  final double previousBalance;
  final double amount;
  final String reason;
  final String transactionType;
  final String date;

  /// Devuelve texto, ícono y color según el estado.
  ({String text, IconData icon, Color color, bool isPositive}) _getStatusData(String status) {
    switch (status.toLowerCase()) {
      case 'income':
        return (
          text: 'Ingreso',
          icon: Icons.moving_rounded,
          color: const Color.fromARGB(255, 30, 225, 82),
          isPositive: true,
        );
      case 'payment':
        return (
          text: 'Pago',
          icon: Icons.payment_rounded,
          color: const Color.fromARGB(255, 225, 30, 30),
          isPositive: false,
        );
      case 'debt':
        return (
          text: 'Cargo',
          icon: Icons.trending_down_outlined,
          color: const Color.fromARGB(255, 225, 30, 30),
          isPositive: false,
        );
     
      default:
        return (
          text: status,
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF1E6AE1),
          isPositive: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.surface;
    final status = _getStatusData(transactionType);
    final sign = status.isPositive ? '+' : '−';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(status.icon, color: status.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.9,
                      fontSize: 15,
                      color: onSurface,
                    ),
                  ),
                   if (reason.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: onSurface.withValues(alpha: 0.5),
                          height: 1.1,
                        ),
                      ),
                    ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                 '$sign\$${amount.abs().toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: status.color,
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}