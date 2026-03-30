import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gixt_worker/config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> selectTime({
  required BuildContext context,
  required TextEditingController controller,
}) async {
  
    await _selectTimeCupertino(context, controller);
  
}

// ── iOS ────────────────────────────────────────────────────────────────────

Future<void> _selectTimeCupertino(
  BuildContext context,
  TextEditingController controller,
) async {
  DateTime initial = DateTime.now().copyWith(hour: 8, minute: 0, second: 0);
  DateTime? selected;

  await showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemFill.resolveFrom(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                  Text(
                    'Hora del servicio',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      selected = initial;
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Aceptar',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorsecundario,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Picker
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initial,
                minuteInterval: 1,
                use24hFormat: false,
                onDateTimeChanged: (dt) => initial = dt,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (selected == null) return;
  _applyTime(context, controller, TimeOfDay.fromDateTime(selected!));
}

// ── Android ────────────────────────────────────────────────────────────────

Future<void> _selectTimeMaterial(
  BuildContext context,
  TextEditingController controller,
) async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: const TimeOfDay(hour: 8, minute: 0),
    helpText: 'Hora del servicio',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            hourMinuteTextColor: Theme.of(context).colorScheme.surface,
            hourMinuteColor: Theme.of(context).colorScheme.primary,
            dialHandColor: colorsecundario,
            dialBackgroundColor: Theme.of(context).colorScheme.primary,
            entryModeIconColor: Theme.of(context).colorScheme.surface.withOpacity(0.6),
            dayPeriodTextColor: Theme.of(context).colorScheme.surface,
            dayPeriodColor: MaterialStateColor.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? colorsecundario.withOpacity(0.15)
                  : Colors.transparent,
            ),
            helpTextStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
            ),
            dialTextColor: MaterialStateColor.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? colorWhite
                  : Theme.of(context).colorScheme.surface,
            ),
            hourMinuteShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            dayPeriodShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: colorsecundario,
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked == null) return;
  _applyTime(context, controller, picked);
}

// ── Validación compartida ──────────────────────────────────────────────────

void _applyTime(
  BuildContext context,
  TextEditingController controller,
  TimeOfDay picked,
) {
  if (picked.hour < 8 || picked.hour >= 22) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colorprimario,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Seleccione un horario entre 8:00 AM y 10:00 PM',
          style: GoogleFonts.poppins(fontSize: 13, color: colorWhite),
        ),
      ),
    );
    return;
  }

  // Formato 12h (AM/PM)
  final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
  final minute = picked.minute.toString().padLeft(2, '0');
  final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
  controller.text = '$hour:$minute $period';
}