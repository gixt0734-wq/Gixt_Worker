import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Components/SinDatos/cardsServicios.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/components/alert.dart';
import 'package:gixt_worker/components/cards/cardsAgenda.dart';
import 'package:gixt_worker/components/sketor/cardsCategoria.dart';
import 'package:gixt_worker/services/Job/Job_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:signalr_netcore/hub_connection.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final Jobs_service api = Jobs_service();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);

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
    jobsStatusNotifier.addListener(_onRefresh);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      timeout = false;
    });

    bool ok = await api.fetchAgendaData();
    print(ok);
    if (!ok) {
      if (!mounted) return;
      Future.microtask(() async {
        await mostrarAlerta(
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
    await api.updatedata();
    _Validation();
    setState(() {});
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
    if (!mounted) return;
    setState(() {
      if (api.jobs.isNotEmpty) {
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
      expandedHeight: 80,
      pinned: true, //  deja solo la barra pequeña visible
      floating: false, //  NO aparece al subir
      snap: false, // NO animación automática
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      iconTheme: const IconThemeData(
        color: Colors.white, // 👈 color del ícono
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Agenda',
          style: GoogleFonts.poppins(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: colorsecundario,
          ),
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
          color: isSelected
              ? colorsecundario.withOpacity(0.08)
              : Colors.transparent,
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
                  ? colorsecundario
                  : Theme.of(context).colorScheme.surface.withOpacity(0.4),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? colorsecundario
                    : Theme.of(context).colorScheme.surface.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicios(String tipo) {
    // Filtrar por estado
    final List<Jobs> filtrados = api.jobs.where((a) {
      if (tipo.toLowerCase() == 'in_progress') {
        // cuando llamas "in_progress" incluimos los 3 estados
        return a.job_status == 'in_progress' ||
            a.job_status == 'going' ||
            a.job_status == 'arrived';
      } else if (tipo.toLowerCase() == 'todos') {
        return true; // incluye todos los estados
      } else {
        return a.job_status == tipo;
      }
    }).toList();

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
                'Tienes ${_category}: (${filtrados.length})',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
              Spacer(),
              InkWell(
                onTap: () {},
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          GridView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 20,
              childAspectRatio: 2.5,
            ),
            itemCount: isLoading ? 3 : filtrados.length,
            itemBuilder: (context, index) {
              if (isLoading && !timeout) {
                return const CardsCategoriaSkeleton();
              }

              final agenda = filtrados[index];

              return CardsAgenda(
                    image_url: agenda.service_image,
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
                  )
                  .animate()
                  .fade(duration: 400.ms)
                  .slideY(begin: 0.15)
                  .scale(begin: const Offset(0.96, 0.96));
            },
          ),
        ],
      ),
    );
  }
}
