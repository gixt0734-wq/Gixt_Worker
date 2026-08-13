import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Components/ReportsOptions.dart';
import 'package:gixt_worker/Components/SinDatos/cardsServicios.dart';
import 'package:gixt_worker/Components/Sketor/LocationsOptions.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Config/Notifiers/reports_notifiers.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/services/Reports/Report_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ScrollController _scrollController = ScrollController();
  final ReportsService reports = ReportsService();
  bool isLoading = false;
  bool hasMore = true;
  bool timeout = false;
  String _category = 'todos';

  void initState() {
    super.initState();
    print("Entré a Mis Reportes");
    reportsNotifier.addListener(_onRefresh);
    _initial();
  }

  Future<void> _initial() async {
    setState(() {
      isLoading = true;
      timeout = false;
    });
    bool ok = await reports.fetchData();
    isLoading = true;
    if (!ok) {
      if (!mounted) return;
      setState(() {});
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
    _Validation();
  }

  Future<void> _onRefresh() async {
    setState(() {
      print('Actualizando datos...');
      _initial();
    });
  }
  
  Future<void> _Validation() async {
    print('empezando contador');
    Future.delayed(const Duration(seconds: 5), () {
      if (isLoading) {
        setState(() {
          timeout = true;
        });
        print('terminando contador');
      }
    });
    setState(() {
      if (reports.reports.isNotEmpty) {
        isLoading = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildHero(),
                      const SizedBox(height: 20),
                      _buildData(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
      // bottom: PreferredSize(
      //   preferredSize: const Size.fromHeight(1),
      //   child: Divider(
      //     height: 1,
      //     thickness: 0.5,
      //     color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      //   ),
      // ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Mis Reportes',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }

Widget _buildHero() {
    final onSurface = Theme.of(context).colorScheme.surface;
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tus Reportes',
              style: GoogleFonts.poppins(
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.9,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLoading
                  ? 'Cargando tus reportes...'
                  : 'Revisa el estado de tus reportes y gestiona tus solicitudes de soporte.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color: onSurface.withOpacity(0.5),
              ),
            ),
            if (!isLoading) ...[
              const SizedBox(height: 18),
              _buildFiltros(),
            ],
          ],
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }
  
  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _categoryChip(
            value: 'todos',
            label: 'Todos',
            icon: Icons.list_alt_rounded,
          ),
          const SizedBox(width: 10),
          _categoryChip(
            value: 'pending',
            label: 'Pendiente',
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(width: 10),
          _categoryChip(
            value: 'resolved',
            label: 'Resuelto',
            icon: Icons.task_alt_rounded,
          ),
          const SizedBox(width: 10),
          _categoryChip(
            value: 'in_review',
            label: 'En progreso',
            icon: Icons.autorenew_rounded,
          ),
          const SizedBox(width: 10),
          _categoryChip(
            value: 'dismissed',
            label: 'Rechazado',
            icon: Icons.block_rounded,
          ),
          const SizedBox(width: 10),
          _categoryChip(
            value: 'canceled',
            label: 'Cancelado',
            icon: Icons.highlight_off_rounded,
          ),
        ],
      ),
    );
  }

  Widget _categoryChip({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _category == value;

    return GestureDetector(
      onTap: () => setState(() => _category = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorsecundario : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorsecundario
                : Theme.of(context).colorScheme.surface.withOpacity(0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? colorWhite
                  : Theme.of(context).colorScheme.surface.withOpacity(0.4),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? colorWhite
                    : Theme.of(context).colorScheme.surface.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildData() {
    return Column(
      children: [
        if (timeout) ...[CardsSN(img: 'assets/Banner2.png')],
        if (!timeout) ...[_buildServicios(_category)],
      ],
    );
  }

  Widget _buildServicios(tipo) {
    final isLoading = reports.reports.isEmpty;
    final List<Reports> filtrados = reports.reports.where((a) {
      if (tipo.toLowerCase() == 'todos') {
        return true;
      } else {
        return a.status_report == tipo;
      }
    }).toList();

    final int count = filtrados.length;
    if (filtrados.isEmpty && !isLoading) {
      return Container();
    }
    return Container(
      alignment: Alignment.topLeft,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                filtrados.isEmpty
                    ? ''
                    : '${_category[0].toUpperCase()}${_category.substring(1).toLowerCase()}',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),

              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorsecundario.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${filtrados.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorsecundario,
                    ),
                  ),
                ),
              ],
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 10,
              childAspectRatio: 2.4,
            ),
            itemCount: isLoading ? 5 : filtrados.length,
            itemBuilder: (context, index) {
              if (isLoading && !timeout) {
                return const LocationsOptionsSkeleton();
              }

              final report = filtrados[index];
              return ReportsOptions(
                description: report.description,
                reason: report.reason,
                type_job: report.type_job,
                type: report.type,
                report_id: report.report_id,
                created_at: report.created_at,
                status_report: report.status_report,
              );
            },
          ),
        ],
      ),
    ).animate().fade().slideX(begin: -0.2);
  }

  
}
