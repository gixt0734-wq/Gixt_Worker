import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Components/ActionAlert%20.dart';
import 'package:gixt_worker/Components/BarStatusReport.dart';
import 'package:gixt_worker/Components/CircleImage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Config/Notifiers/reports_notifiers.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/services/Reports/Cancel_Report_Service.dart';
import 'package:gixt_worker/services/Reports/Report_service_job.dart';
import 'package:gixt_worker/services/Reports/Report_service_worker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class Inforeportjobpage extends StatefulWidget {
  const Inforeportjobpage({super.key, required this.report_id});
  final String report_id;
  @override
  State<Inforeportjobpage> createState() => _InforeportjobpageState();
}

class _InforeportjobpageState extends State<Inforeportjobpage> {
  bool isLoading = false;
  bool hasMore = true;
  final ReportsServicejob report = ReportsServicejob();
  final ScrollController _scrollController = ScrollController();
  bool fav = false;

  @override
  void initState() {
    super.initState();
    reportsNotifier.addListener(_onRefresh);
    _initial();
  }

  Future<void> _initial() async {
    bool ok = await report.fetchData(widget.report_id);
    if (!ok) {
      if (!mounted) return;
      Future.microtask(() async {
        await Toast(
          context,
          title: "Error",
          message: "No se pudo obtener la información",
          type: alert_type.error,
        );
        Navigator.pop(context);
      });
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(() => hasMore = true);
    bool ok = await report.fetchData(widget.report_id);
    if (!ok) {
      if (!mounted) return;
      Future.microtask(() async {
        await Toast(
          context,
          title: "Error",
          message: "No se pudo obtener la información",
          type: alert_type.error,
        );
        Navigator.pop(context);
      });
    }
    setState(() {});
  }

  void _Cancelar() async {
    bool? ok = await ActionAlert(
      context,
      title: 'Cancelar Reporte',
      message: '¿Estás seguro de cancelar esta reporte?',
      type: action_type.advertencia,
    );
    if (ok!) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Indicador(),
      );
     final result = await CancelReportService.CancelReport(
       report_id: widget.report_id,
       type: 'job'
      );

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        if (!mounted) return;
        Future.microtask(() async {
          await Toast(
            context,
            title: "Reporte cancelado",
            message: "Reporte cancelado exitosamente",
            type: alert_type.exito,
          );
        });
      } else {
        Toast(
          context,
          title: "Error",
          message: result['message'],
          type: alert_type.error,
        );
      }
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.pop(context), // cerrar al tocar
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image),
              ),
              
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (report.report.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Indicador(),
      );
    }
    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          color: colorsecundario,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTitle()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideX(begin: -0.2, curve: Curves.easeOutCubic),

                    const SizedBox(height: 10),
                     _sectionCard(
                      title: 'Estado del reporte',
                      child:
                          BarstatusReport(
                                estadoReport: report.report[0].status_report,
                              )
                              .animate()
                              .fadeIn(delay: 50.ms, duration: 500.ms)
                              .slideY(begin: 0.3, curve: Curves.easeOutCubic),
                    ),
                    const SizedBox(height: 10),

                    _buildReport()
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 500.ms)
                        .slideY(begin: 0.3, curve: Curves.easeOutCubic),
                    const SizedBox(height: 10),

                    _buildTrabajador()
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .slideY(begin: 0.3, curve: Curves.easeOutCubic),
                    const SizedBox(height: 10),
                    _buildImg().animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms)
                        .slideY(begin: 0.3, curve: Curves.easeOutCubic),

                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: ['canceled', 'dismissed','resolved'].contains(report.report[0].status_report)? null: _bottomBar(context)
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: 70,
      pinned: true, //  deja solo la barra pequeña visible
      floating: false, //  NO aparece al subir
      snap: false, // NO animación automática
      elevation: 0,
      toolbarHeight: 70,
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.surface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Reporte',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }

 Widget _buildTitle() {
    final color = Theme.of(context).colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reporte para el trabajador',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 6),

        Text(
          report.report[0].problem_job,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.9,
            color: color,
          ),
        ),

        const SizedBox(height: 15),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.update_rounded, size: 16, color: color.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              'Actualizado: ${report.report[0].updated_at}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.5),
              ),
            ),
          ],
        ),

        const SizedBox(height: 0),
      ],
    );
  }
 

  Widget _buildReport() {
    return _sectionCard(
      title: 'Información del reporte',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección descripción
          _detailField('Problema', report.report[0].reason),
          const SizedBox(height: 20),
          _detailField('Descripcion del reporte', report.report[0].description),
          const SizedBox(height: 20),
          if (report.report[0].status_report == 'resolved') ...[
            _detailField('Solucion del reporte', report.report[0].solution),
            const SizedBox(height: 20),
          ],

          _buildInfoCard(
            icon: Icons.support_agent_rounded,
            text:
                'El reporte esta siendo supervisado por el equipo Gixt Support espera una respuesta',
          ),
        ],
      ),
    );
  }

  Widget _detailField(String label, String value) {
    final surface = Theme.of(context).colorScheme.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: surface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.5,
            color: surface.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }


  Widget _buildTrabajador() {
  return _sectionCard(
      title: 'Trabajo reportado',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        InkWell(
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) =>
            //         WorkerPage(id_worker: report.report[0].worker_id),
            //   ),
            // );
          },
          child:  Row(
              children: [
                Circleimage(
                  w: 56,
                  h: 56,
                  image_url: report.report[0].job_image,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${report.report[0].problem_job}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.report[0].description_job,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
              ],
            
          ),
        )

      ],
      )
    );
  }

 Widget _buildImg() {
    return _sectionCard(
      title: 'Evdencia del reporte',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                imageBox(report.report[0].evidence_image),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget imageBox(String? imagen) {
    return SizedBox(
      width: 130,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          imagen == null || imagen == ''
              ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.05),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.12),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  width: double.infinity,
                  height: double.infinity,
                  child: Icon(Icons.image, color: Colors.white, size: 25),
                )
              : GestureDetector(
                  onTap: () {
                    _showFullImage(imagen);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    width: double.infinity,
                    height: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: imagen,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.white24),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        // border: Border(
        //   top: BorderSide(
        //     color: Theme.of(context).colorScheme.surface.withOpacity(0.08),
        //     width: 0,
        //   ),
        // ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {_Cancelar();},
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: colorError,
            foregroundColor: colorWhite,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.close_rounded, size: 20),
          label: Text(
            'Cancelar',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorsecundario.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorsecundario.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorsecundario),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.5,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    String? title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(child: _fieldLabel(title)),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 18,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }

}
