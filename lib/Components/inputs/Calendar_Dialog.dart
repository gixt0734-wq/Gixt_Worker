import 'package:flutter/material.dart';
import 'package:gixt_worker/config/colors.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

Future<void> showCalendarDialog({
  required BuildContext context,
  required TextEditingController controller,
  required DateTime focusedDay,
  required Function(DateTime) onDateSelected,
}) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      DateTime selectedDay = focusedDay;
      CalendarFormat calendarFormat = CalendarFormat.month;

      return AlertDialog(
        backgroundColor: colorcuartario,
        
        content: SizedBox(
          width: 300,
          height: 400,
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.utc(2030, 12, 30),
            focusedDay: focusedDay,
            calendarFormat: calendarFormat,
            // selectedDayPredicate: (day) {
            //   return apidate.date
            //       .map((dateObj) => DateTime.parse(dateObj.fecha)) // Convierte el String a DateTime
            //       .any((date) => isSameDay(date, day)); // Compara si alguna fecha coincide con 'day'// Verifica si alguna fecha coincide con 'day'

            // },

            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: colorsecundario,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFFFFBABA),
                shape: BoxShape.circle,
              ),
            ),

            onDaySelected: (day, focused) {
              controller.text =
                  DateFormat('yyyy-MM-dd').format(day);

              onDateSelected(day);
              Navigator.pop(context);
            },
          ),
        ),
      );
    },
  );
}
