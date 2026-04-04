import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/components/CircleImage.dart';
import 'package:google_fonts/google_fonts.dart';

class OptionsCategorias extends StatelessWidget {
  final String nombre;
  final int id;
  final String img;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  const OptionsCategorias({
    super.key,
    required this.nombre,
    required this.id,
    required this.img,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = id == selectedId;

    return GestureDetector(
      onTap: () => onSelected(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorsecundario.withOpacity(0.08)
              : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorsecundario
                : Theme.of(context).colorScheme.surface.withOpacity(0.07),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar con anillo si está seleccionado
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSelected ? 2 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: colorsecundario, width: 2)
                    : null,
              ),
              child: Circleimage(w: 55, h: 55, image_url: img),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Text(
                nombre,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorsecundario
                      : Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ),
              ),
            ),

            // Indicador minimalista en lugar del Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colorsecundario : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? colorsecundario
                      : Theme.of(context).colorScheme.surface.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: colorWhite)
                  : null,
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 300.ms).slideX(begin: -0.15);
  }
}