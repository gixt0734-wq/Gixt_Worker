import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/Reports/InfoReportJobPage.dart';
import 'package:gixt_worker/Pages/Reports/InfoReportClientPage.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportsOptions extends StatelessWidget {
  final String description;
  final String reason;
  final String created_at;
  final String? type_job;
  final String type;
  final String status_report;
  final String report_id;

  const ReportsOptions({
    super.key,
    required this.description,
    required this.reason,
    required this.type_job,
    required this.status_report,
    required this.created_at,
    required this.type,
    required this.report_id,
  });

  // Paleta de estados (tonos iOS)
  Color _getStatusColor() {
    switch (status_report.toLowerCase()) {
      case 'in_review':
        return const Color(0xFFFF9500); // naranja
      case 'pending':
        return const Color(0xFFAF52DE); // morado
      case 'resolved':
        return const Color(0xFF34C759); // verde
      case 'dismissed':
      case 'canceled':
        return const Color(0xFFFF3B30); // rojo
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (status_report.toLowerCase()) {
      case 'in_review':
        return 'En Proceso';
      case 'resolved':
        return 'Resuelto';
      case 'dismissed':
        return 'Rechazado';
      case 'canceled':
        return 'Cancelado';
      case 'pending':
        return 'Pendiente';
      default:
        return status_report;
    }
  }

  // Estados "en vivo" -> el punto del badge pulsa
  bool _isActive() {
    final s = status_report.toLowerCase();
    return s == 'in_progress' || s == 'going' || s == 'arrived';
  }

  String _formatDate() {
    final date = DateTime.tryParse(created_at);
    if (date == null) return created_at;
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${meses[date.month - 1]} ${date.year}';
  }

  Widget _buildStatusDot(Color color) {
    final dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (_isActive()) {
      return dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.7, end: 1.2, duration: 700.ms, curve: Curves.easeInOut);
    }
    return dot;
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusDot(color),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.surface;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: onSurface.withOpacity(0.06), width: 0),
      ),
      child: InkWell(
        onTap: () {
          if(type =='client')
          {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Inforeportclientpage(report_id: report_id),
              ),
            );
          }
          else{
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Inforeportjobpage(report_id: report_id),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              // ---- Header: icono + título + estado ----
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color :colorsecundario.withOpacity(0.20),          
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      type == 'job'
                          ?  type_job == 'express' ? Icons.flash_on_rounded: Icons.work_outline
                          : Icons.people_alt_rounded,
                      size: 24,
                      color: colorsecundario,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: onSurface.withOpacity(0.40),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildStatusBadge(),
                ],
              ),

              const SizedBox(height: 10),
              // ---- Descripción ----
              Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.5,
                    color: onSurface.withOpacity(0.55),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideX(
          begin: -0.15,
          curve: Curves.easeOutCubic,
        );
  }
}