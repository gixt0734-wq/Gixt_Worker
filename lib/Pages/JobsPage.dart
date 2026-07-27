import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Components/Cards/CardscATALOG.dart';
import 'package:gixt_worker/Components/SinDatos/cardsServicios.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/calendar.dart';
import 'package:gixt_worker/Config/Notifiers/catalog_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/components/cards/cardsAgenda.dart';
import 'package:gixt_worker/components/sketor/cardsCategoria.dart';
import 'package:gixt_worker/services/Catalogo/Catalog_service.dart';
import 'package:gixt_worker/services/Job/Jobs_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:signalr_netcore/hub_connection.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final Catalog_service api = Catalog_service();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);
  Timer? _timeoutTimer;
  String _category = 'todos';
  bool isLoading = false;
  bool hasMore = true;
  bool timeout = false;
  String? img;
  String? username;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    catalogNotifier.addListener(_onRefresh);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      timeout = false;
    });

    bool ok = await api.fetchFromApi();
    print(ok);
    if (!ok) {
      if (!mounted) return;
      Future.microtask(() async {
        await Toast(
          context,
          title: "Error",
          message: "No se pudo obtener la información",
          type: alert_type.error,
        );
      });
    }

    _Validation();
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      timeout = false;
    });
    await api.fetchFromApi();
    _Validation();
    setState(() {});
  }

  Future<void> _Validation() async {
    _timeoutTimer?.cancel();

    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;

      if (isLoading) {
        setState(() {
          timeout = true;
        });
      }
    });

    if (!mounted) return;

    setState(() {
      if (api.catalog.isNotEmpty) {
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
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Calendar(),
                    // const SizedBox(height: 10),
                    _buildFiltros(),
                    const SizedBox(height: 20),
                    _buildData(),
                    const SizedBox(height: 100),
                  ]),
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
      automaticallyImplyLeading: false,
      iconTheme: const IconThemeData(
        color: Colors.white, // 👈 color del ícono
      ),
      // bottom: PreferredSize(
      //   preferredSize: const Size.fromHeight(1),
      //   child: Divider(
      //     height: 1,
      //     thickness: 0.5,
      //     color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      //   ),
      // ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Catalogo de trabajos',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }

  Widget _buildData() {
    return Column(
      children: [
        if (timeout) ...[_buildEmptyState()],
        if (!timeout) ...[_buildServicios(_category)],
      ],
    );
  }

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _categoryChip(
            value: 'todos',
            label: 'Todos',
            icon: Icons.list_alt_outlined,
          ),
          const SizedBox(width: 15),
          _categoryChip(
            value: 'express',
            label: 'Express',
            icon: Icons.flash_on_outlined,
          ),
          const SizedBox(width: 15),
          _categoryChip(
            value: 'job',
            label: 'Agendados',
            icon: Icons.event_note_outlined,
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

  Widget _buildServicios(String tipo) {
    final List<Catalog> filtrados = api.catalog.where((a) {
      if (tipo.toLowerCase() == 'todos') {
        return true; // incluye todos los estados
      } else {
        return a.type == tipo;
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
                _category.isEmpty
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
                    '${count}',
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
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: isLoading ? 5 : filtrados.length,
            itemBuilder: (context, index) {
              if (isLoading && !timeout) {
                return const CardsCategoriaSkeleton();
              }

              final agenda = filtrados[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child:  CardsCatalog(
                type: agenda.type,
                image_url: agenda.image_url,
                name: agenda.problem,
                client_image: agenda.client_image,
                job_id: agenda.job_id,
                client: agenda.client_first_name,
                date: agenda.job_date,
                time: agenda.job_time,
                price: agenda.price,
                description: agenda.description,
                address: agenda.maps_address,
                status: agenda.job_status,
                category: agenda.category,
              ));
              // .animate()
              // .fade(duration: 400.ms)
              // .slideY(begin: 0.15)
              // .scale(begin: const Offset(0.96, 0.96));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 38,
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin trabajos cercanos',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Por el momento no hay trabajos disponibles dentro de tu rango de servicio. Puedes ampliar tu rango para descubrir más oportunidades cercanas.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.25),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms);
  }
}
