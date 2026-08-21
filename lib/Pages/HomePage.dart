import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Components/SinDatos/cardsServicios.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/calendar.dart';
import 'package:gixt_worker/Config/Notifiers/home_notifiers.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/NotificationPage.dart';
import 'package:gixt_worker/components/cards/CardsExpress.dart';
import 'package:gixt_worker/components/cards/cardsAgenda.dart';
import 'package:gixt_worker/components/cards/cardsServicios.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/components/sketor/cardsCategoria.dart';
import 'package:gixt_worker/components/sketor/cardsServicios.dart';
import 'package:gixt_worker/routes/BottomNavigationBar.dart';
import 'package:gixt_worker/services/Agenda/Agenda_service.dart';
import 'package:gixt_worker/services/Express/Express_service.dart';
import 'package:gixt_worker/services/Job/Jobs_service.dart';
import 'package:gixt_worker/services/Location/Geolocation_service.dart';
import 'package:gixt_worker/services/Location/geocoding_helper.dart';
import 'package:gixt_worker/services/servicios/categorias_service.dart';
import 'package:gixt_worker/services/servicios/servicios_service.dart';
import 'package:gixt_worker/services/servicios/serviciosbyfav.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // final Servicios_service api = Servicios_service();
  final Agenda_service jobs = Agenda_service();
  final Categorias_service categorias = Categorias_service();
  final Express_service express = Express_service();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);
  int pageNumber = 1;
  String? img;
  String? username;
  String? calle;
  String ciudad = "";
  String estado = "";
  String pais = "";
  String colonia = "";
  double longitude = 0;
  double latitude = 0;
  GoogleMapController? mapController;
  LatLng posicionActual = LatLng(20.9674, -89.5926);
  bool isLoading = false;
  bool hasMore = true;
  bool timeout = false;
  bool hayNotificacion = false;
  bool? isworking = false;

  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('llegoooooooo');
      if (!mounted) return;
      setState(() {
        hayNotificacion = true;
      });
    });
    // 👇 SE EJECUTA AL ENTRAR A LA PÁGINA
    print("Entré a Home");
    homeNotifier.addListener(_Refresh);
    _loadUserId();
    _Initial();
    _GoMyLocation();
    //  expressNotifier.addListener(_reload);
    // cancelexpressNotifier.addListener(_reload);
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      img = prefs.getString('img');
      username = prefs.getString('user');
      isworking = prefs.getBool('isworking') ?? false;
    });
  }

  Future<void> _reload() async {
    await express.updatedata();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
      timeout = false;
    });

    await categorias.updatedata();
    await express.updatedata();
    await jobs.fetchFromApi(1);
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    _Validation();
  }

  Future<void> _Refresh() async {
    await express.updatedata();
    await jobs.fetchFromApi(1);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _Initial() async {
    setState(() {
      isLoading = true;
      timeout = false;
    });
    bool okData = await categorias.fetchCategoriasData();
    bool okEx = await express.fetchFromApi();
    bool okjob = await jobs.fetchAgendaData();
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    if (!okData || !okEx) {
      Toast(
        context,
        title: "Error",
        message: "No se pudo obtener la información",
        type: alert_type.error,
      );
    }
    _Validation();
  }

  Future<void> _Validation() async {
    print('empezando contador');
    Future.delayed(const Duration(seconds: 5), () {
      if (isLoading) {
        setState(() {
          timeout = true;
          isLoading = false;
        });
        print('terminando contador');
      }
    });
    if (!mounted) return;
    setState(() {
      // if (api.servicios.isNotEmpty) {
      //   isLoading = false;
      // }
    });
  }

  Future<void> _GoMyLocation() async {
    Position pos = await GeoLocationService.obtenerUbicacion(context);
    latitude = pos.latitude;
    longitude = pos.longitude;
    setState(() {
      posicionActual = LatLng(pos.latitude, pos.longitude);
    });

    await GetStreet();
  }

  Future<void> GetStreet() async {
    GeocodingHelper.obtenerCiudadDesdeCoordenadas(
      latitud: latitude,
      longitud: longitude,
      onResult:
          (ciudadResult, calleResult, estadoResult, paisResult, coloniaResult) {
            setState(() {
              ciudad = ciudadResult;
              calle = calleResult;
              estado = estadoResult;
              colonia = coloniaResult;
              pais = paisResult;
            });
          },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
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
                  horizontal: 0,
                  vertical: 20,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Calendar(),
                    const SizedBox(height: 16),
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    _buildServiciosjob(),
                    // _buildServiciosActivos2(),
                    if (!isLoading &&
                        jobs.agenda
                            .where(
                              (j) =>
                                  j.job_status == 'in_progress' ||
                                  j.job_status == 'going' ||
                                  j.job_status == 'arrived',
                            )
                            .isEmpty &&
                        express.express
                            .where((e) => e.job_status != 'completed')
                            .isEmpty)
                      _buildEmptyState(),
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
      expandedHeight: 150,
      elevation: 0,
      pinned: false,
      floating: false, // 👈 sin efecto raro
      snap: false, // 👈 sin delay
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),

          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ubicación
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.radio_button_checked,
                            size: 12,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ciudad.isEmpty
                                  ? 'Obteniendo ubicación…'
                                  : '$ciudad, $estado',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.surface,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getGreeting()}, ${username ?? ''}',
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colorsecundario,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Notificaciones
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      color: Theme.of(context).colorScheme.surface,
                      iconSize: 28,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationPage(),
                          ),
                        );
                        setState(() {
                          hayNotificacion = false;
                        });
                      },
                    ),

                    if (hayNotificacion)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),

                // Avatar
                InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppBottomNavigation(index: 4),
                      ),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Circleimage(w: 48, h: 48, image_url: img),

                      if (isworking!)
                        Positioned(
                          bottom: -5,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {String? sub, VoidCallback? onMore}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.surface,
                letterSpacing: -0.4,
              ),
            ),
            if (sub != null)
              Text(
                sub,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        // Spacer(),
        // InkWell(
        //   onTap: () {},
        //   child: Icon(
        //     Icons.arrow_forward_ios,
        //     size: 20,
        //     color: Theme.of(context).colorScheme.surface,
        //   ),
        // ),
      ],
    ).animate().fade().slideX(begin: -0.1);
  }

  Widget _buildServiciosjob() {
    // Filtrar por estado
    final List<Agenda> filtrados = jobs.agenda.where((a) {
      return a.job_status == 'in_progress' ||
          a.job_status == 'going' ||
          a.job_status == 'arrived';
    }).toList();

    if (filtrados.isEmpty && !isLoading) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
      child: Container(
        alignment: Alignment.topLeft,
        child: Column(
          children: [
            _sectionHeader(
              'Servicios En Curso',
              sub: 'Servicios Programados Activos',
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: isLoading ? 2 : filtrados.length,
              itemBuilder: (context, index) {
                if (isLoading) {
                  return const CardsCategoriaSkeleton();
                }

                final agenda = filtrados[index];

                return CardsAgenda(
                      image_url: agenda.image,
                      type: agenda.type,
                      name: agenda.problem,
                      client_image: agenda.client_image,
                      job_id: agenda.job_id,
                      client: agenda.client_first_name,
                      date: agenda.job_date,
                      time: agenda.job_time,
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
      ),
    );
  }

  Widget _buildServiciosActivos2() {
    final List<Agenda> filtrados = jobs.agenda.where((a) {
      return a.job_status == 'in_progress' ||
          a.job_status == 'going' ||
          a.job_status == 'arrived';
    }).toList();

    if (!isLoading && filtrados.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 0, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: _sectionHeader(
              'Servicios En Curso',
              sub: 'Tus servicios activos ahora',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.18,
            child: isLoading && !timeout
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 15),
                    itemCount: 2,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, __) => SizedBox(
                      width: MediaQuery.of(context).size.width * 0.10,
                      child: Shimmer.fromColors(
                        baseColor: Theme.of(context).colorScheme.primary,
                        highlightColor: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.06),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 15),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final agenda = filtrados[index];
                      return SizedBox(
                        width: MediaQuery.of(context).size.width * 0.82,

                        child: CardsAgenda(
                          image_url: agenda.image,
                          type: agenda.type,
                          name: agenda.problem,
                          client_image: agenda.client_image,
                          job_id: agenda.job_id,
                          client: agenda.client_first_name,
                          date: agenda.job_date,
                          time: agenda.job_time,
                          description: agenda.description,
                          address: agenda.maps_address,
                          status: agenda.job_status,
                        ).animate().fade(duration: 350.ms).slideX(begin: 0.08),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  // Widget _buildServicios() {
  //   final isLoading = api.servicios.isEmpty;

  //   if (timeout) {
  //     return CardsSN(img: 'assets/Banner1.png');
  //   }
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
  //     child: Container(
  //       alignment: Alignment.topLeft,
  //       child: Column(
  //         children: [
  //           _sectionHeader(
  //             'Servicios Creados',
  //             sub: 'Estos servicos ven los usuario',
  //           ),

  //           SizedBox(
  //             height: 370,
  //             child: GridView.builder(
  //               controller: _scrollController,
  //               scrollDirection: Axis.horizontal,
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 0,
  //                 vertical: 30,
  //               ),
  //               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //                 crossAxisCount: 1,
  //                 mainAxisSpacing: 30,
  //                 childAspectRatio: 1.45,
  //               ),
  //               itemCount: isLoading
  //                   ? 3 //  skeletons visibles
  //                   : api.servicios.length,
  //               itemBuilder: (context, index) {
  //                 if (isLoading && !timeout) {
  //                   return const CardsEmpresaSkeleton();
  //                 }
  //                 try {
  //                   final servicio = api.servicios[index];

  //                   return CardsServicios(
  //                         image_url: servicio.image,
  //                         name: servicio.service_name,
  //                         worker_image: servicio.userImage,
  //                         service_id: servicio.service_id,
  //                         worker: servicio.first_name,
  //                         category: servicio.category,
  //                         stars: servicio.rating,
  //                         price: servicio.price,
  //                         description: servicio.description,
  //                         favorito: false,
  //                       )
  //                       .animate()
  //                       .fade(duration: 400.ms)
  //                       .slideY(begin: 0.15)
  //                       .scale(begin: const Offset(0.96, 0.96));
  //                 } catch (e) {
  //                   return const SizedBox(); // widget vacío
  //                 }
  //               },
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildExpress() {
    final List<Express> filtrados = express.express.where((a) {
      return a.job_status != 'completed' && a.job_status != 'canceled';
    }).toList();

    if (filtrados.isEmpty && !isLoading) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
      child: Container(
        alignment: Alignment.topLeft,
        child: Column(
          children: [
            _buildDivider(),
            _sectionHeader(
              'Servicios Express Curso',
              sub: 'Servicios Express Activos',
            ),

            GridView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 20,
                childAspectRatio: 2.5,
              ),
              itemCount: isLoading ? 2 : filtrados.length,
              itemBuilder: (context, index) {
                if (isLoading) {
                  return const CardsCategoriaSkeleton();
                }
                try {
                  final servicio = filtrados[index];
                  return CardsExpress(
                        image_url: servicio.image,
                        name: servicio.problem,
                        client_image: servicio.client_image,
                        express_id: servicio.express_id,
                        client: servicio.client_username,
                        maps_address: servicio.maps_address,
                        price: servicio.price,
                        description: servicio.description,
                        date: servicio.job_date,
                        time: servicio.job_time,
                        status: servicio.job_status,
                      )
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.15)
                      .scale(begin: const Offset(0.96, 0.96));
                } catch (e) {
                  return const SizedBox();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final activeJobs = jobs.agenda
        .where(
          (j) =>
              j.job_status == 'in_progress' ||
              j.job_status == 'going' ||
              j.job_status == 'arrived',
        )
        .length;
    final activeExpress = express.express
        .where((e) => e.job_status != 'completed')
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          _statCard(
            Icons.work_outline_rounded,
            activeJobs.toString(),
            'En Curso',
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _statCard(
            Icons.bolt_rounded,
            activeExpress.toString(),
            'Express',
            colorsecundario,
          ),
        ],
      ),
    ).animate().fade(duration: 350.ms).slideY(begin: 0.1);
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: scheme.surface,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: scheme.surface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
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
            'Sin trabajos activos',
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
            'Cuando tengas servicios en curso\naparecerán aquí.',
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

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
