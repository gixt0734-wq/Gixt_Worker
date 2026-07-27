import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Auth/Documentos.dart';
import 'package:gixt_worker/Auth/Login.dart';
import 'package:gixt_worker/Components/Sketor/opciones.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/categoriasoption.dart';
import 'package:gixt_worker/Components/registro_loader.dart';
import 'package:gixt_worker/Config/SignalRService.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/WelcomePage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
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
import 'package:gixt_worker/services/Location/Geolocation_service.dart';
import 'package:gixt_worker/services/Location/geocoding_helper.dart';
import 'package:gixt_worker/services/servicios/categorias_service.dart';
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
  final Categorias_service category = Categorias_service();
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
  bool isLoading = false;
  bool hasMore = true;
  bool timeout = false;
  BitmapDescriptor markericon = BitmapDescriptor.defaultMarker;
  List<int?> _categoriaSeleccionada = [];
  List<File?> _images = [];

  final PreferencesService _preferencesService = PreferencesService();

  void initState() {
    super.initState();
    marker();
    print(widget.data);
    // 👇 SE EJECUTA AL ENTRAR A LA PÁGINA
    print("Entré a crear info de trabajador");
    _Initial();
  }

  void addcategory(int id) {
    if (_categoriaSeleccionada.contains(id)) {
      _categoriaSeleccionada.remove(id);
    } else {
      _categoriaSeleccionada.add(id);
    }
  }

  Future<void> _Initial() async {
    setState(() {
      isLoading = true;
      timeout = false;
    });
    bool okData = await category.updatedata();
    if (!okData) {
      if (!mounted) return;
      setState(() {});
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
      if (!mounted) return;
      if (isLoading) {
        setState(() {
          timeout = true;
        });
        print('terminando contador');
      }
    });
    if (!mounted) return;
    setState(() {
      if (category.categorias.isNotEmpty) {
        isLoading = false;
      }
    });
  }

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
    builder: (_) => RegistroLoader(
      onRun: () =>  InfoService.Crear(
      description: _descriptionController.text,
      city: ciudad!,
      latitude: latitude,
      longitude: longitude,
      labor_cost: double.parse(_priceController.text),
      range_km: _rangoKm,
      images: _images,
      cat: _categoriaSeleccionada,
      id: widget.data['id'],
    ),

      onSuccess: (result) async {

          await Toast(
            context,
            title: "Bienvenido",
            message: 'Datos de trabajador creados correctamente, ahora solo necesitamos que subas tus documentos para poder activar tu cuenta.',
            type: alert_type.exito,
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => CrearDocumentos(data: widget.data,)),  (route) => false,
          );
          return;
          }
    
     
    ),
  );
   
  }

  Future<void> _pickImage() async {
    final File? image = await pickAndCropImage(context);

    if (image != null) {
      setState(() {
        _images.add(image);
      });
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
                      if (_paginaActual == 3) _buildCategory(),
                      if (_paginaActual == 4) _buildEvidence(),
                      const SizedBox(height: 20),
                      if (_paginaActual != 0 && _paginaActual != 1) ...[
                        _buildDots(),
                        const SizedBox(height: 30),
                      ],
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
              top: size.height * 0.15,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: size.width * 0.82,
                  height: size.width * 0.82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorsecundario.withOpacity(0.18),
                        colorsecundario.withOpacity(0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      duration: 3200.ms,
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1.06, 1.06),
                      curve: Curves.easeInOut,
                    ),
              ),
            ),

            // Imagen persona (hero)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.58,
              child: Center(
                child: Hero(
                  tag: 'info',
                  child: Image.asset(
                    'assets/work.png',
                    width: size.width * 0.78,
                    fit: BoxFit.contain,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.06, end: 0, duration: 700.ms, curve: Curves.easeOutCubic),
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
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorsecundario.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.waving_hand_rounded,
                        color: colorsecundario,
                        size: 22,
                      ),
                    ),

                    const SizedBox(height: 18),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        children:  [
                          TextSpan(text: 'Hola, ${widget.data['username']} '),
                          TextSpan(
                            text: 'Bienvenido',
                            style: TextStyle(color: colorsecundario),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Ahora necesitamos recopilar tu información como trabajador. Completa los siguientes datos con información real y actualizada, ya que serán utilizados para crear tu perfil y asignarte trabajos que se ajusten a tus servicios y disponibilidad',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        height: 1.75,
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 0),
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
            ).animate()
              .fadeIn(duration: 700.ms, curve: Curves.easeOut)
              .slideY(begin: 0.06, end: 0, duration: 800.ms, curve: Curves.easeOutCubic),
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
      children: List.generate(5, (i) {
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
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Perfil Laboral',
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
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
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
            top: MediaQuery.of(context).padding.top + 12,
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
            top: MediaQuery.of(context).padding.top + 120,
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
                      _buildSectionHeader(
                        number: '1',
                        title: 'Rango de trabajo',
                        subtitle: 'selecciona tu rango de trabajo',
                      ),
                      const SizedBox(height: 16),
                      // ─── Título + valor del rango ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: 
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
                          )),
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
            _buildSectionHeader(
              number: '2',
              title: 'Tu perfil laboral',
              subtitle:
                  'Cuéntanos sobre ti como trabajador para que los clientes te encuentren.',
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 20),
            _buildInfoCard(
              icon: Icons.info_outline,
              text:
                  'El precio del diagnóstico y el rango debe estar relacionado, ya que esto te ayudará a proporcionar precios a futuros trabajos.',
            ),
            const SizedBox(height: 70),
            _nextButton('Siguiente', () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              setState(() {
                _Initial();
                _paginaActual++;
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 30),
          _nextButton('Siguiente', () {
            if (_categoriaSeleccionada.isEmpty) {
              Toast(
                context,
                title: 'Selecciona una categoría',
                message: 'Debes elegir al menos una categoría para continuar',
                type: alert_type.advertencia,
              );
              return;
            }
            setState(() => _paginaActual++);
          }),
        ],
      ),
    );
  }

  Widget _buildEvidence() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionHeader(
            number: '4',
            title: 'Tu portafolio de evidencia',
            subtitle: 'Sube tus evidencias de trabajos anteriores.',
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Text(
                'Imágenes ',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),

              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorsecundario.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_images.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorsecundario,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 30,
            runSpacing: 20,
            children: [
              imageBox(),

              for (File? img in _images) ...[
                SizedBox(
                  width: 150,
                  height: 170,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          img!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _images.remove(img);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 30),
          _nextButton('Crear', () {
            if (_images.isEmpty || _images.length < 1) {
              Toast(
                context,
                title: 'Sube evidencia',
                message: 'Debes  subir al menos una evidencia para continuar',
                type: alert_type.advertencia,
              );
              return;
            }
            _Create();
          }),
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

  Widget imageBox() {
    return GestureDetector(
      onTap: () => _pickImage(),
      child: SizedBox(
        width: 150,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.05),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.12),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 28,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
