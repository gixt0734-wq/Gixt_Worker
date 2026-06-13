import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Components/ActionAlert%20.dart';
import 'package:gixt_worker/Components/GpsStatus.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/alert_bar.dart';
import 'package:gixt_worker/Components/inputs/Input_Price.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/EvidenceJobPage.dart';
import 'package:gixt_worker/Pages/PayJobPage.dart';
import 'package:gixt_worker/components/BarStatus.dart';
import 'package:gixt_worker/components/CircleImage.dart' show Circleimage;
import 'package:gixt_worker/components/Indicador.dart';
import 'package:gixt_worker/components/inputs/Input_Description.dart';
import 'package:gixt_worker/components/inputs/Input_Time.dart';
import 'package:gixt_worker/components/inputs/UbicacionesInput.dart';
import 'package:gixt_worker/components/inputs/calendar_dialog.dart';
import 'package:gixt_worker/components/inputs/input.dart';
import 'package:gixt_worker/components/inputs/pick_image.dart';
import 'package:gixt_worker/components/inputs/time_picker_helper.dart';
import 'package:gixt_worker/components/sketor/opciones.dart';
import 'package:gixt_worker/Config/Notification.dart';
import 'package:gixt_worker/Config/Notifiers/express_notifiers.dart';
import 'package:gixt_worker/Config/location.dart';
import 'package:gixt_worker/main.dart';
import 'package:gixt_worker/routes/root.dart';
import 'package:gixt_worker/services/Job/Express_Id_service.dart';
import 'package:gixt_worker/services/Job/Send_Propuesta_service.dart';
import 'package:gixt_worker/services/Job/Update_Express_service%20copy.dart';
import 'package:gixt_worker/services/Job/Update_Job_service.dart';
import 'package:gixt_worker/services/Location/Geolocation_service.dart';
import 'package:gixt_worker/services/Location/geocoding_helper.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class ExpressPage extends StatefulWidget {
  const ExpressPage({super.key, required this.express_id});

  final String express_id;
  @override
  State<ExpressPage> createState() => _ExpressPageState();
}

class _ExpressPageState extends State<ExpressPage> with TickerProviderStateMixin {
  final ExpressById_service express = ExpressById_service();
  final ScrollController _scrollController = ScrollController();
  final PreferencesService _preferencesService = PreferencesService();

  bool isLoading = false;
  bool hasMore = true;

  bool isactive = false;
  bool isaccept = false;
  bool isSearch = false;
  bool timeout = false;
  bool loadig = true;

  bool _tracking = false;
  HubConnection? hubConnection;
  StreamSubscription<Position>? _positionStreamSubscription;
  GoogleMapController? _mapController;
  List<LatLng> polylineCoordinates = [];
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  AnimationController? _markerAnimController;

  LatLng? posicionAnterior;
  double longitude = 0;
  double latitude = 0;

  String? calle;
  String? ciudad;
  String? estado;
  String? pais;
  String distanceText = "";
  String durationText = "";

  String? colonia;
  LatLng positionActual = const LatLng(20.9674, -89.5926);
  LatLng? positionclient = LatLng(20.9674, -89.5926);

  BitmapDescriptor markericon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor workericon = BitmapDescriptor.defaultMarker;

  StreamSubscription? _statusSub;

  bool onlocation = false;
  String status = 'pending';
  double? _km_cost;
  TextEditingController _priceController = TextEditingController();

  String _StatusGps = 'desconocido';
  String get _mapsKey => dotenv.env['MAPS_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();

    marker();
    _initial();

    expressNotifier.addListener(_onRefresh);
    cancelexpressNotifier.addListener(_cancelreload);
    finishexpressNotifier.addListener(_Refresh);

    FlutterBackgroundService().isRunning().then((running) {
      print("🔍 Servicio corriendo: $running");
    });
    
    _statusSub = FlutterBackgroundService().on("status").listen((event) {
      final state = event?["state"];
      if (state != null && mounted) {
        setState(() {
          if (state != 'enviando ubicación') {
            if (!mounted) return;
            ViewAlertBar(
              context,
              title: state,
              isError: state == 'reconectando' ? true : false,
            );
          }

          _StatusGps = state;
        }); // o lo que quieras hacer con el estado
        print("✅ Status recibido: $state");
      }
    });
  }

  Future<void> _initial() async {
    bool ok = await express.fetchServicioData(widget.express_id);
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
      Navigator.pop(context);
    }

    await GetRute();
    await _GoMyLocation();
    _startTracking();
    setState(() {});
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(() {
      hasMore = true;
    });

    bool ok = await express.fetchServicioData(widget.express_id);

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
    if (!mounted) return;
    setState(() {});
    _startTracking();
  }

  void _Refresh() async {
    if (express.express[0].images_evicence.isNotEmpty) {
      _stopTracking();
    }
    _onRefresh();
  }

  Future<void> _cancelreload() async {
    await _stopTracking();
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    if (!mounted) return;
    Future.microtask(() async {
      await Toast(
        context,
        title: "Trabajo cancelado",
        message: 'se el usuario cancelo el trabajo',
        type: alert_type.error,
      );
      Navigator.pop(context);
    });
  }

  Future<void> _GoMyLocation() async {
    if (!mounted) return;

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
        positionActual = LatLng(pos.latitude, pos.longitude);
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: positionActual!, zoom: 17),
          ),
        );
      });
      await GetRoute();
    } catch (e) {
      print(e);
    }

    await GetStreet();
    if (mounted) setState(() => loadig = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> GetStreet() async {
    GeocodingHelper.obtenerCiudadDesdeCoordenadas(
      latitud: latitude,
      longitud: longitude,
      onResult:
          (ciudadResult, calleResult, estadoResult, paisResult, coloniaResult) {
            if (!mounted) return; 
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

  Future<void> getDistanceAndTime() async {
    final String url =
        "https://maps.googleapis.com/maps/api/distancematrix/json"
        "?origins=${positionActual!.latitude},${positionActual!.longitude}"
        "&destinations=${positionclient!.latitude},${positionclient!.longitude}"
        "&mode=driving"
        "&key=$_mapsKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final element = data["rows"][0]["elements"][0];

      String distance = element["distance"]["text"]; // km
      String duration = element["duration"]["text"]; // tiempo

      print("Distancia: $distance");
      print("Tiempo estimado: $duration");

      if (!mounted) return;

      setState(() {
        distanceText = distance;
        durationText = duration;
      });
    }
  }

  Future<void> GetRute() async {
    final position = await Geolocator.getCurrentPosition();

    final workerPos = LatLng(position.latitude, position.longitude);
    final clientPos = LatLng( express.express[0].latitude,express.express[0].longitude);

    if (!mounted) return;
    setState(() {
      positionActual = workerPos;
      positionclient = clientPos;

      latitude = position.latitude;
      longitude = position.longitude;

      /// MARCADOR WORKER
      markers.add(
        Marker(
          markerId: const MarkerId("worker"),
          position: workerPos,
          infoWindow: const InfoWindow(title: "Tu ubicación"),
          icon: markericon,
        ),
      );

      /// MARCADOR CLIENTE
      markers.add(
        Marker(
          markerId: const MarkerId("client"),
          position: clientPos,
          infoWindow: const InfoWindow(title: "Cliente"),
          icon: workericon,
        ),
      );
    });

    /// ajustar cámara para ver ambos puntos
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        min(workerPos.latitude, clientPos.latitude),
        min(workerPos.longitude, clientPos.longitude),
      ),
      northeast: LatLng(
        max(workerPos.latitude, clientPos.latitude),
        max(workerPos.longitude, clientPos.longitude),
      ),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));

    _startTracking();

    /// obtener dirección
    await GetStreet();

    /// dibujar ruta
    await GetRoute();
  }

  Future<void> GetRoute() async {
    PolylinePoints polylinePoints = PolylinePoints(
      apiKey: _mapsKey,
    );

    PolylineRequest request = PolylineRequest(
      origin: PointLatLng(positionActual!.latitude, positionActual!.longitude),
      destination: PointLatLng(positionclient!.latitude,positionclient!.longitude),
      mode: TravelMode.driving,
    );

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: request,
    );

    if (result.points.isNotEmpty) {
     polylineCoordinates
          ..clear()
          ..addAll(
            result.points.map((p) => LatLng(p.latitude, p.longitude)),
          );
      if (!mounted) return;
      await createPolyline();
      await getDistanceAndTime();
      setState(() {});
    }
  }

  Future<void> createPolyline() async {
    polylines.add(
      Polyline(
        polylineId: PolylineId("ruta"),
        points: polylineCoordinates,
        width: 5,
        color: colorsecundario,
      ),
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
    final BitmapDescriptor iconworker = await BitmapDescriptor.fromAssetImage(
      configuration,
      "assets/worker.png",
    );

    if (mounted) {
      setState(() {
        markericon = icon;
        workericon = iconworker;
      });
    }
  }

  void _Send() async {
    if (_priceController.text.isEmpty) {
      Toast(
        context,
        title: 'Precio requerido',
        message: 'Ingresa el precio de los materiales',
        type: alert_type.error,
      );
      return;
    }
    if (_km_cost == null) {
      Toast(
        context,
        title: 'Selecciona un precio',
        message: 'Selecciona una opcion',
        type: alert_type.error,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );
 
    final result = await SendPropuestaService.Update(
      express_id: widget.express_id,
      km_cost: _km_cost?.roundToDouble() ?? 0.0,
      labor_price: _priceController.text,
    );

    if (mounted) Navigator.pop(context);

    if (result['success'] == true) {
      final data = result['data'];
      if (!mounted) return;
      Toast(
        context,
        title: "Trabajo Actualizado",
        message: 'se notificara a tu cliente',
        type: alert_type.exito,
      );

      _priceController.clear();
      if (mounted) Navigator.pop(context);
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

  Future<void> _Update(String actions) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await UpdateExpressService.Update(
      action: actions,
      job_id: widget.express_id,
    );

    if (mounted) Navigator.pop(context);

    if (result['success'] == true) {
      final data = result['data'];
      Toast(
        context,
        title: "Trabajo Actualizado",
        message: 'se notificara a tu cliente',
        type: alert_type.exito,
      );
      _onRefresh();
      _startTracking();
    } else {
      Toast(
        context,
        title: "Error",
        message: result['message'],
        type: alert_type.error,
      );
    }
  }

  Future<void> _startTracking() async {
    final excludedStatuses = ['pending', 'canceled', 'completed', 'finalized'];

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ GPS apagado");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      print("❌ Permiso GPS bloqueado");

      return;
    }

    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
          ),
        ).listen((position) {
          if (!mounted) return; // ← CHECK MOUNTED PRIMERO
          final nuevaPosicion = LatLng(position.latitude, position.longitude);
          final anterior = positionActual; // ← guardar ANTES
          
          try {
            setState(() {
              
              positionActual = nuevaPosicion;
              _animarMovimiento(anterior, nuevaPosicion);
            });
          } catch (e) {
            print("Error: $e");
          }
        });
    if (_StatusGps == 'desconocido' &&
        !excludedStatuses.contains(express.express[0].job_status)) {
        if (mounted) setState(() => _tracking = true);
        await LocationService.start(widget.express_id);
    }
  }

  void _animarMovimiento(LatLng desde, LatLng hasta) {
    _markerAnimController?.dispose();

    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    final tween = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _markerAnimController!, curve: Curves.easeInOut),
    );

    _markerAnimController!.addListener(() {
      final t = tween.value;
      final lat = desde.latitude + (hasta.latitude - desde.latitude) * t;
      final lng = desde.longitude + (hasta.longitude - desde.longitude) * t;

      positionActual = LatLng(lat, lng);
      markers.removeWhere((m) => m.markerId.value == "worker");
      markers.add(
        Marker(
          markerId: const MarkerId("worker"),
          position: positionActual!,
          infoWindow: const InfoWindow(title: "Tu ubicación"),
          icon: markericon,
        ),
      );
      // Fuera del setState
      _mapController?.animateCamera(CameraUpdate.newLatLng(positionActual!));
      if (mounted) setState(() {});
    });

    _markerAnimController!.forward();
  }
  
  @override
  void dispose() {

    _positionStreamSubscription?.cancel();
    _markerAnimController?.stop();
    _markerAnimController?.dispose();
    super.dispose();
  }


  Future<void> _stopTracking() async {
    if (mounted) setState(() => _tracking = false);
    await LocationService.stop();
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.pop(context), // cerrar al tocar
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (express.express.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Indicador(),
      );
    }
    return KeyboardDismisser(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // 🗺️ MAPA DE FONDO
            Positioned.fill(child: _buildMap()),

            DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.40,
              maxChildSize: 0.92,
              expand: true,
              snap: true,
              snapSizes: const [0.45, 0.92],
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: _buildInformacion(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: _bottomBar(context),
      ),
    );
  }

  Widget _buildMap() {
    final h = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // ── Mapa ──────────────────────────────────────────────────────────
        SizedBox(
          height: h,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: positionActual,
              zoom: 16,
            ),
            scrollGesturesEnabled: !isSearch,
            rotateGesturesEnabled: true,
            zoomGesturesEnabled: !isSearch,
            tiltGesturesEnabled: !isactive,
            onMapCreated: (controller) => _mapController = controller,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            polylines: polylines,
            markers: markers,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 62,
          right: 12,
          child: Gpsstatus(status: _StatusGps), // 👈 una sola línea
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
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
          top: MediaQuery.of(context).padding.top + 110,
          right: 12,
          child: GestureDetector(
            onTap: () {
              if (positionclient != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: positionclient!, zoom: 17),
                  ),
                );
              }
            },
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
                Icons.person_pin_circle_rounded,
                color: Colors.deepOrange,
                size: 20,
              ),
            ),
          ),
        ),
        if (calle != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 64,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
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
                    "${calle} ${ciudad} a ${express.express[0].maps_address}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (estado != null || ciudad != null)
                    Text(
                      "${distanceText} en ${durationText}",
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
          ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.2),

        // 🔥 RADAR EN EL MAPA — solo cuando isactive
      ],
    );
  }

  Widget _buildInformacion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          SizedBox(height: 20),
          _buildTitle()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          SizedBox(height: 20),
          Barstatus(
                estadoTrabajo: express.express[0].job_status.isEmpty
                    ? ''
                    : express.express[0].job_status,
              )
              .animate()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          SizedBox(height: 20),
          _buildTrabajo()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          SizedBox(height: 20),
          _buildEvidence()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          image(
            express.express[0].image,
          ).animate().fade(duration: 450.ms, delay: 60.ms).slideX(begin: -0.2),
          SizedBox(height: 10),
          _buildClient()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 13, color: colorsecundario),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            express.express[0].maps_address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.event_outlined,
          size: 13,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.35),
        ),
        const SizedBox(width: 3),
        Text(
          express.express[0].job_date,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.access_time_outlined,
          size: 13,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.35),
        ),
        const SizedBox(width: 3),
        Text(
          express.express[0].job_time,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget imageBox(String? imagen) {
    return SizedBox(
      width: 130,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,

        children: [
          imagen == null
              ? Container(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 177, 177, 177),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  width: 200,
                  height: 200,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.person,
                    ), // Usa un icono de calendario
                    color: const Color.fromARGB(255, 255, 255, 255),
                    iconSize: 65,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(0, 103, 10, 10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  width: 200,
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: imagen!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: Container(color: Colors.white24)
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .shimmer(duration: 1200.ms)
                            .fade(begin: 0.4, end: 1),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildClient() {
    return Column(
      children: [
        SizedBox(height: 20),
        _fieldLabel('Información del cliente'),
        SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Circleimage(
                w: 56,
                h: 56,
                image_url: express.express[0].client_image,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            express.express[0].client_username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget image(String? imagen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Imagen de evidencia'),
        SizedBox(height: 20),
        SizedBox(
          width: 130,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              imagen == null
                  ? Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 177, 177, 177),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      width: double.infinity,
                      height: double.infinity,
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.person,
                        ), // Usa un icono de calendario
                        color: const Color.fromARGB(255, 255, 255, 255),
                        iconSize: 65,
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        _showFullImage(imagen);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(0, 103, 10, 10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        width: double.infinity,
                        height: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: imagen!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Center(child: Indicador()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEvidence() {
    final evidence = express.express[0].images_evicence;
    if (evidence.isEmpty) {
      return SizedBox.shrink();
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        _fieldLabel('Evidencias del trabajador'),
        SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for ( final img in evidence)...[
              imageBox(img),
              const SizedBox(width: 20),
              ]
            ],
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTrabajo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Problema a resolver'),
        SizedBox(height: 20),
        _fieldText(express.express[0].problem),
        SizedBox(height: 20),
        _fieldLabel('Descripción del trabajo'),
        SizedBox(height: 20),
        _fieldText(express.express[0].description),
        SizedBox(height: 20),
        _buildInfoCard(
          icon: Icons.info_outline,
          text:'El precio mostrado corresponde a la mano de obra y de ir al domicilio; el costo final puede variar según los materiales necesarios.',
        ),
        if (express.express[0].job_status != 'pending') ...[
          SizedBox(height: 20),
          _buildPrice(),
        ],
        SizedBox(height: 20),
        _buildPaymentMethodCard(),
      ],
    );
  }

  Widget _buildPrice() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Costos'),
        Column(
          children: [
            _buildPriceRow(
              'Precio estimado de Mano de obra',
              '\$${express.express[0].labor_cost.toStringAsFixed(2)}',
            ),
            _buildPriceRow(
              'Precio estimado de Materiales',
              '\$${express.express[0].materials.toStringAsFixed(2)}',
            ),
            _buildPriceRow(
              'Precio estimado de visita',
              '\$${express.express[0].km_cost.toStringAsFixed(2)}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    final expressStatus = express.express[0].job_status.toLowerCase();

    IconData icon = Icons.info;
    String text = '';
    VoidCallback? action;
    Color bgColor = colorsecundario;
    action = () async {
      print(express.express[0].job_status);
      if (express.express[0].job_status == 'pending') {
        // _Send();
        _showofferSheet();
        return;
      } else if (express.express[0].job_status != 'in_progress') {
        await _Update(express.express[0].job_status);
        _startTracking();
      } else if (express.express[0].job_status == 'in_progress') {
        if (express.express[0].images_evicence.isEmpty) {
          bool? ok = await ActionAlert(
            context,
            title: 'Evidencia',
            message:
                'Antes de finalizar manda tu evidencia que ya se termino el trabajo',
            type: action_type.advertencia,
          );
          if (ok!) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Evidencejobpage(
                  isExpress: true,
                  job_id: express.express[0].express_id,
                  price: express.express[0].labor_cost,
                  km_priece: express.express[0].km_cost,
                ),
              ),
            );

            return;
          }
        }
      }
    };
    switch (expressStatus) {
      case 'pending':
        icon = Icons.check_circle;
        text = 'Enviar Propuesta';
        break;

      case 'accepted':
        icon = Icons.delivery_dining_outlined;
        text = 'Estoy llendo';
        break;

      case 'going':
        icon = Icons.house_rounded;
        text = 'Ya llegue';
        break;

      case 'arrived':
        icon = Icons.search;
        text = 'Iniciar diagnóstico';
        action = () {
          _startTracking();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PayJobPage(
                isExpress: true,
                job_id: express.express[0].express_id,
                price: express.express[0].labor_cost,
                km_priece: express.express[0].km_cost,
              ),
            ),
          );
        };
        break;

      case 'diagnosing':
        icon = Icons.hourglass_top;
        text = 'Esperando aprobación';
        bgColor = Theme.of(context).colorScheme.surface.withOpacity(0.6);
        action = null;
        break;

      case 'in_progress':
        icon = Icons.home_repair_service;
        text = 'Finalizar';
        break;
      case 'finalized':
        icon = Icons.home_repair_service;
        text = 'Esperando Pago';
        action = null;
        break;
      case 'completed':
        icon = Icons.payment;
        text = 'Completado';
        action = null;
        break;

      default:
        icon = Icons.help;
        text = expressStatus;
        bgColor = Theme.of(context).colorScheme.surface.withOpacity(0.6);
    }

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: action,
          icon: Icon(icon, color: colorWhite, size: 25),
          label: Text(
            text,
            style: const TextStyle(fontSize: 18, color: colorWhite),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  void _showofferSheet() {
  // Estado local del sheet: índice del chip seleccionado
  int? selectedChipIndex;

  // Multiplicadores y su valor base
  final basePrice = express.express[0].worker_price;
  final multipliers = [1.10, 1.20, 2, 3];

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
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar centrado
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Propuesta de precio',
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.surface,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'este es el precio que le vas a proponer al cliente por tu visita y diagnóstico, el cliente puede aceptar o rechazar la propuesta',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _fieldLabel('Tarifa de visita y diagnóstico'),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(multipliers.length, (index) {
                          final value = basePrice * multipliers[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == multipliers.length - 1 ? 0 : 12,
                            ),
                            child: _paymentChip(
                              value: value,
                              label: value.toStringAsFixed(0),
                              icon: Icons.attach_money_rounded,
                              isSelected: selectedChipIndex == index,
                              onTap: () {
                                setModalState(() {
                                  _km_cost = value;
                                  selectedChipIndex = index;
                                });
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _fieldLabel('Tarifa de mano de obra'),
                    const SizedBox(height: 20),
                    CustomTextFormFieldPrice(
                      controller: _priceController,
                      label: '\$ 0.00',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el precio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Botones de acción
                    ElevatedButton(
                      onPressed: () {
                        _Send();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorsecundario,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Enviar propuesta',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
  
  Widget _buildPriceRow(String label, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.65),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
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
                fontSize: 12,
                height: 1.5,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentChip({
    required double value,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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

  Widget _buildPaymentMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),    
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.payments_rounded,
              color: Theme.of(context).scaffoldBackgroundColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Método de pago',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.money_rounded,
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(0.85),
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  '${express.express[0].payment_method == 'cash' ? 'Efectivo' : 'Tarjeta'} ',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: colorsecundario,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.surface,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldText(String text) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: 13,
        height: 1.6,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
      ),
    );
  }
}
