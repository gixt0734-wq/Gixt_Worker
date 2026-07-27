import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Auth/Login.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/inputs/Input_Description.dart';
import 'package:gixt_worker/Components/inputs/Input_Price.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/GPS/gps_tracking_page.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/inputs/Input.dart';
import 'package:gixt_worker/components/inputs/Input_Fecha.dart';
import 'package:gixt_worker/components/inputs/Input_Phone.dart';
import 'package:gixt_worker/components/inputs/Pick_Image.dart';
import 'package:gixt_worker/providers/theme_provider.dart';
import 'package:gixt_worker/services/Location/Geolocation_service.dart';
import 'package:gixt_worker/services/Location/geocoding_helper.dart';
import 'package:gixt_worker/services/user/User_service.dart';
import 'package:gixt_worker/services/user/Worker_service.dart';
import 'package:gixt_worker/services/user/update_info_service.dart';
import 'package:gixt_worker/services/user/update_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

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

  int _paginaActual = 0;
  bool isLoading = false;
  bool hasMore = true;

  String? img;
  String? username;
  bool isworking = false;

  double longitude = 0;
  double latitude = 0;
  double _rangoKm = 1.0;

  String? calle;
  String? ciudad;
  String? estado;
  String? pais;
  String? colonia;

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
  Future<BitmapDescriptor> getMarkerIcon(
  String imagePath,
  int width,
) async {
  final ByteData data = await rootBundle.load(imagePath);

  final ui.Codec codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: width,
  );

  final ui.FrameInfo fi = await codec.getNextFrame();

  final ByteData? bytes = await fi.image.toByteData(
    format: ui.ImageByteFormat.png,
  );

  return BitmapDescriptor.fromBytes(
    bytes!.buffer.asUint8List(),
  );
}
  
  Future<void> marker() async {
    const ImageConfiguration configuration = ImageConfiguration(
      size: Size(80, 80),
    );

      markericon = await getMarkerIcon(
        "assets/marker.png",
        100,
      );

    if (mounted) {
      setState(() {
        markericon ;
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
    } else {
      Navigator.pop(context);
      return true;
    }
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

  Future<void> _toggleWorking(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isworking', value);
    if (!mounted) return;
    setState(() {
      isworking = value;
    });
  }

  Future<void> _onRefresh() async {
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
    if (!ok) {
      if (!mounted) return;
      Toast(
        context,
        title: "Error",
        message: "No se pudo obtener la información",
        type: alert_type.error,
      );
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
      range_km: _rangoKm 
    );

    Navigator.pop(context);

    if (result['success'] == true) {
      final data = result['data'];
      Toast(
        context,
        title: "Datos Actualizados",
        message: 'tus datos se actualizo correctamente',
        type: alert_type.exito,
      );
      _onRefresh();
    } else {
      Toast(
        context,
        title: "Error",
        message: result['message'],
        type: alert_type.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (worker.worker.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Indicador()),
      );
    }
    return WillPopScope(
      onWillPop: () async {
        return salir();
      },
      child: KeyboardDismisser(
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
                    vertical: 0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_paginaActual == 1) _buildMapa(),
                      if (_paginaActual == 0) ...[
                        _buildProfileCard(),
                        const SizedBox(height: 12),
                        _buildQuickStats(),
                        const SizedBox(height: 4),
                        _buildForm(),
                      ],
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
      expandedHeight: 56,
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      toolbarHeight: 56,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        color: Theme.of(context).colorScheme.surface,
        onPressed: salir,
      ),
      title: Text(
        _paginaActual == 0 ? 'Mi Perfil' : 'Área de Trabajo',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: img != null && img!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: img!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholderAvatar(),
                  )
                : _placeholderAvatar(),
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
                    Icon(Icons.location_on_rounded, size: 13, color: colorsecundario),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        worker.worker.isNotEmpty
                            ? (ciudad ?? worker.worker[0].city)
                            : (ciudad ?? 'Sin ciudad'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isworking ? const Color(0xFF10B981) : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isworking ? 'Activo' : 'Inactivo',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isworking
                      ? const Color(0xFF10B981)
                      : Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: colorsecundario.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.person_rounded, color: colorsecundario, size: 30),
    );
  }

  Widget _buildQuickStats() {
    if (worker.worker.isEmpty) return const SizedBox();
    final w = worker.worker[0];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _miniStat(
            Icons.attach_money_rounded,
            '\$${w.km_cost.toStringAsFixed(0)} MXN',
            'Tarifa visita',
          ),
          const SizedBox(width: 10),
          _miniStat(
            Icons.radar_rounded,
            '${w.range_km} km',
            'Radio de trabajo',
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Expanded(
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
            Column(
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
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return GestureDetector(
      onTap: () => _toggleWorking(!isworking),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isworking
              ? const Color(0xFF10B981).withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isworking
                ? const Color(0xFF10B981).withValues(alpha: 0.35)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isworking
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isworking
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isworking
                    ? const Color(0xFF10B981)
                    : Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isworking ? 'Disponible para trabajar' : 'No disponible',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isworking
                        ? 'Los clientes pueden verte y contactarte'
                        : 'Tu perfil no aparece en búsquedas',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isworking,
              onChanged: _toggleWorking,
              activeThumbColor: const Color(0xFF10B981),
              activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _PageHeader(String title, String subtitle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            height: 1.6,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 12,
            child: GestureDetector(
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
                          ),
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
                          ),
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
                          onPressed: () {
                            if (calle == null) {
                              Toast(
                                context,
                                title: 'Ubicación requerida',
                                message: 'Por favor selecciona tu ubicación',
                                type: alert_type.advertencia,
                              );
                              return;
                            }
                            setState(() {
                              _paginaActual--;
                            });
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
                              Text(
                                'Guardar y continuar',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorWhite,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
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

  Widget _buildForm() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAvailabilityToggle(),
            const SizedBox(height: 24),
            _buildSectionHeader(number: '1', title: 'Información laboral', subtitle: 'Cuéntanos sobre tu experiencia y servicios'),
            const SizedBox(height: 16),
            CustomDescriptionFormField(
              controller: _descriptionController,
              label: 'Descripción como trabajador',
              hint: 'Ej: Electricista con 5 años de experiencia...',
              minLines: 2,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Por favor agrega una descripción';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextFormFieldPrice(
              controller: _priceController,
              label: 'Tarifa por visita y diagnóstico',
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingresa el precio';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.tips_and_updates_outlined,
              text: 'Consejo: Investiga precios de servicios similares '
                  'en tu zona para ser competitivo.',
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(number: '2', title: 'Ubicación y rango de trabajo', subtitle: 'Define tu área de servicio y distancia máxima de desplazamiento'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorsecundario.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorsecundario.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con título y botón actualizar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ubicación',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                      ),
                      _buildRefreshButton(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Ubicación
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: colorsecundario,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          calle != null
                              ? '$calle, ${colonia ?? ''}, ${ciudad ?? ''}'
                              : 'No seleccionada',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Rango
                  Row(
                    children: [
                      Icon(
                        Icons.radar_rounded,
                        size: 16,
                        color: colorsecundario.withOpacity(0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Rango: ${_rangoKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _nextButton('Actualizar', () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              _Update();
            }),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _paginaActual++;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorsecundario,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              size: 14,
              color: colorWhite,
            ),
            const SizedBox(width: 6),
            Text(
              'Actualizar',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorsecundario.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorsecundario.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorsecundario.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
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
                  'Tu perfil laboral',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Esta informacion es visible para los clientes que te buscan',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
}
