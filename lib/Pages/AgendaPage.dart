import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/Components/SinDatos/cardsServicios.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/calendar.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/components/cards/cardsAgenda.dart';
import 'package:gixt_worker/components/sketor/cardsCategoria.dart';
import 'package:gixt_worker/services/Agenda/Agenda_service.dart';
import 'package:gixt_worker/services/Job/Jobs_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:signalr_netcore/hub_connection.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final Agenda_service api = Agenda_service();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);
  bool isLoading = false;
  bool hasMore = true;
  bool timeout = false;
  bool initialLoad = false;
  int page = 1;
  String? img;
  String? username;
  String _category = 'todos';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    jobsStatusNotifier.addListener(_onRefresh);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    jobsStatusNotifier.removeListener(_onRefresh);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _currentIndexNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      timeout = false;
      initialLoad = true;
    });

    bool ok = await api.fetchAgendaData();

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
      initialLoad = true;
      page = 1;
    });

    await api.fetchFromApi(page);
    _Validation();
    
    if (!mounted) return;
    setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 10 &&
        !isLoading) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (isLoading || !hasMore) return;
    setState(() {
      isLoading = true;
      initialLoad = false;
    });

    page++;

    await api.fetchFromApi(page);

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _Validation() async {
    print('empezando contador');
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (isLoading) {
        setState(() {
          timeout = true;
          initialLoad = false;
        });
        print('terminando contador');
      }
    });
    if (!mounted) return;
    setState(() {
      if (api.agenda.isNotEmpty) {
        isLoading = false;
      }
    });
  }

  String _categoryTitle(String value) {
    switch (value) {
      case 'todos':
        return 'Todos';
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptado';
      case 'in_progress':
        return 'En progreso';
      case 'finalized':
        return 'Finalizado';
      case 'completed':
        return 'Completado';
      default:
        return value;
    }
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
                    Calendar(),
                    const SizedBox(height: 10),
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
          'Agenda',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
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
          const SizedBox(width: 10),
          _categoryChip(
            value: 'pending',
            label: 'Pendiente',
            icon: Icons.pending_actions_outlined,
          ),
          const SizedBox(width: 10),
          _categoryChip(
            value: 'accepted',
            label: 'Aceptado',
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(width: 10),
          _categoryChip(
            value: 'in_progress',
            label: 'En progreso',
            icon: Icons.work_outline,
          ),
          const SizedBox(width: 10),
          _categoryChip(
            value: 'finalized',
            label: 'Finalizado',
            icon: Icons.done_outline,
          ),
          const SizedBox(width: 10),
          _categoryChip(
            value: 'completed',
            label: 'Completado',
            icon: Icons.thumb_up_outlined,
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

  List<Agenda> _filtrar(String tipo) {
    return api.agenda.where((a) {
      final t = tipo.toLowerCase();
      if (t == 'in_progress') {
        return a.job_status == 'in_progress' ||
            a.job_status == 'going' ||
            a.job_status == 'arrived';
      } else if (t == 'todos') {
        return true;
      } else {
        return a.job_status == tipo;
      }
    }).toList();
  }

  Widget _buildData() {
    if (initialLoad && isLoading) {
      return Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: CardsCategoriaSkeleton(),
          ),
        ),
      );
    }
    final filtrados = _filtrar(_category);

    if (filtrados.isEmpty) {
      return _buildEmptyState();
    }

    return _buildServicios(filtrados);
  }

  Widget _buildServicios(List<Agenda> filtrados) {
    final int count = filtrados.length;

    // Indicador al final solo cuando ya hay datos y se está paginando.
    final bool showFooter = isLoading && !initialLoad && count > 0;

    return Container(
      alignment: Alignment.topLeft,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _categoryTitle(_category),
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
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: count + (showFooter ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= count) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Indicador(),
                );
              }

              final agenda = filtrados[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child:
                    CardsAgenda(
                          image_url: agenda.image,
                          name: agenda.problem,
                          client_image: agenda.client_image,
                          job_id: agenda.job_id,
                          client: agenda.client_username,
                          date: agenda.job_date,
                          time: agenda.job_time,
                          description: agenda.description,
                          address: agenda.maps_address,
                          status: agenda.job_status,
                          type: agenda.type,
                        )
                        .animate()
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.15)
                        .scale(begin: const Offset(0.96, 0.96)),
              );
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
            'Aún no tienes trabajos ',
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
            'Recuerda que puedes solicitar trabajos express o tu asiganas la fehca e hora!',
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
