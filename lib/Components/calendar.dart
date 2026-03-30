import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  final DateTime _today = DateTime.now();
  String _dayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  String _monthAbbr(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  // Genera 5 días centrados en hoy
  List<DateTime> get _calendarDays {
    return List.generate(5, (i) => _today.add(Duration(days: i - 2)));
  }

  @override
  Widget build(BuildContext context) {
    final days = _calendarDays;
    return Container(
      margin: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((day) {
          final isToday =
              day.day == _today.day &&
              day.month == _today.month &&
              day.year == _today.year;
          return _buildDayCell(day, isToday);
        }).toList(),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildDayCell(DateTime day, bool isToday) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isToday ? colorsecundario : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _monthAbbr(day.month),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isToday
                  ? Colors.white.withOpacity(0.85)
                  : Theme.of(context).colorScheme.surface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${day.day}',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isToday
                  ? Colors.white
                  : Theme.of(context).colorScheme.surface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _dayName(day.weekday),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isToday
                  ? Colors.white.withOpacity(0.85)
                  : Theme.of(context).colorScheme.surface.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}
