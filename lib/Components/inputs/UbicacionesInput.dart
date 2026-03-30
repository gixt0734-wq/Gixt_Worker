import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gixt_worker/config/colors.dart';

class UbicacionesInput extends StatelessWidget {
  final String calle;
  final String colonia;
  final String estado;
  final String ciudad;
  final String descripcion;
  final String id;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const UbicacionesInput({
    super.key,
    required this.calle,
    required this.colonia,
    required this.estado,
    required this.ciudad,
    required this.descripcion,
    required this.id,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = id == selectedId;
    return InkWell(
      onTap: () => onSelected(id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
           color: isSelected
              ? colorsecundario.withOpacity(0.08)
              : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorsecundario
                : Theme.of(context).colorScheme.surface.withOpacity(0.07),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: colorsecundario,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, size: 30, color: colorWhite),
            ),

            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.surface,
                      letterSpacing: -0.2,
                    ),
                  ),

                  Text(
                    '${colonia} ${estado} ${ciudad}',
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.6,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.45),
                    ),
                  ),
                  Text(
                    calle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.6,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),

            Radio<String>(
              value: id,
              groupValue: selectedId,
              fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return colorsecundario; // color cuando está seleccionado
                }
                return Theme.of(
                  context,
                ).colorScheme.surface; // color cuando NO está seleccionado
              }),
              onChanged: (value) {
                if (value != null) onSelected(value);
              },
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 300.ms).slideX(begin: -0.2);
  }
}
