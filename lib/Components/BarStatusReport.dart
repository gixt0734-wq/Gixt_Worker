import 'package:flutter/material.dart';
import 'package:gixt_worker/config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class BarstatusReport extends StatelessWidget {
  const BarstatusReport({super.key, required this.estadoReport});

  final String estadoReport;

  // Orden lineal de estados
  static const List<String> _steps = ['pending', 'in_review', 'resolved'];

  Color _colorForState(String state) {
    switch (state) {
      case 'pending':
        return Colors.purple;
      case 'dismissed':
      case 'canceled':
        return Colors.red;
      case 'in_review':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _iconForState(String state) {
    switch (state) {
      case 'pending':
        return Icons.schedule_outlined;
      case 'resolved':
        return Icons.check_outlined;
      case 'in_review':
        return Icons.autorenew;
      case 'dismissed':
      case 'canceled':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  String _labelForState(String state) {
    switch (state) {
      case 'pending':
        return 'Pendiente';
      case 'in_review':
        return 'En revision';
      case 'resolved':
        return 'Resuelto';
      case 'dismissed':
        return 'Rechazado';
      case 'canceled':
        return 'Cancelado';
      default:
        return state;
    }
  }

  // Índice del estado actual dentro de _steps
  int _currentIndex() {
    final s = estadoReport.toLowerCase();
    // going/arrived cuentan como in_progress en la barra
    final mapped = (s == 'canceled' || s == 'dismissed') ? 'dismissed' : s;
    final idx = _steps.indexOf(mapped);
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final current = estadoReport.toLowerCase();
    final activeColor = _colorForState(current);
    final currentIdx = _currentIndex();
    final bool isRejected = current == 'dismissed' || current == 'canceled';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 5),

        // Barra de progreso minimalista
        Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              final lineIdx = i ~/ 2;

              final filled = isRejected ? true : lineIdx < currentIdx;

              return Expanded(
                child: Container(
                  height: 5,
                  color: filled
                      ? activeColor.withOpacity(0.5)
                      : Theme.of(context).colorScheme.surface.withOpacity(0.12),
                ),
              );
            }

            final stepIdx = i ~/ 2;
            final stepState = _steps[stepIdx];

            final isActive = isRejected ? false : stepIdx == currentIdx;

            final isDone = isRejected ? true : stepIdx < currentIdx;

            return _stepDot(
              context,
              icon: isRejected ? Icons.close : _iconForState(stepState),
              isActive: isActive,
              isDone: isDone,
              activeColor: activeColor,
            );
          }),
        ),

        const SizedBox(height: 16),

        // Chip de estado — solo texto + punto de color, sin caja
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _labelForState(current),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: activeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepDot(
    BuildContext context, {
    required IconData icon,
    required bool isActive,
    required bool isDone,
    required Color activeColor,
  }) {
    if (isActive) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activeColor,
          border: Border.all(color: activeColor, width: 1.5),
        ),
        child: Icon(icon, size: 14, color: colorWhite),
      );
    }

    if (isDone) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, color: activeColor),
        child: Icon(Icons.check, size: 14, color: colorWhite),
      );
    }

    // Pendiente (no alcanzado)
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Icon(
        icon,
        size: 14,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
      ),
    );
  }
}
