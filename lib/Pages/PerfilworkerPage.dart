import 'dart:io';
import 'dart:math';

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
import 'package:gixt_worker/components/Indicador.dart';
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

  Future<void> marker() async {
    const ImageConfiguration configuration = ImageConfiguration(
      size: Size(80, 80),
    );

    final BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
      configuration,
      "assets/marker.png",
    );

    if (mounted) {
      setState(() {
        markericon = icon;
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
    _Initial();
  }

  Future<void> _onRefresh() async {
    setState(() {
      print('Actualizando datos...');
      worker.updatedata();
      hasMore = true;
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
                      if (_paginaActual == 0) _buildForm(),
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
      expandedHeight: 50,
      pinned: true, //  deja solo la barra pequeña visible
      floating: false, //  NO aparece al subir
      snap: false, // NO animación automática
      elevation: 0,
      toolbarHeight: 50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: Theme.of(context).colorScheme.surface,
        onPressed: () {
          salir();
        },
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
            _buildSectionHeader(number: '1', title: 'Información laboral', subtitle: 'Cuéntanos sobre tu experiencia y servicios'),
            const SizedBox(height: 20),
            _fieldLabel('Descripción como trabajador'),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            _fieldLabel('Tarifa por visita y diagnóstico',),
            const SizedBox(height: 10),
            CustomTextFormFieldPrice(
              controller: _priceController,
              label: 'Precio a proponer',
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingresa el precio';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              icon: Icons.tips_and_updates_outlined,
              text:'Consejo: Investiga precios de servicios similares '
                  'en tu zona para ser competitivo.',
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(number: '2', title: 'Ubicacion y rango de trabajo', subtitle: 'Define tu área de servicio y distancia máxima de desplazamiento'),
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
