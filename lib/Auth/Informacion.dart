import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Components/alert.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/WelcomePage.dart';
import 'package:gixt_worker/components/Indicador.dart';
import 'package:gixt_worker/components/inputs/Input.dart' hide OtpBoxclass;
import 'package:gixt_worker/components/inputs/Input_Description.dart';
import 'package:gixt_worker/components/inputs/Input_Fecha.dart';
import 'package:gixt_worker/components/inputs/Input_Password.dart';
import 'package:gixt_worker/components/inputs/Input_Phone.dart';
import 'package:gixt_worker/components/inputs/Input_Price.dart';
import 'package:gixt_worker/components/inputs/OtpBox.dart';
import 'package:gixt_worker/components/inputs/Pick_Image.dart';
import 'package:gixt_worker/routes/root.dart';
import 'package:gixt_worker/services/Auth/cuenta_service.dart';
import 'package:gixt_worker/services/Auth/info_service.dart';
import 'package:gixt_worker/services/Auth/validar.dart';
import 'package:gixt_worker/services/Location/Geolocation_service.dart';
import 'package:gixt_worker/services/Location/geocoding_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'dart:async';
import 'dart:io';

class CrearInfo extends StatefulWidget {
  const CrearInfo({super.key, required this.data});
  final Map<String, dynamic> data;
  @override
  State<CrearInfo> createState() => _CrearInfoState();
}

class _CrearInfoState extends State<CrearInfo> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  int _paginaActual = 0;

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

 Future<void> _saveToken(
    String token,
    String inicio,
    String id,
    String user,
    String img,
  ) async {
    await _preferencesService.savePreferences(token, inicio, id, img, user);

  }

  void _Create() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await InfoService.Crear(
      description: _descriptionController.text,
      city: ciudad!,
      latitude: latitude,
      longitude: longitude,
      labor_cost: double.parse(_priceController.text),
      range_km: _rangoKm,
    );

    Navigator.pop(context);

    if (result['success'] == true) {
      Future.microtask(() async {
        await _saveToken(
          widget.data['token'],
          "true",
          widget.data['id'].toString(),
          widget.data['username'],
          widget.data['img'],
        );
        await mostrarAlerta(
          context,
          title: "Bienvenido",
          message: 'Datos de trabajador creados correctamente',
          type: alert_type.exito,
        );
      }
      );
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomePage()),
      );
    } else {
      Future.microtask(() async {
        await mostrarAlerta(
          context,
          title: "Error",
          message: result['message'],
          type: alert_type.error,
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    marker();
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
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (_paginaActual != 0) _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 0,
                  ),
                  child: Column(
                    children: [
                      if (_paginaActual == 0) _buildwelcome(),
                      if (_paginaActual == 1) _buildMapa(),
                      if (_paginaActual == 2) _buildForm(),
                      const SizedBox(height: 20),
                      if (_paginaActual == 2) _buildDots(),
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

  Widget _buildwelcome() {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height,
      child: Stack(
        children: [
          // Imagen persona (hero)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.58,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Hero(
                tag: 'logo',
                child: Image.asset(
                  'assets/persona3.png',
                  width: size.width * 0.65,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Contenido inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      children: [
                        TextSpan(text: 'Hola, ${ widget.data['username']} '),
                        TextSpan(
                          text: 'Bienvenido',
                          style: TextStyle(color: colorsecundario),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '¡Bienvenido! Para comenzar a usar nuestra plataforma, por favor completa tus datos correctamente.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      height: 1.75,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDots(),
                      _circleNextButton(() {
                        _GoMyLocation();
                        setState(() {
                          _paginaActual++;
                        });
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleNextButton(VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: colorsecundario,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = _paginaActual == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? colorsecundario
                : Theme.of(context).colorScheme.surface.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: Theme.of(context).colorScheme.surface,
        onPressed: () {
          salir();
        },
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Crear Cuenta',
          style: GoogleFonts.poppins(
            fontSize: 25,
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
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        height: 1.6,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
      ),
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
              if (loadig == false)
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
                              mostrarAlerta(
                                context,
                                title: 'Ubicación requerida',
                                message: 'Por favor selecciona tu ubicación',
                                type: alert_type.advertencia,
                              );
                              return;
                            }
                            setState(() {
                              _paginaActual++;
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
                                'Siguiente',
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
            _PageHeader(
              'Tu perfil laboral',
              'Cuéntanos sobre ti como trabajador para que los clientes te encuentren.',
            ),
            const SizedBox(height: 10),
            _fieldLabel('Descripción como trabajador'),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            _fieldLabel(
              '¿Cuánto cobras solo por ir al domicilio dentro de tu rango?',
            ),
            const SizedBox(height: 10),
            CustomTextFormFieldPrice(
              controller: _priceController,
              label: 'Precio a proponer',
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingresa el precio';
                return null;
              },
            ),
            const SizedBox(height: 10),
            _fieldLabel('Ubicación y rango de trabajo'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Ubicación
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.45),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.8),
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
            const SizedBox(height: 90),
            _nextButton('Crear', () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              _Create();
            }),
          ],
        ),
      ),
    );
  }
}
