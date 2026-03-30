import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Components/SinDatos/cardsServicios.dart';
import 'package:gixt_worker/Components/calendar.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/components/alert.dart';
import 'package:gixt_worker/components/cards/CardsExpress.dart';
import 'package:gixt_worker/components/cards/cardsAgenda.dart';
import 'package:gixt_worker/components/cards/cardsServicios.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/components/sketor/cardsCategoria.dart';
import 'package:gixt_worker/components/sketor/cardsServicios.dart';
import 'package:gixt_worker/services/Job/Express_service.dart';
import 'package:gixt_worker/services/Job/Job_service.dart';
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
  final Servicios_service api = Servicios_service();
  final Jobs_service jobs = Jobs_service();
  final ServiciosFav_service fav = ServiciosFav_service();
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
    print("Entré a Restaurantes");
   
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
    });
  }

  Future<void> _reload() async {
     await express.updatedata();
          if (!mounted) return;
     setState(() {
       
     });
  }

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
      timeout = false;
    });

    await api.updatedata();
    await categorias.updatedata();
    await express.updatedata();
    await jobs.updatedata();
    _Validation();
  }

  Future<void> _Initial() async {
    setState(() {
      isLoading = true;
      timeout = false;
    });
    bool ok = await api.fetchServicioData();
    bool okData = await categorias.fetchCategoriasData();
    bool okEx = await express.fetchFromApi();
    bool okjob = await jobs.fetchAgendaData();
    if (!okData || !ok || !okEx) {
      if (!mounted) return;
      setState(() {});
      mostrarAlerta(
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
        });
        print('terminando contador');
      }
    });
    if (!mounted) return;
    setState(() {
      if (api.servicios.isNotEmpty) {
        isLoading = false;
      }
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
                    const SizedBox(height: 20),
                    if (express.express.isNotEmpty) ...[_buildDivider(),_buildExpress()],
                    _buildDivider(),
                    _buildServicios(),
                    _buildDivider(),
                    if (jobs.jobs.isNotEmpty) ...[_buildServiciosjob(),],
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
      expandedHeight: 120,
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
                           Icon(Icons.radio_button_checked,
                              size: 12, color: Theme.of(context).colorScheme.surface),
                          const SizedBox(width: 6),
                          Text(
                            ciudad.isEmpty ? 'Obteniendo ubicación…' : '$ciudad, $estado',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.surface,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hola, ${username ?? ''}',
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
                Circleimage(w: 48, h: 48, image_url: img),
              ],
            ),
          ),
        ),
      ),
    );
  }

 Widget _sectionHeader(String title, {String? sub, VoidCallback? onMore}) {
      return  Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color:  Theme.of(context).colorScheme.surface, letterSpacing: -0.4,
                    )),
                if (sub != null)
                  Text(sub,
                      style: GoogleFonts.inter(
                          fontSize: 12, color:  Theme.of(context).colorScheme.surface.withOpacity(0.55), fontWeight: FontWeight.w400)),
              ],
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

      ).animate().fade().slideX(begin: -0.1);
    }
  
  Widget _buildServiciosjob() {
    // Filtrar por estado
    final List<Jobs> filtrados = jobs.jobs.where((a) {
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
              _sectionHeader('Servicios En Curso', sub: 'Servicios Programados Activos',),
            
            GridView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
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
                      name: agenda.service_name,
                      client_image: agenda.client_image,
                      job_id: agenda.job_id,
                      client: agenda.client_first_name,
                      date: agenda.job_date,
                      time: agenda.job_time,
                      price: agenda.price,
                      description: agenda.service_description,
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

  Widget _buildServicios() {
    final isLoading = api.servicios.isEmpty;
    if (timeout) {
      return CardsSN(img: 'assets/Banner1.png');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
      child: Container(
        alignment: Alignment.topLeft,
        child: Column(
          children: [
              _sectionHeader('Servicios Creados', sub: 'Estos servicos ven los usuario',),
           
            SizedBox(
               height: 370,
              child: GridView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 30,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: 1,
          mainAxisSpacing: 30,
          childAspectRatio: 1.45,
                ),
                itemCount: isLoading
                    ? 3 //  skeletons visibles
                    : api.servicios.length,
                itemBuilder: (context, index) {
                  if (isLoading && !timeout) {
                    return const CardsEmpresaSkeleton();
                  }
                  try {
                    final servicio = api.servicios[index];

                    return CardsServicios(
                          image_url: servicio.image,
                          name: servicio.service_name,
                          worker_image: servicio.userImage,
                          service_id: servicio.service_id,
                          worker: servicio.first_name,
                          category: servicio.category,
                          stars: servicio.rating,
                          price: servicio.price,
                          description: servicio.description,
                          favorito: false,
                        )
                        .animate()
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.15)
                        .scale(begin: const Offset(0.96, 0.96));
                  } catch (e) {
                    return const SizedBox(); // widget vacío
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpress() {
    final isLoading = express.express.isEmpty;
    if (timeout) {
      return CardsSN(img: 'assets/Banner1.png');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
      child: Container(
        alignment: Alignment.topLeft,
        child: Column(
          children: [
            _sectionHeader('Servicios Express Curso', sub: 'Servicios Express Activos',),
            
            SizedBox(
              
              child: GridView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 20,
                  childAspectRatio: 2.5,
                ),
                itemCount: isLoading
                    ? 1 //  skeletons visibles
                    : express.express.length,
                itemBuilder: (context, index) {
                  if (isLoading && !timeout) {
                    return const CardsEmpresaSkeleton();
                  }
                  try {
                    final servicio = express.express[index];
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
                    return const SizedBox(); // widget vacío
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildDivider() {
  return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Theme.of(context).colorScheme.surface.withOpacity(0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
