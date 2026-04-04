import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Barstatus extends StatelessWidget {
  const Barstatus({super.key, required this.estadoTrabajo});

  final String estadoTrabajo;

  // Orden lineal de estados
  static const List<String> _steps = [
    'pending',
    'accepted',
    'in_progress',
    'finalized',
    'completed',
  ];

  Color _colorForState(String state) {
    switch (state) {
      case 'pending':   return Colors.purple;
      case 'accepted':  return Colors.blue;
      case 'going':
      case 'arrived':
      case 'in_progress': return Colors.orange;
      case 'finalized': return Colors.red;
      case 'completed': return Colors.green;
      case 'canceled':  return Colors.red;
      default:          return Colors.grey;
    }
  }

  IconData _iconForState(String state) {
    switch (state) {
      case 'pending':     return Icons.schedule_outlined;
      case 'accepted':    return Icons.check_outlined;
      case 'in_progress': return Icons.autorenew;
      case 'finalized':   return Icons.price_check_outlined;
      case 'completed':   return Icons.check_circle_outline;
      case 'canceled':    return Icons.cancel_outlined;
      default:            return Icons.circle_outlined;
    }
  }

  String _labelForState(String state) {
    switch (state) {
      case 'pending':     return 'Pendiente';
      case 'accepted':    return 'Aceptado';
      case 'going':       return 'En camino';
      case 'arrived':     return 'En domicilio';
      case 'in_progress': return 'En proceso';
      case 'finalized':   return 'Por finalizar';
      case 'completed':   return 'Completado';
      case 'canceled':    return 'Cancelado';
      default:            return state;
    }
  }

  // Índice del estado actual dentro de _steps
  int _currentIndex() {
    final s = estadoTrabajo.toLowerCase();
    // going/arrived cuentan como in_progress en la barra
    final mapped = (s == 'going' || s == 'arrived') ? 'in_progress' : s;
    final idx = _steps.indexOf(mapped);
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final current = estadoTrabajo.toLowerCase();
    final isCanceled = current == 'canceled';
    final activeColor = _colorForState(current);
    final currentIdx = _currentIndex();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          'Estado del trabajo',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 20),

        // Barra de progreso minimalista
        if (!isCanceled)
          Row(
            children: List.generate(_steps.length * 2 - 1, (i) {
              // Índices pares → círculo, impares → línea
              if (i.isOdd) {
                final lineIdx = i ~/ 2;
                final filled = lineIdx < currentIdx;
                return Expanded(
                  child: Container(
                    height: 1.5,
                    color: filled
                        ? activeColor.withOpacity(0.5)
                        : Theme.of(context).colorScheme.surface.withOpacity(0.12),
                  ),
                );
              }

              final stepIdx = i ~/ 2;
              final stepState = _steps[stepIdx];
              final isActive = stepIdx == currentIdx;
              final isDone = stepIdx < currentIdx;

              return _stepDot(
                context,
                icon: _iconForState(stepState),
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
          color: activeColor.withOpacity(0.12),
          border: Border.all(color: activeColor, width: 1.5),
        ),
        child: Icon(icon, size: 14, color: activeColor),
      );
    }

    if (isDone) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activeColor.withOpacity(0.08),
        ),
        child: Icon(Icons.check, size: 14, color: activeColor.withOpacity(0.6)),
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