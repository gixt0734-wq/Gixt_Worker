import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Components/ActionAlert%20.dart';
import 'package:gixt_worker/Components/GpsStatus.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/alert_bar.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/EvidenceJobPage.dart';
import 'package:gixt_worker/Pages/PayjobPage.dart';
import 'package:gixt_worker/Pages/Reports/AddReportPage.dart';
import 'package:gixt_worker/components/BarStatus.dart';
import 'package:gixt_worker/components/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/config/location.dart';
import 'package:gixt_worker/services/Job/JonId_service.dart';
import 'package:gixt_worker/services/Job/Update_Job_service.dart';
import 'package:gixt_worker/services/Location/Geolocation_service.dart';
import 'package:gixt_worker/services/Location/geocoding_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewJobPage extends StatefulWidget {
  const ViewJobPage({super.key, required this.id_trabajo});
  final String id_trabajo;
  @override
  State<ViewJobPage> createState() => _ViewJobPageState();
}

class _ViewJobPageState extends State<ViewJobPage>  with TickerProviderStateMixin {
  bool isLoading = false;
  bool hasMore = true;
  final JobById_service job = JobById_service();
  final ScrollController _scrollController = ScrollController();
  final PreferencesService _preferencesService = PreferencesService();
  bool _tracking = false;
  bool _hubConnected = false;
  HubConnection? _hubConnection;
  double? _price;
  GoogleMapController? mapController;
  bool isactive = false;
  bool isaccept = false;
  bool isSearch = false;
  bool timeout = false;
  bool loadig = true;
  Set<Polyline> polylines = {};
  HubConnection? hubConnection;
  Set<Marker> markers = {};
  List<LatLng> polylineCoordinates = [];
  double longitude = 0;
  double latitude = 0;
  File? _image;
  String? calle;
  String? ciudad;
  String? estado;
  String? pais;
  String distanceText = "";
  String durationText = "";
  String? colonia;
  LatLng positionActual = const LatLng(20.9674, -89.5926);
  LatLng positionclient = LatLng(20.9674, -89.5926);
  bool onlocation = false;
  String status = 'pending';
  StreamSubscription<Position>? _positionStreamSubscription;
  BitmapDescriptor markericon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor workericon = BitmapDescriptor.defaultMarker;
  AnimationController? _markerAnimController;
  LatLng? posicionAnterior;
  StreamSubscription? _statusSub;
  String _StatusGps = 'desconocido';

  @override
  void initState() {
    super.initState();
    print("Entré a Mi trabajo");
    marker();
    _initial();
    jobsStatusNotifierFinish.addListener(_Refresh);
    jobsStatusNotifier.addListener(_Refresh);
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
    _startTracking();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  void _Refresh() async {
    print('nose');
    if (job.job[0].job_status == 'in_progress') {
      _stopTracking();
      _onRefresh();
    }
    _onRefresh();
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

  Future<void> _startTracking() async {
      final excludedStatuses = ['pending', 'canceled', 'completed', 'finalized','accepted'];

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
        !excludedStatuses.contains(job.job[0].job_status)) {
      setState(() {
        _tracking = true;
      });
      await LocationService.start(widget.id_trabajo);
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
      mapController?.animateCamera(CameraUpdate.newLatLng(positionActual!));
      if (mounted) setState(() {});
    });

    _markerAnimController!.forward();
  }

  Future<void> _stopTracking() async {
    await LocationService.stop();
  }

  Future<void> _initial() async {
    bool ok = await job.fetchServicioData(widget.id_trabajo);
    if (!ok) {
      if (!mounted) return;
      Future.microtask(() async {
        await Toast(
          context,
          title: "Error",
          message: "No se pudo obtener la información",
          type: alert_type.error,
        );

        Navigator.pop(context);
      });
    }
    GetRute();
    setState(() {});
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(() {
      print('Actualizando datos...');
      hasMore = true;
    });
    bool ok = await job.fetchServicioData(widget.id_trabajo);
    if (!ok) {
      if (!mounted) return;
      Future.microtask(() async {
        await Toast(
          context,
          title: "Error",
          message: "No se pudo obtener la información",
          type: alert_type.error,
        );

        Navigator.pop(context);
      });
    }
    setState(() {});
  }

  Future<void> abrirGoogleMaps(double lat, double lng) async {
    final Uri googleMapsUri = Uri.parse("geo:$lat,$lng?q=$lat,$lng");

    if (await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication)) {
      return;
    }

    final Uri webUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    if (!await launchUrl(webUrl, mode: LaunchMode.externalApplication)) {
      throw 'No se pudo abrir Google Maps';
    }
  }

  Future<void> _Update(String actions) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await UpdateJobsService.Update(
      action: actions,
      job_id: widget.id_trabajo,
    );

    Navigator.pop(context);

    if (result['success'] == true) {
      final data = result['data'];
      Toast(
        context,
        title: "Trabajo Actualizado",
        message: 'se notificara a tu cliente',
        type: alert_type.exito,
      );
      jobsStatusNotifier.refresh();
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
        positionActual = LatLng(pos.latitude, pos.longitude);
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: positionActual!, zoom: 17),
          ),
        );
      });
      
        GetRoute();
      
    } catch (e) {
      print(e);
    }

    await GetStreet();
    setState(() {
      loadig = false;
    });
    Navigator.pop(context);
  }

  Future<void> getDistanceAndTime() async {
    final String url =
        "https://maps.googleapis.com/maps/api/distancematrix/json"
        "?origins=${positionActual!.latitude},${positionActual!.longitude}"
        "&destinations=${positionclient!.latitude},${positionclient!.longitude}"
        "&mode=driving"
        "&key=AIzaSyD_Hw4Izij6u7r5lv0RqukDOfft6tExN64";

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
    final clientPos = LatLng(job.job[0].latitude, job.job[0].longitude);
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: clientPos, zoom: 17),
      ),
    );
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

    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));

    /// obtener dirección
    GetStreet();

    /// dibujar ruta
    await GetRoute();
  }

  Future<void> GetRoute() async {
    PolylinePoints polylinePoints = PolylinePoints(
      apiKey: "AIzaSyD_Hw4Izij6u7r5lv0RqukDOfft6tExN64",
    );

    PolylineRequest request = PolylineRequest(
      origin: PointLatLng(
        positionActual!.latitude,
        positionActual!.longitude,
      ),
      destination: PointLatLng(positionclient!.latitude, positionclient!.longitude),
      mode: TravelMode.driving,
    );

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: request,
    );

    if (result.points.isNotEmpty) {
      polylineCoordinates.clear();

      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
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
    if (job.job.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Indicador(),
      );
    }
    return KeyboardDismisser(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        floatingActionButton: ['canceled', 'completed','in_progress','finalized'].contains(job.job[0].job_status)? _buttonDelete(context) :null ,
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
                      top: Radius.circular(25),
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
    final topPadding = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        SizedBox(
          height: h,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: positionActual,
              zoom: 16,
            ),
            polylines: polylines,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: !isactive,
            onMapCreated: (controller) => mapController = controller,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            markers: markers,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 62,
          right: 12,
          child: Gpsstatus(status: _StatusGps), // 👈 una sola línea
        ),
        // botón mi ubicación
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
                mapController?.animateCamera(
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
        // chip de dirección
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
                    "${calle} ${ciudad} a ${job.job[0].maps_address}",
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),

        // Título: entrada protagónica desde arriba con scale sutil
        _buildTitle()
            .animate()
            .fadeIn(duration: 500.ms, curve: Curves.easeOut)
            .slideY(begin: -0.2, curve: Curves.easeOutCubic)
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: 20),

        // Status bar: entra "expandiéndose" horizontalmente — refuerza que es un indicador de progreso
        Barstatus(
          estadoTrabajo: job.job[0].job_status.isEmpty
              ? ''
              : job.job[0].job_status,
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 450.ms)
            .scaleX(
              begin: 0.7,
              end: 1,
              alignment: Alignment.centerLeft,
              curve: Curves.easeOutCubic,
              duration: 600.ms,
            ),

        const SizedBox(height: 20),

        // Bloque "Trabajo": desliza desde la izquierda
        _buildTrabajo()
            .animate(delay: 350.ms)
            .fadeIn(duration: 500.ms)
            .slideX(begin: -0.15, curve: Curves.easeOutCubic),

        // Evidence: desliza desde la derecha (efecto espejo con el anterior)
        _buildEvidence()
            .animate(delay: 450.ms)
            .fadeIn(duration: 500.ms)
            .slideX(begin: 0.15, curve: Curves.easeOutCubic),

        // Client: vuelve desde la izquierda (zigzag visual)
        _buildClient()
            .animate(delay: 550.ms)
            .fadeIn(duration: 500.ms)
            .slideX(begin: -0.15, curve: Curves.easeOutCubic),

        const SizedBox(height: 20),

        // Servicio: entrada con blur (cambio de "sección")
        _buildServicio()
            .animate(delay: 700.ms)
            .fadeIn(duration: 550.ms)
            .blurXY(begin: 6, end: 0, duration: 550.ms)
            .slideY(begin: 0.1, curve: Curves.easeOut),

        const SizedBox(height: 20),

        // Imagen: scale + fade (protagonismo visual)
        _buildImg()
            .animate(delay: 850.ms)
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.88, 0.88),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
              duration: 700.ms,
            ),

        const SizedBox(height: 20),

        // Ubicación: sube desde abajo (cierre natural de la lista)
        _buildUbicacion()
            .animate(delay: 1000.ms)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.25, curve: Curves.easeOutCubic),

        const SizedBox(height: 20),
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
            job.job[0].maps_address,
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
          job.job[0].job_date,
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
          job.job[0].job_time,
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
                  width: double.infinity,
                  height: double.infinity,
                  child: Icon(Icons.person, color: Colors.white, size: 65),
                )
              : GestureDetector(
                  onTap: () {
                    _showFullImage(imagen);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    width: double.infinity,
                    height: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: imagen,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.white24),
                      ),
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
        _fieldLabel('Cliente'),
        SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Circleimage(w: 56, h: 56, image_url: job.job[0].client_image),
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
                            job.job[0].client_username,
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

               GestureDetector(
            onTap: () {
               Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddReportPage(type: 'client', id: job.job[0].client_id,user: "${job.job[0].client_username}".trim(),type_job: null,),
              ));
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorError,
                borderRadius: BorderRadius.circular(50),
               
              ),
              child: Icon(
                Icons.report_outlined,
                color: colorWhite,
                size: 20,
              ),
            ),
          ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicio() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Servicio solicitado:   ${job.job[0].service_name}'),
        const SizedBox(height: 20),
        _fieldText(job.job[0].service_description),
      ],
    );
  }

  Widget _buildTrabajo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Problema descrito por el cliente'),
        SizedBox(height: 20),
        _fieldText(job.job[0].problem),
        SizedBox(height: 20),
        _fieldLabel('Descripción del trabajo'),
        SizedBox(height: 20),
        _fieldText(job.job[0].description),
        SizedBox(height: 20),
        _fieldLabel('Pago y método de pago'),
        SizedBox(height: 20),
        Column(
          children: [
            _buildPriceRow('Mano de obra', '\$${job.job[0].labor_cost}'),
            _buildPriceRow(
              'Precio estimado de visita ',
              '\$${job.job[0].km_cost}',
            ),
             _buildPriceRow(
              'Precio estimado de materiales',
              '\$${job.job[0].materials_cost > 0 ? job.job[0].materials_cost : '0.0'}',
            ),
          ],
        ),
        SizedBox(height: 20),
        _buildPaymentMethodCard(),
      ],
    );
  }

  Widget _buildUbicacion() {
    return Column(
      children: [
        _fieldLabel('Ubicación del trabajo'),
        SizedBox(height: 20),
        Row(
          children: [
            imageBox(job.job[0].location_image),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${job.job[0].maps_address}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.75,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    '${job.job[0].state} ${job.job[0].neighborhood} ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.75,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.55),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => abrirGoogleMaps(
                        job.job[0].latitude,
                        job.job[0].longitude,
                      ),
                      icon: const Icon(
                        Icons.directions_rounded,
                        color: colorWhite,
                      ),
                      label: Text(
                        'Cómo llegar',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorWhite,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorsecundario,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ],
    );
  }

  Widget _buildImg() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Imagenes del cliente'),
        SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              imageBox(job.job[0].image_1),
              const SizedBox(width: 20),
              imageBox(job.job[0].image_2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEvidence() {
    if (job.job[0].images_evicence.isEmpty) {
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
              imageBox(job.job[0].images_evicence[0]),
              const SizedBox(width: 20),
              imageBox(job.job[0].images_evicence[1]),
              const SizedBox(width: 10),
            ],
          ),
        ),
        SizedBox(height: 20),
      ],
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
              Expanded(child: 
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.65),
                ),
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
 
  Widget _buildPaymentMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
        ),
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
          Expanded(child: 
          Text(
            'Método de pago',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
            ),
          )),
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
                  '${job.job[0].payment_method == 'cash' ? 'Efectivo' : 'Tarjeta'} ',
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

  Widget _bottomBar(BuildContext context) {
    final jobStatus = job.job[0].job_status.toLowerCase();

    IconData icon = Icons.info;
    String text = '';
    VoidCallback? action;
    Color bgColor = colorsecundario;
    action = () async {
      print(job.job[0].job_status);

     if (job.job[0].job_status == 'in_progress') {
        if (job.job[0].images_evicence.isEmpty) {
          bool? ok = await ActionAlert(
            context,
            title: 'Evidencia requerida',
            message:
                'Antes de finalizar, envía la evidencia de que el trabajo ya fue terminado.',
            type: action_type.advertencia,
          );
          if (ok!) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Evidencejobpage(
                  isExpress: false,
                  job_id: job.job[0].job_id,
                  price: job.job[0].labor_cost,
                  km_priece: job.job[0].km_cost,
                ),
              ),
            );
            return;
          }
        }
        
      } else if (job.job[0].job_status != 'in_progress') {
        await _Update(job.job[0].job_status);
        _startTracking();
      }
    };
    switch (jobStatus) {
      case 'pending':
        icon = Icons.check_circle_outline;
        text = 'Aceptar trabajo';
        break;

      case 'accepted':
        icon = Icons.directions_bike;
        text = 'Voy en camino';
        break;

      case 'going':
        icon = Icons.location_on_outlined;
        text = 'Ya llegué';
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
              isExpress: false,
              job_id: job.job[0].job_id,
              price: job.job[0].labor_cost,
              km_priece: job.job[0].km_cost,
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
        icon = Icons.task_alt;
        text = 'Finalizar trabajo';
        break;
      case 'finalized':
        icon = Icons.schedule;
        text = 'Esperando pago';
        action = null;
        break;
      case 'completed':
        icon = Icons.verified;
        text = 'Trabajo completado';
        action = null;
        break;

      default:
        icon = Icons.help_outline;
        text = jobStatus;
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

 Widget _buttonDelete(BuildContext context) {
  
    return FloatingActionButton(
      onPressed: () {
         Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddReportPage(type: 'job', id: widget.id_trabajo,user: "${job.job[0].problem}" ,type_job: 'job',),
              ));
      },
      backgroundColor: colorError,
      elevation: 6,
      child: const Icon(
        Icons.report,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}