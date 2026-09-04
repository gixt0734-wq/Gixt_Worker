import 'dart:convert' as ui hide Codec;
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Components/CircleImage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/Components/Sketor/opciones.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/OptionsCategoriasView.dart';
import 'package:gixt_worker/Components/categoriasoption.dart';
import 'package:gixt_worker/Components/inputs/Input_Description.dart';
import 'package:gixt_worker/Components/inputs/Input_Price.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/Skeletor/PerfilWorkerSkeletor.dart';
import 'package:gixt_worker/services/Location/Geolocation_service.dart';
import 'package:gixt_worker/services/Location/geocoding_helper.dart';
import 'package:gixt_worker/services/servicios/categorias_service.dart';
import 'package:gixt_worker/services/user/Worker_service.dart';
import 'package:gixt_worker/services/user/update_info_service%20copy.dart';
import 'package:gixt_worker/services/user/update_info_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilWorkerPage extends StatefulWidget {
  const PerfilWorkerPage({super.key});

  @override
  State<PerfilWorkerPage> createState() => _PerfilWorkerPageState();
}

class _PerfilWorkerPageState extends State<PerfilWorkerPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final Worker_service worker = Worker_service();
  List<int?> _categoriaSeleccionada = [];
  final Categorias_service category = Categorias_service();

  int _paginaActual = 0;
  bool isLoading = false;
  bool hasMore = true;

  double longitude = 0;
  double latitude = 0;
  double _rangoKm = 1.0;

  String? calle;
  String? ciudad;
  String? estado;
  String? pais;
  String? colonia;

  String? img;
  String? username;
  bool isworking = false;

  GoogleMapController? mapController;
  LatLng? posicionActual = LatLng(20.9674, -89.5926);
  bool loadig = true;

  BitmapDescriptor markericon = BitmapDescriptor.defaultMarker;
  final ScrollController _scrollController = ScrollController();
  final PreferencesService _preferencesService = PreferencesService();

  Future<void> _GoMyLocation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );
    try {
      Position pos = await GeoLocationService.obtenerUbicacion(context);
      latitude = pos.latitude;
      longitude = pos.longitude;
      setState(() {
        posicionActual = LatLng(pos.latitude, pos.longitude);
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: posicionActual!, zoom: 17),
          ),
        );
      });
    } catch (e) {
      print(e);
    }

    await GetStreet();
    setState(() {
      loadig = false;
    });
    Navigator.pop(context);
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


  Future<BitmapDescriptor> getMarkerIcon(String imagePath, int width) async {
    final ByteData data = await rootBundle.load(imagePath);

    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );

    final ui.FrameInfo fi = await codec.getNextFrame();

    final ByteData? bytes = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> marker() async {
  
    final w = MediaQuery.of(context).size.width * .27;

    const ImageConfiguration configuration = ImageConfiguration(
      size: Size(80, 80),
    );

    markericon = await getMarkerIcon("assets/marker.png",w.toInt());

    if (mounted) {
      setState(() {
        markericon;
      });
    }
  }

  double _zoomForRange(double km) {
    // Fórmula aproximada: a 1km → zoom ~15, a 5km → zoom ~12
    // log2(40075 * cos(lat) / (km * 256)) ≈ zoom
    // Simplificado para mejor UX:
    if (km <= 0.5) return 16.0;
    if (km <= 1.0) return 15.0;
    if (km <= 1.5) return 14.5;
    if (km <= 2.0) return 14.0;
    if (km <= 3.0) return 13.3;
    if (km <= 4.0) return 12.8;
    return 12.3; // 5 km
  }

  void _UpdateZoomforRange() {
    final zoom = _zoomForRange(_rangoKm);
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: posicionActual!, zoom: zoom),
      ),
    );
  }

  bool salir() {
    if (_paginaActual != 0) {
      setState(() {
        _paginaActual--; // vuelve al formulario
      });
      return false;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    marker();
    _loadPrefs();
    _Initial();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      img = prefs.getString('img');
      username = prefs.getString('user');
      isworking = prefs.getBool('isworking') ?? false;
    });
  }

  Future<void> _onRefresh() async {
    await worker.updatedata();
        Navigator.pop(context);
        if (!mounted) return;
        setState(() {
      });
      if(_paginaActual == 1)
      {
        if (!mounted) return;
         setState(() {
          _paginaActual--;
        });
      }
      if(_paginaActual == 2)
      {
        if (!mounted) return;
         setState(() {
          _paginaActual=0;
        });
      }
     Toast(
        context,
        title: '¡Perfil actualizado!',
        message: 'Tu información se guardó correctamente.',
        type: alert_type.exito,
      );
      
    setState(() {
      print('Actualizando datos...');
      hasMore = true;
      _descriptionController.text = worker.worker[0].description;
      _rangoKm = worker.worker[0].range_km.toDouble();
      _priceController.text = worker.worker[0].km_cost.toString();
      latitude = worker.worker[0].latitude;
      longitude = worker.worker[0].longitude;
      hasMore = true;
      posicionActual = LatLng(latitude, longitude);
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: posicionActual!, zoom: 17),
        ),
      );
      GetStreet();
    });
  }

  Future<void> _Refresh() async {
    await worker.updatedata();
    setState(() {
      print('Actualizando datos...');
      hasMore = true;
      _descriptionController.text = worker.worker[0].description;
      _rangoKm = worker.worker[0].range_km.toDouble();
      _priceController.text = worker.worker[0].km_cost.toString();
      latitude = worker.worker[0].latitude;
      longitude = worker.worker[0].longitude;
      hasMore = true;

      posicionActual = LatLng(latitude, longitude);
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: posicionActual!, zoom: 17),
        ),
      );
      GetStreet();
    });
  }

  Future<void> _Initial() async {
    bool ok = await worker.fetchUserData();
    await category.fetchCategoriasData();
    if (!ok) {
      if (!mounted) return;
      Toast(
        context,
        title: "Error",
        message: "No se pudo obtener la información",
        type: alert_type.error,
      );
    }

    for(var catadd in worker.worker[0].listcatworker)
    {
      addcategory(catadd.id);
    }

    setState(() {
      print('Iniciando home');
      _descriptionController.text = worker.worker[0].description;
      _rangoKm = worker.worker[0].range_km.toDouble();
      _priceController.text = worker.worker[0].km_cost.toString();
      latitude = worker.worker[0].latitude;
      longitude = worker.worker[0].longitude;
      hasMore = true;

      posicionActual = LatLng(latitude, longitude);
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: posicionActual!, zoom: 17),
        ),
      );
      GetStreet();
    });
  }

  void _Update() async {
   
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await UpdateInfoService.Send(
      description: _descriptionController.text,
      city: ciudad ?? '',
      latitude: latitude,
      longitude: longitude,
      labor_cost: double.parse(_priceController.text),
      range_km: _rangoKm,
    );



    if (result['success'] == true) {
      final data = result['data'];
     await  _onRefresh();
    } else {
      Toast(
        context,
        title: "Error",
        message: result['message'],
        type: alert_type.error,
      );
      Navigator.pop(context);
    }
  }

   void _UpdateCat() async {
   
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await UpdateCatService.Send(
      cat: _categoriaSeleccionada
    );

    if (result['success'] == true) {
      final data = result['data'];
     await  _onRefresh();

    } else {
      Navigator.pop(context);
      Toast(
        context,
        title: "Error",
        message: result['message'],
        type: alert_type.error,
      );

      
    }
  }

  void addcategory(int id) {
    if (_categoriaSeleccionada.contains(id)) {
      _categoriaSeleccionada.remove(id);
    } else {
      _categoriaSeleccionada.add(id);
    }
  }


  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async {
        return salir();
      },
      child: KeyboardDismisser(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: _Refresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (worker.worker.isEmpty) ...[
                      const PerfilWorkerSkeletor(),
                    ] else ...[
                      if (_paginaActual == 1) _buildMapa(),
                      if (_paginaActual == 0) ...[
                        _buildEditHint(),
                        _buildWorking(),
                        _buildWorkingCategory(),
                        const SizedBox(height: 100),
                      ],
                      if (_paginaActual == 2) _buildCategory(),
                    ]
                    ]),
                  ),
                ),
              ],
            ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Mi Espacio de Trabajo',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🆕 Banner-guía: avisa al usuario que las tarjetas son editables
  // ─────────────────────────────────────────────────────────────
  Widget _buildEditHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorsecundario.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorsecundario.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colorsecundario.withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorsecundario,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Toca cualquier sección para editar y guardar tu información.',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🆕 Badge reutilizable "Editar" para las esquinas de las tarjetas
  // ─────────────────────────────────────────────────────────────
  Widget _editBadge({String label = 'Editar'}) {
    return GestureDetector(
      onTap: () => {
        setState(() {
          _paginaActual =2;
        })
      },
      child:
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorsecundario.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_rounded, size: 11, color: colorsecundario),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colorsecundario,
            ),
          ),
        ],
      ),
    )
    );
  }

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () => _showofferSheetDescription(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Circleimage(image_url: img, w: 60, h: 60),
                    if (isworking)
                      Positioned(
                        bottom: -2,
                        right: -6,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username ?? 'Trabajador',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _descriptionController.text.isEmpty
                                  ? 'Toca aquí para agregar tu descripción profesional'
                                  : _descriptionController.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 🆕 ícono lápiz a la derecha
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorsecundario.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: colorsecundario,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    if (worker.worker.isEmpty) return const SizedBox();
    final w = worker.worker[0];
    return Row(
      children: [
        _miniStat(
          Icons.monetization_on_rounded,
          '\$${w.km_cost.toStringAsFixed(0)} MXN',
          'Tarifa por visita',
          () => _showofferSheetDiagnostic(_Update),
        ),
        const SizedBox(width: 10),
        _miniStat(
          Icons.social_distance_rounded,
          '${w.range_km} km',
          'Radio de trabajo',
          () {
            setState(() {
              _paginaActual++;
            });
          },
        ),
      ],
    );
  }

  Widget _miniStat(
    IconData icon,
    String value,
    String label,
    VoidCallback ontap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ontap(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colorsecundario),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              // 🆕 ícono de editar/ajustar al final
              Icon(
                Icons.edit_rounded,
                size: 13,
                color: colorsecundario.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _nextButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorWhite,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorsecundario,
          foregroundColor: colorWhite,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildMapa() {
    final h = MediaQuery.of(context).size.height * .89;
    return SizedBox(
      height: h,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: posicionActual!,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              mapController = controller;
            },
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            onTap: (pos) {
              setState(() {
                posicionActual = pos;
                latitude = pos.latitude;
                longitude = pos.longitude;
                mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: posicionActual!, zoom: 16),
                  ),
                );
              });

              GetStreet();
            },
            circles: _buildCirculoRango(),
            markers: {
              Marker(
                markerId: MarkerId("ubicacion"),
                position: posicionActual!,
                icon: markericon,
              ),
            },
          ),

          
          Positioned(
            top: 12,
            left: 15,
            right: 15,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               GestureDetector(
              onTap: () => setState(() => _paginaActual = 0),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: colorsecundario,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: 
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: colorsecundario,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ubicación seleccionada',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorsecundario,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    calle ?? 'Toca el mapa para seleccionar',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (colonia != null || ciudad != null)
                    Text(
                      [colonia, ciudad].where((e) => e != null).join(', '),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
             )
            ),
            const SizedBox(width: 8),
             GestureDetector(
              onTap: _GoMyLocation,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  color: colorsecundario,
                  size: 20,
                ),
              ),
            ),
            ]
            )
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ─── Handle visual ───
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ─── Título + valor del rango ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: 
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rango de trabajo',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                              ),
                           
                              Text(
                                'Distancia máxima a la que te desplazas',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withOpacity(0.45),
                                ),
                              ),
                            ],
                          ),),
                          // ─── Badge con el valor ───
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorsecundario.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_rangoKm.toStringAsFixed(1)} km',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colorsecundario,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ─── Slider ───
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: colorsecundario,
                          inactiveTrackColor: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.08),
                          thumbColor: colorsecundario,
                          overlayColor: colorsecundario.withOpacity(0.15),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                            elevation: 3,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 20,
                          ),
                        ),
                        child: Slider(
                          value: _rangoKm,
                          min: 0.5,
                          max: 5.0,
                          divisions: 9, // pasos de 0.5 km
                          onChanged: (value) {
                            setState(() {
                              _rangoKm = value;
                            });
                            _UpdateZoomforRange();
                          },
                        ),
                      ),

                      // ─── Etiquetas min/max ───
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0.5 km',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(0.35),
                              ),
                            ),
                            Text(
                              '5.0 km',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(0.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ─── Botón siguiente ───
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: ()  {
                            if (calle == null) {
                              Toast(
                                context,
                                title: 'Ubicación requerida',
                                message: 'Toca el mapa para seleccionar tu punto de trabajo.',
                                type: alert_type.advertencia,
                              );
                              return;
                            }
                            _Update();

                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: colorsecundario,
                            foregroundColor: colorWhite,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Confirmar ubicación',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Set<Circle> _buildCirculoRango() {
    return {
      Circle(
        circleId: const CircleId("rango_trabajo"),
        center: posicionActual!,
        radius: _rangoKm * 1000, // convertir km a metros
        fillColor: colorsecundario.withOpacity(0.12),
        strokeColor: colorsecundario.withOpacity(0.5),
        strokeWidth: 2,
      ),
    };
  }

  Widget _buildWorking() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(
              number: '1',
              title: 'Información laboral',
              subtitle: 'Tu perfil visible para los clientes',
            ),
            const SizedBox(height: 20),
            _buildProfileCard(),
            const SizedBox(height: 12),
            _buildQuickStats(),
            const SizedBox(height: 12),
            _buildLocationCard(),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingCategory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            number: '2',
            title: 'Categorías de trabajo',
            subtitle: 'Áreas en las que ofreces tus servicios',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),

            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🆕 cabecera con badge "Editar"
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: 
                      Text(
                        'MIS CATEGORÍAS',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.45),
                        ),
                      )),
                      _editBadge(label: 'Administrar'),
                    ],
                  ),
                ),
                SizedBox(
                  height: 150, // 👈 altura fija
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 0,
                    ),
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: isLoading
                        ? 3 //  skeletons visibles
                        : worker.worker[0].listcatworker.length,
                    itemBuilder: (context, index) {
                      if (isLoading) {
                        return const OptionsSkeleton();
                      }
                      final categoria = worker.worker[0].listcatworker[index];
                      return OptionsCategoriasView(
                        name: categoria.name,
                        img: categoria.image,
                      );
                    },
                  ).animate().fade().slideX(begin: -0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final hasLocation = calle != null || ciudad != null;
    return GestureDetector(
      onTap: () => setState(() => _paginaActual++),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorsecundario.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: colorsecundario,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zona de trabajo',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasLocation
                        ? (calle ?? ciudad ?? 'Sin dirección')
                        : 'Toca para definir tu zona de trabajo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  if (hasLocation && (colonia != null || ciudad != null))
                    Text(
                      [colonia, ciudad].where((e) => e != null).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              color: colorsecundario.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildSectionHeader({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorsecundario.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorsecundario,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.surface,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _backButton({String label = 'Regresar'}) {
    return GestureDetector(
      onTap: () => setState(() => _paginaActual = 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorsecundario.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.arrow_back_rounded,
              size: 16,
              color: colorsecundario,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showofferSheetDiagnostic(VoidCallback onPressed) {
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: KeyboardDismisser(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel('Tarifa por visita y diagnóstico'),
                        const SizedBox(height: 10),
                        CustomTextFormFieldPrice(
                          controller: _priceController,
                          label: 'Ingresa tu tarifa por visita',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa una tarifa';
                            }
                            final precio = double.tryParse(value.trim());
                            if (precio == null) {
                              return 'Ingresa un número válido';
                            }
                            if (precio < 10) {
                              return 'La tarifa mínima es de \$50';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildInfoCard(
                          icon: Icons.lightbulb_outline_rounded,
                          text:
                              'Consejo: Investiga los precios de servicios similares '
                              'en tu zona para ser más competitivo.',
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState?.validate() ?? false) {
                                onPressed();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorsecundario,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Guardar tarifa',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showofferSheetDescription() {
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: KeyboardDismisser(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel('Tu presentación profesional'),
                        const SizedBox(height: 20),
                        CustomDescriptionFormField(
                          controller: _descriptionController,
                          label: 'Cuéntanos sobre tu experiencia',
                          hint: 'Ej: Electricista con 5 años de experiencia en instalaciones residenciales...',
                          minLines: 2,
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor agrega una descripción';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState?.validate() ?? false) {
                                _Update();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorsecundario,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Guardar descripción',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


Widget _buildCategory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _backButton(),
          const SizedBox(height: 16),
          _buildSectionHeader(
            number: '3',
            title: '¿Qué tipo de trabajos realizas?',
            subtitle:
                'Selecciona las categorías que mejor describen los servicios que puedes ofrecer a los clientes.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: 
              Text(
                'Categorías seleccionadas',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                ),
              )),

              if (_categoriaSeleccionada.length > 0) ...[
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
                    '${_categoriaSeleccionada.length}',
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
          const SizedBox(height: 20),
          _buildCategoriaItem(),
          const SizedBox(height: 10),
          _nextButton('Guardar', () {
            if (_categoriaSeleccionada.isEmpty) {
              Toast(
                context,
                title: 'Selecciona una categoría',
                message: 'Debes elegir al menos una categoría para continuar',
                type: alert_type.advertencia,
              );
              return;
            }
           _UpdateCat();
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

 Widget _buildCategoriaItem() {
    final isLoading = category.categorias.isEmpty;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1,
      ),

      itemCount: isLoading ? 3 : category.categorias.length,
      itemBuilder: (context, index) {
        if (isLoading) {
          return const OptionsSkeleton();
        }
        final categoria = category.categorias[index];
        return OptionsCategorias(
          nombre: categoria.name,
          img: categoria.image_url,
          id: categoria.category_id,
          isSelected: _categoriaSeleccionada.contains(categoria.category_id),
          onSelected: (id) {
            setState(() {
              if (_categoriaSeleccionada.contains(id)) {
                _categoriaSeleccionada.remove(id);
              } else {
                _categoriaSeleccionada.add(id);
              }
            });
          },
        ).animate(delay: (index * 50).ms).fade().slideX(begin: -0.15);
      },
    ).animate().fade().slideX(begin: -0.2);
  }

}