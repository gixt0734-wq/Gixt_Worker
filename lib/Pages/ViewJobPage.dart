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
import 'package:gixt_worker/Components/GpsStatus.dart';
import 'package:gixt_worker/Components/alert_bar.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/EvidenceJobPage.dart';
import 'package:gixt_worker/Pages/PayjobPage.dart';
import 'package:gixt_worker/components/BarStatus.dart';
import 'package:gixt_worker/components/Indicador.dart';
import 'package:gixt_worker/components/alert.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/config/location.dart';
import 'package:gixt_worker/services/Job/JonId_service.dart';
import 'package:gixt_worker/services/Job/Update_Job_service.dart';
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

class _ViewJobPageState extends State<ViewJobPage> {
  bool isLoading = false;
  bool hasMore = true;
  final JobById_service job = JobById_service();
  final ScrollController _scrollController = ScrollController();
  final PreferencesService _preferencesService = PreferencesService();
  bool _tracking = false;
  bool _hubConnected = false;
  HubConnection? _hubConnection;
  double? _price;
  GoogleMapController? _mapController;
  bool isactive = false;
  bool isaccept = false;
  bool isSearch = false;
  bool timeout = false;
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
  BitmapDescriptor markericon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor workericon = BitmapDescriptor.defaultMarker;
  final String hubUrl = "${dotenv.env['API_URL']}/gpsHub";
  StreamSubscription? _statusSub;
  String _StatusGps = 'desconocido';

  @override
  void initState() {
    super.initState();
    print("Entré a Mi trabajo");
    marker();
    _initial();
    jobsStatusNotifierFinish.addListener(_Refresh);
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

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  void _Refresh() async {
    if (job.job[0].images_evicence.isEmpty) {
      _onRefresh();
      return;
    }
    _Update(job.job[0].job_status);
    _stopTracking();
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
    setState(() {
      _tracking = true;
    });
    await LocationService.start(widget.id_trabajo);
  }

  Future<void> _stopTracking() async {
    setState(() {
      _tracking = false;
    });
    await LocationService.stop();
  }

  Future<void> _initial() async {
    bool ok = await job.fetchServicioData(widget.id_trabajo);
    if (!ok) {
      if (!mounted) return;
      Future.microtask(() async {
        await mostrarAlerta(
          context,
          title: "Error",
          message: "No se pudo obtener la información",
          type: alert_type.error,
        );

        Navigator.pop(context);
      });
    }
    rute();
    setState(() {});
  }

  Future<void> _onRefresh() async {
    setState(() {
      print('Actualizando datos...');
      hasMore = true;
    });
    bool ok = await job.fetchServicioData(widget.id_trabajo);
    if (!ok) {
      if (!mounted) return;
      Future.microtask(() async {
        await mostrarAlerta(
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

  void _Update(String actions) async {
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
      mostrarAlerta(
        context,
        title: "Trabajo Actualizado",
        message: 'se notificara a tu cliente',
        type: alert_type.exito,
      );
      jobsStatusNotifier.refresh();
      _onRefresh();
    } else {
      mostrarAlerta(
        context,
        title: "Error",
        message: result['message'],
        type: alert_type.error,
      );
    }
  }

  void getcalle() {
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

  Future<void> _irAMiUbicacion() async {
    final position = await Geolocator.getCurrentPosition();
    final nuevaPos = LatLng(position.latitude, position.longitude);
    setState(() {
      positionActual = nuevaPos;
      latitude = position.latitude;
      longitude = position.longitude;
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: nuevaPos, zoom: 17),
      ),
    );
    getcalle();
  }

  Future<void> getDistanceAndTime() async {
    final String url =
        "https://maps.googleapis.com/maps/api/distancematrix/json"
        "?origins=${positionActual!.latitude},${positionActual!.longitude}"
        "&destinations=${positionclient!.latitude},${positionclient!.longitude}"
        "&mode=driving"
        "&key=AIzaSyAjcb5WA1kNYLE5Gchmx1sNnpZM31vzXF8";

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

  Future<void> rute() async {
    final position = await Geolocator.getCurrentPosition();

    final workerPos = LatLng(position.latitude, position.longitude);
    final clientPos = LatLng(job.job[0].latitude, job.job[0].longitude);
    _mapController?.animateCamera(
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

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));

    /// obtener dirección
    getcalle();

    /// dibujar ruta
    await getRoute();
  }

  Future<void> getRoute() async {
    PolylinePoints polylinePoints = PolylinePoints(
      apiKey: "AIzaSyAjcb5WA1kNYLE5Gchmx1sNnpZM31vzXF8",
    );

    PolylineRequest request = PolylineRequest(
      origin: PointLatLng(positionclient!.latitude, positionclient!.longitude),
      destination: PointLatLng(
        positionActual!.latitude,
        positionActual!.longitude,
      ),
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
            onMapCreated: (controller) => _mapController = controller,
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
            onTap: _irAMiUbicacion,
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
        // chip de dirección
        if (calle != null)
          Positioned(
            top: topPadding + 12,
            left: 12,
            right: 64,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: colorsecundario,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${calle} ${ciudad} a ${job.job[0].maps_address}",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.surface,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        Text(
                          "${distanceText} en ${durationText}",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.5),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
          SizedBox(height: 20),
          _buildTitle()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          SizedBox(height: 20),
          Barstatus(
                estadoTrabajo: job.job[0].job_status.isEmpty
                    ? ''
                    : job.job[0].job_status,
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
          _buildEvidence()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          _buildClient()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          SizedBox(height: 20),
          _buildServicio()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          SizedBox(height: 20),
          _buildImg()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          SizedBox(height: 20),
          _buildUbicacion()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          SizedBox(height: 20),
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
      width: 100,
      height: 130,
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
                      placeholder: (context, url) => Center(child: Indicador()),
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
        Row(
          children: [
            SizedBox(height: 20),
            Text(
              'Cliente',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.surface,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
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
        Text(
          'Servicio solicitado:   ${job.job[0].service_name}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 10),
        Text(
          '${job.job[0].service_description}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.75,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildTrabajo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Problema a resolver',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 10),
        Text(
          '${job.job[0].problem}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.75,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
          ),
        ),

        SizedBox(height: 20),
        Text(
          'Descripción',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 10),
        Text(
          '${job.job[0].description}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.75,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
          ),
        ),
        SizedBox(height: 20),

        Text(
          'Pago y Metodo',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.2,
          ),
        ),

        SizedBox(height: 20),
        Column(
          children: [
            _buildPriceRow('Mano de obra', '\$${job.job[0].price}'),
            _buildPriceRow(
              'Precio estimado de visita ',
              '\$${job.job[0].km_cost}',
            ),
            _buildPriceRow(
              'Metodo de pago',
              '${job.job[0].payment_method == 'card' ? 'Tarjeta' : 'Efectivo'}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUbicacion() {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(height: 20),
            Text(
              'Ubicacion',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.surface,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
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
        Row(
          children: [
            SizedBox(height: 20),
            Text(
              'Imagenes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.surface,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              imageBox(job.job[0].image_1),
              const SizedBox(width: 20),
              imageBox(job.job[0].image_2),
              const SizedBox(width: 10),
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
        Row(
          children: [
            SizedBox(height: 20),
            Expanded(
              child: Text(
                'Evidencias proporcionadas por el trabajador',
                maxLines: 2,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildButton() {
    final jobStatus = job.job[0].job_status.toLowerCase();

    IconData icon = Icons.info;
    String text = '';
    VoidCallback? action;
    Color bgColor = colorsecundario;
    action = () {
      _Update(job.job[0].job_status);
      if (job.job[0].job_status == 'accepted') {
        _startTracking();
      }
      if (job.job[0].job_status == 'in_progress') {
        _stopTracking();
      }
    };
    switch (jobStatus) {
      case 'pending':
        icon = Icons.check_circle;
        text = 'Aceptar';
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
        icon = Icons.home_repair_service;
        text = 'Empezar';
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
        text = jobStatus;
        bgColor = Theme.of(context).colorScheme.surface.withOpacity(0.6);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
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
        if (_tracking) ...[
          SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              backgroundColor: !_tracking ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {},
            child: Icon(
              _tracking ? Icons.location_off : Icons.location_on,
              size: 28,
              color: Colors.white,
            ),
          ),
        ],
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
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.65),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
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

  Widget _bottomBar(BuildContext context) {
    final jobStatus = job.job[0].job_status.toLowerCase();

    IconData icon = Icons.info;
    String text = '';
    VoidCallback? action;
    Color bgColor = colorsecundario;
    action = () async {
      print(job.job[0].job_status);
      if (job.job[0].job_status != 'in_progress') {
        _Update(job.job[0].job_status);
      }
      if (job.job[0].job_status == 'accepted') {
        _startTracking();
      }
      if (job.job[0].job_status == 'in_progress') {
        if (job.job[0].images_evicence.isEmpty) {
          bool? ok = await mostrarAlerta(
            context,
            title: 'Evidencia',
            message:
                'Antes de finalizar manda tu evidencia que ya se termino el trabajo',
            type: alert_type.advertencia,
          );
          if (ok!) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Evidencejobpage(
                  job_id: job.job[0].job_id,
                  price: job.job[0].price,
                  km_priece: job.job[0].km_cost,
                ),
              ),
            );

            return;
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayJobPage(
              job_id: job.job[0].job_id,
              price: job.job[0].price,
              km_priece: job.job[0].km_cost,
            ),
          ),
        );
      }
    };
    switch (jobStatus) {
      case 'pending':
        icon = Icons.check_circle;
        text = 'Aceptar';
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
        icon = Icons.home_repair_service;
        text = 'Empezar';
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
}
