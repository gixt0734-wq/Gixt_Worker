import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
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
import 'package:gixt_worker/Components/Job/ActionsButton.dart';
import 'package:gixt_worker/Components/Job/BarStatus.dart';
import 'package:gixt_worker/Components/Job/Button.dart';
import 'package:gixt_worker/Components/Job/Client.dart';
import 'package:gixt_worker/Components/Job/DetailField.dart';
import 'package:gixt_worker/Components/Job/Extra.dart';
import 'package:gixt_worker/Components/Job/FieldLabelDescription.dart';
import 'package:gixt_worker/Components/Job/Image.dart';
import 'package:gixt_worker/Components/Job/InfoCard.dart';
import 'package:gixt_worker/Components/Job/InfoChip.dart';
import 'package:gixt_worker/Components/Job/OptionsButton.dart';
import 'package:gixt_worker/Components/Job/PaymentChip.dart';
import 'package:gixt_worker/Components/Job/PaymentMethodCard.dart';
import 'package:gixt_worker/Components/Job/PriceBreakdown.dart';
import 'package:gixt_worker/Components/Job/SectionCard.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/alert_bar.dart';
import 'package:gixt_worker/Components/inputs/Input_Price.dart';
import 'package:gixt_worker/Config/Notifiers/home_notifiers.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Config/location_cache_service.dart';
import 'package:gixt_worker/Pages/EvidenceJobPage.dart';
import 'package:gixt_worker/Pages/PayJobPage.dart';
import 'package:gixt_worker/Pages/Reports/AddReportPage.dart';
import 'package:gixt_worker/components/CircleImage.dart' show Circleimage;
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
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
import 'package:gixt_worker/services/Express/Cancel_Express_Service.dart';
import 'package:gixt_worker/services/Express/Express_Id_service.dart';
import 'package:gixt_worker/services/Express/Send_Propuesta_service.dart';
import 'package:gixt_worker/services/Express/Update_Express_service.dart';
import 'package:gixt_worker/services/Job/Update_Job_service.dart';
import 'package:gixt_worker/services/Location/Geolocation_service.dart';
import 'package:gixt_worker/services/Location/geocoding_helper.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'dart:io';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class ExpressPage extends StatefulWidget {
  const ExpressPage({super.key, required this.express_id});

  final String express_id;
  @override
  State<ExpressPage> createState() => _ExpressPageState();
}

class _ExpressPageState extends State<ExpressPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    // ⚡ El AnimationController del marcador se crea UNA sola vez y se reutiliza.
    // Antes se creaba/destruía uno por cada tick de GPS (con distanceFilter: 0,
    // eso eran muchísimos por minuto), lo que causaba jank y podía hacer
    // dispose() sobre un controller en pleno forward().
    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _markerCurve = CurvedAnimation(
      parent: _markerAnimController!,
      curve: Curves.easeInOut,
    );
    _markerAnimController!.addListener(_onMarkerTick);

    _initial();
    WidgetsBinding.instance.addObserver(this);

    expressNotifier.addListener(_onRefresh);
    cancelexpressNotifier.addListener(_cancelreload);
    finishexpressNotifier.addListener(_Refresh);

    FlutterBackgroundService().isRunning().then((running) {
      debugPrint("🔍 Servicio corriendo: $running");
    });

    _statusSub = FlutterBackgroundService().on("status").listen((event) {
      final state = event?["state"];
      final id = event?["id"];
      if (state == null || !mounted) return;

      // ⚠️ ANTES: el ViewAlertBar (efecto secundario / navegación de UI) se
      // ejecutaba DENTRO de setState. Eso es incorrecto: setState solo debe
      // mutar estado. Ahora el efecto va fuera y setState solo actualiza campos.
      if (state != 'enviando ubicación') {
        ViewAlertBar(
          context,
          title: state.toString(),
          isError: state == 'reconectando',
        );
      }
      setState(() {
        _gpsid = (id ?? '').toString();
        _StatusGps = state.toString();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    expressNotifier.removeListener(_onRefresh);
    cancelexpressNotifier.removeListener(_cancelreload);
    finishexpressNotifier.removeListener(_Refresh);

    _positionStreamSubscription?.cancel();
    _statusSub?.cancel();
    _timer?.cancel();

    _markerAnimController?.removeListener(_onMarkerTick);
    _markerAnimController?.stop();
    _markerAnimController?.dispose();

    _priceController.dispose();
    _scrollController.dispose();

    // ⚡ Notificadores aislados liberados.
    _workerPos.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // ⚡ ANTES: llamaba _initial() completo en cada resume (diálogo modal
        // bloqueante + re-ruteo + re-adquisición de GPS). Ahora solo refresca
        // datos y re-asegura el tracking, sin bloquear la pantalla.
        _onRefresh();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Segundo plano: mantenemos la conexión abierta.
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  // cache
  final PreferencesService _preferencesService = PreferencesService();

  // servicios
  final ExpressById_service express = ExpressById_service();
  String? motivoSeleccionado;

  // Datos que se mandan en el formulario
  double? _diagnostic_cost;
  final TextEditingController _priceController = TextEditingController();
  String _gpsid = '';

  // Datos del renderizado del mapa
  GoogleMapController? _mapController;
  List<LatLng> polylineCoordinates = [];

  // ⚡ `markers` ahora contiene SOLO el marcador del cliente (estático). El del
  // trabajador se dibuja aparte desde _workerPos para no reconstruir todo el
  // mapa en cada frame de la animación.
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  // ⚡ Animación del marcador del trabajador.
  AnimationController? _markerAnimController;
  Animation<double>? _markerCurve;
  LatLng _animFrom = const LatLng(20.9674, -89.5926);
  LatLng _animTo = const LatLng(20.9674, -89.5926);
  final ValueNotifier<LatLng?> _workerPos = ValueNotifier<LatLng?>(null);

  final _formKey = GlobalKey<FormState>();
  final LocationCacheService locationCache = LocationCacheService();

  // Controllers
  final ScrollController _scrollController = ScrollController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  //Inconos de marker mapa
  BitmapDescriptor markericon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor workericon = BitmapDescriptor.defaultMarker;

  // Variables de mapa
  String get _mapsKey => dotenv.env['MAPS_API_KEY'] ?? '';
  LatLng positionActual = const LatLng(20.9674, -89.5926);
  LatLng? positionclient = const LatLng(20.9674, -89.5926);
  LatLng? posicionAnterior;
  double longitude = 0;
  double latitude = 0;
  String? street;
  String? city;
  String? state;
  String? country;
  String? colonia;
  String distanceText = "";
  String durationText = "";
  bool isMantenimiento = false;

  Timer? _timer;
  // ⚡ El contador vive en un ValueNotifier: NO llama setState cada segundo.
  Duration _remaining = Duration.zero;
  DateTime? _countdownExpiresAt;

  // Estados de express
  bool isLoading = false;
  bool hasMore = true;
  bool isactive = false;
  bool isaccept = false;
  bool isSearch = false;
  bool timeout = false;
  bool loadig = true;
  bool _tracking = false;
  bool onlocation = false;
  String status = 'pending';
  String _StatusGps = 'desconocido';

  // Geolocalizacion
  HubConnection? hubConnection;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription? _statusSub;

  Future<void> _startTracking() async {
    // Guarda: sin datos cargados no podemos leer job_status.
    if (express.express.isEmpty) return;

    final excludedStatuses = [
      'pending',
      'canceled',
      'completed',
      'finalized',
      'rejected',
    ];

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
          if (!mounted) return;
          final nuevaPosicion = LatLng(position.latitude, position.longitude);
          final anterior = _workerPos.value ?? positionActual;

          // ⚡ Sin setState: la animación publica en _workerPos y solo el mapa
          // escucha.
          _animarMovimiento(anterior, nuevaPosicion);
        });

    if (_StatusGps == 'desconocido' &&
        !excludedStatuses.contains(express.express[0].job_status)) {
      if (mounted) setState(() => _tracking = true);
      await LocationService.start(widget.express_id);
    }
  }

  Future<void> _stopTracking() async {
    if (mounted) setState(() => _tracking = false);
    await LocationService.stop();
  }

  // ⚡ Tick de la animación: interpola y publica en el ValueNotifier. Sigue al
  // trabajador con moveCamera (no animateCamera, que pelearía frame a frame).
  void _onMarkerTick() {
    final t = _markerCurve!.value;
    final lat =
        _animFrom.latitude + (_animTo.latitude - _animFrom.latitude) * t;
    final lng =
        _animFrom.longitude + (_animTo.longitude - _animFrom.longitude) * t;
    final pos = LatLng(lat, lng);

    positionActual = pos; // origen para ruta/distancia
    _workerPos.value = pos; // solo el mapa escucha
    _mapController?.moveCamera(CameraUpdate.newLatLng(pos));
  }

  void _animarMovimiento(LatLng desde, LatLng hasta) {
    _animFrom = desde;
    _animTo = hasta;
    _markerAnimController!
      ..reset()
      ..forward();
  }

  Future<void> getDistanceAndTime() async {
    if (positionclient == null) return;
    final String url =
        "https://maps.googleapis.com/maps/api/distancematrix/json"
        "?origins=${positionActual.latitude},${positionActual.longitude}"
        "&destinations=${positionclient!.latitude},${positionclient!.longitude}"
        "&mode=driving"
        "&key=$_mapsKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final element = data["rows"][0]["elements"][0];

      String distance = element["distance"]["text"]; // km
      String duration = element["duration"]["text"]; // tiempo

      if (!mounted) return;
      setState(() {
        distanceText = distance;
        durationText = duration;
      });
    }
  }

  Future<void> GetRute() async {
    if (express.express.isEmpty) return;

    final position = await Geolocator.getCurrentPosition();

    final workerPos = LatLng(position.latitude, position.longitude);
    final clientPos = LatLng(
      express.express[0].latitude,
      express.express[0].longitude,
    );

    if (!mounted) return;

    positionActual = workerPos;
    positionclient = clientPos;
    latitude = position.latitude;
    longitude = position.longitude;

    // ⚡ Solo el marcador del CLIENTE va al set estático. El del trabajador se
    // publica en _workerPos y lo dibuja el ValueListenableBuilder del mapa.
    setState(() {
      markers = {
        Marker(
          markerId: const MarkerId("client"),
          position: clientPos,
          infoWindow: const InfoWindow(title: "Cliente"),
          icon: workericon,
        ),
      };
    });
    _workerPos.value = workerPos;

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
    if (positionclient == null) return;

    PolylinePoints polylinePoints = PolylinePoints(apiKey: _mapsKey);

    PolylineRequest request = PolylineRequest(
      origin: PointLatLng(positionActual.latitude, positionActual.longitude),
      destination: PointLatLng(
        positionclient!.latitude,
        positionclient!.longitude,
      ),
      mode: TravelMode.driving,
    );

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: request,
    );

    if (result.points.isNotEmpty) {
      polylineCoordinates
        ..clear()
        ..addAll(result.points.map((p) => LatLng(p.latitude, p.longitude)));
      if (!mounted) return;
      await createPolyline();
      await getDistanceAndTime();
      setState(() {});
    }
  }

  Future<void> createPolyline() async {
    polylines.add(
      Polyline(
        polylineId: const PolylineId("ruta"),
        points: polylineCoordinates,
        width: 5,
        color: colorsecundario,
      ),
    );
  }

  // Traer datos de ubicacion
  Future<void> _GoMyLocation({bool showLoader = true}) async {
    if (!mounted) return;

    if (showLoader) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Indicador(),
      );
    }

    try {
      Position pos = await GeoLocationService.obtenerUbicacion(context);
      latitude = pos.latitude;
      longitude = pos.longitude;

      setState(() {
        positionActual = LatLng(pos.latitude, pos.longitude);
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: positionActual, zoom: 17),
          ),
        );
      });
      
    } catch (e) {
      debugPrint('$e');
    }

    // ⚡ GetStreet fuera de setState (es async, no muta estado sincrónicamente).
    await GetStreet();
    GetRute();
    if (mounted) setState(() => loadig = false);
    if (showLoader && mounted) Navigator.pop(context);
  }

  Future<void> GetStreet() async {
    GeocodingHelper.obtenerCiudadDesdeCoordenadas(
      latitud: latitude,
      longitud: longitude,
      onResult:
          (ciudadResult, calleResult, estadoResult, paisResult, coloniaResult) {
            if (!mounted) return;
            setState(() {
              city = ciudadResult;
              street = calleResult;
              state = estadoResult;
              colonia = coloniaResult;
              country = paisResult;
            });
          },
    );
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

    workericon = await getMarkerIcon("assets/marker.png", w.toInt());
    markericon = await getMarkerIcon("assets/worker.png", w.toInt());

    if (mounted) {
      setState(() {
        markericon;
        workericon;
      });
    }
  }

  // Validacion inicial
  Future<void> _initial() async {
    if (locationCache.hasPosicion) {
      latitude = locationCache.latitud!;
      longitude = locationCache.longitud!;
      setState(() {
        positionActual = LatLng(latitude, longitude);
        positionclient = LatLng(latitude, longitude);
      });
      _workerPos.value = LatLng(latitude, longitude);
    }

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
      if (mounted) Navigator.pop(context);
      return;
    }
    if (!mounted) return;
    setState(() {
      isMantenimiento = express.express[0].type_category == 1;
    });

    // ⚡ En el arranque NO bloqueamos con el diálogo modal: ya tenemos la
    // posición del cache y GetRute vuelve a centrar con la real.
    await _GoMyLocation(showLoader: false);
    await marker();
    await GetRute();
    _startTracking();

    if (!mounted) return;
    setState(() {});
  }

  // Fetchs de datos
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
    setState(() {
      isMantenimiento = express.express[0].type_category == 1;
    });
    _startTracking();
  }

  void _Refresh() async {
    if (express.express.isNotEmpty &&
        express.express[0].images_evicence.isNotEmpty) {
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
        message: 'se cancelo el trabajo',
        type: alert_type.error,
      );
      if (mounted) Navigator.pop(context);
    });
  }

  void _startCountdown(DateTime expiresAt) {
    _timer?.cancel();
    _countdownExpiresAt = expiresAt;
    _remaining = expiresAt.difference(DateTime.now());

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final difference = expiresAt.difference(DateTime.now());

      if (difference.isNegative) {
        timer.cancel();
        setState(() {
          _remaining = Duration.zero;
        });
      } else {
        setState(() {
          _remaining = difference;
        });
      }
    });
  }

  String _formatTime(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = duration.isNegative ? Duration.zero : duration;
    return "${two(d.inHours)}:"
        "${two(d.inMinutes.remainder(60))}:"
        "${two(d.inSeconds.remainder(60))}";
  }

  // Funciones principales
  void _Send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_priceController.text.isEmpty) {
      Toast(
        context,
        title: 'Precio requerido',
        message: 'Ingresa el precio de los materiales',
        type: alert_type.error,
      );
      return;
    }
    if (_diagnostic_cost == null && isMantenimiento == false) {
      Toast(
        context,
        title: 'Selecciona un precio a tu diagnostico',
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

    final result = await SendPropuestaExpressService.Update(
      express_id: widget.express_id,
      diagnostic_cost: _diagnostic_cost,
      labor_price: _priceController.text,
    );

    if (mounted) Navigator.pop(context);

    if (result['success'] == true) {
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

  void _Cancelar() async {
    bool? ok = await ActionAlert(
      context,
      title: 'Cancelar solicitud',
      message:
          '¿Estás seguro de que deseas cancelar esta solicitud? Las cancelaciones frecuentes o injustificadas pueden generar sanciones en tu cuenta.',
      type: action_type.advertencia,
    );
    if (ok!) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Indicador(),
      );

      final result = await CancelExpressService.CancelExpress(
        express_id: widget.express_id,
        reason: motivoSeleccionado!,
      );

      if (mounted) Navigator.pop(context);
      if (mounted) Navigator.pop(context);
      if (result['success'] == true) {
        _cancelreload();
        homeNotifier.refresh();
        if (!mounted) return;
        if (mounted) Navigator.pop(context);
        Future.microtask(() async {
          await Toast(
            context,
            title: "Trabajo cancelado",
            message: "Trabajo cancelado exitosamente",
            type: alert_type.exito,
          );
        });
      } else {
        Toast(
          context,
          title: "Error",
          message: result['message'],
          type: alert_type.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (express.express.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Indicador(),
      );
    }
    final theme = Theme.of(context);
    return KeyboardDismisser(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // 🗺️ MAPA DE FONDO (aislado en su propio RepaintBoundary)
            Positioned.fill(child: RepaintBoundary(child: _buildMap())),

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
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
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
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final h = mq.size.height;

    return Stack(
      children: [
        // ── Mapa ──────────────────────────────────────────────────────────
        SizedBox(
          height: h,
          child: ValueListenableBuilder<LatLng?>(
            valueListenable: _workerPos,
            builder: (context, worker, _) {
              return GoogleMap(
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
                markers: {
                  ...markers, // cliente (estático)
                  if (worker != null)
                    Marker(
                      markerId: const MarkerId("worker"),
                      position: worker,
                      infoWindow: const InfoWindow(title: "Tu ubicación"),
                      icon: markericon,
                    ),
                },
              );
            },
          ),
        ),

        Positioned(
          top: mq.padding.top + 12,
          left: 12,
          right: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Botón atrás ───────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withValues(
                      alpha: 0.92,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 17,
                    color: theme.colorScheme.surface,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // ── Tarjeta "Ubicación seleccionada" ──────────────
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withValues(
                      alpha: 0.92,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                          Expanded(
                            child: Text(
                              'Ubicación seleccionada',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorsecundario,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${street} ${city} a ${express.express[0].maps_address}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.surface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (state != null || city != null)
                        Text(
                          "${distanceText} en ${durationText}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // ── Columna de botones ────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ir a mi ubicación
                  GestureDetector(
                    onTap: () => _GoMyLocation(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: colorsecundario,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Estado GPS
                  Gpsstatus(
                    status: _StatusGps,
                    is_active: _gpsid == express.express[0].express_id,
                  ),
                  const SizedBox(height: 8),

                  // Ir a ubicación del cliente
                  GestureDetector(
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
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_pin_circle_rounded,
                        color: Colors.deepOrange,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Abrir en Google Maps
                  GestureDetector(
                    onTap: () {
                      abrirGoogleMaps(
                        express.express[0].latitude,
                        express.express[0].longitude,
                      );
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colorsecundario,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_rounded,
                        color: colorWhite,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInformacion() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _buildTitle()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          const SizedBox(height: 10),
          _buildClient()
              .animate(delay: 550.ms)
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.15, curve: Curves.easeOutCubic),
          const SizedBox(height: 10),
          _buildTrabajo()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          const SizedBox(height: 10),
          _buildEvidence()
              .animate()
              .fade(duration: 450.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          const SizedBox(height: 10),
          _buildActionsSection()
              .animate()
              .fade(duration: 500.ms, delay: 60.ms)
              .slideX(begin: -0.2),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    final surface = Theme.of(context).colorScheme.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOLICITUD EXPRESS',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: colorsecundario,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          express.express[0].client_username,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: surface,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Barstatus(
          estadoTrabajo: express.express[0].job_status.isEmpty
              ? ''
              : express.express[0].job_status,
        ).animate().fade(duration: 450.ms, delay: 60.ms).slideX(begin: -0.2),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: double.infinity,
              child: InfoChip(
                icon: Icons.location_on_rounded,
                label:
                    (express.express[0].maps_address?.trim().isNotEmpty ??
                        false)
                    ? express.express[0].maps_address!
                    : 'Buscando ubicación...',
                color: colorsecundario,
              ),
            ),
            InfoChip(
              icon: Icons.calendar_month_rounded,
              label: express.express[0].job_date,
              color: Colors.transparent,
            ),
            InfoChip(
              icon: Icons.access_time_filled_rounded,
              label: express.express[0].job_time,
              color: Colors.transparent,
            ),
            InfoChip(
              icon: Icons.handyman_rounded,
              label: express.express[0].category.toUpperCase(),
              color: colorsecundario,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClient() {
    return ClientInfo(
      img: express.express[0].client_image,
      name: express.express[0].client_username,
      id: express.express[0].client_id,
    );
  }

  Widget _buildEvidence() {
    final evidence = express.express[0].images_evicence;
    final total = 1 + evidence.length;
    return SectionCard(
      title: 'Imágenes de evidencia',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colorsecundario.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$total foto${total != 1 ? 's' : ''}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorsecundario,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Imagen(
                  imagen: express.express[0].image!,
                  type: 'Cliente',
                  icon: Icons.person_rounded,
                )
                .animate()
                .fade(duration: 450.ms, delay: 60.ms)
                .slideX(begin: -0.2),
            const SizedBox(width: 20),
            for (final img in evidence) ...[
              Imagen(
                imagen: img!,
                type: 'Trabajador',
                icon: Icons.handyman_rounded,
              ),
              const SizedBox(width: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrabajo() {
    final problem = express.express[0].problem;
    final description = express.express[0].description;
    final expressdetails = express.express[0].listdetails;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Trabajo a realizar',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailField(label: 'Problema', value: problem),
              const SizedBox(height: 16),
              DetailField(label: 'Descripción', value: description),
            ],
          ),
        ),
        if (expressdetails.isNotEmpty) ...[
          const SizedBox(height: 10),
          SectionCard(
            title: 'Informacion extra',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var details in expressdetails) ...[
                  Extra(name: details.name, value: details.value),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        const InfoCard(
          icon: Icons.info_outline,
          text:
              'El precio mostrado corresponde a la mano de obra y de ir al domicilio; el costo final puede variar según los materiales necesarios.',
        ),
        if (express.express[0].job_status != 'pending') ...[
          const SizedBox(height: 10),
          _buildPriceBreakdown(),
        ],
        const SizedBox(height: 10),
        _buildPaymentMethodCard(),
      ],
    );
  }

  Widget _buildPriceBreakdown() {
    final labor = express.express[0].labor_cost;
    final diagnostic = express.express[0].diagnostic_cost;
    final materials = express.express[0].materials;
    final iva = express.express[0].labor;
    final total = express.express[0].total;

    return PriceBreakdown(
      labor: labor,
      diagnostic: diagnostic,
      materials: materials,
      iva: iva,
      total: total,
    );
  }

  Widget _bottomBar(BuildContext context) {
    final expressStatus = express.express[0].job_status.toLowerCase();
    final proposal = express.express[0].express_proposal;
    bool isproposal = proposal.length < 2;
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
        final proposals = express.express[0].express_proposal;
        if (proposals.length == 1) {
          final createdAt = DateTime.parse(proposals[0].created_at);
          print(createdAt);
          final expiresAt = createdAt.add(const Duration(minutes: 5));

          if (_countdownExpiresAt != expiresAt) {
            _startCountdown(expiresAt);
          }

          if (_remaining.inSeconds > 0) {
            icon = Icons.timer;
            text = "Espera ${_formatTime(_remaining)}";
            bgColor = Colors.grey;
            action = null;
          } else {
            icon = Icons.send_rounded;
            text = "Enviar propuesta";
            action = () {
              _showofferSheet();
            };
          }
        } else if (proposals.length >= 2) {
          icon = Icons.block;
          text = "Propuestas completas";
          bgColor = Colors.grey;
          action = null;
        } else {
          icon = Icons.hourglass_empty;
          text = "Enviar propuesta";
        }

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
        icon =  isMantenimiento ?  Icons.home_repair_service :Icons.search;
        text = isMantenimiento ? 'Empezar' :'Iniciar diagnóstico' ;
        action = () {
          if(isMantenimiento == true)
          {
            _Update(express.express[0].job_status);
          }
          else
          {
            _startTracking();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PayJobPage(
                  isExpress: true,
                  job_id: express.express[0].express_id,
                  price: express.express[0].labor,
                  km_priece: express.express[0].diagnostic_cost,
                  methodpayment: express.express[0].payment_method,
                ),
              ),
            );
          }
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

      case 'canceled':
      case 'rejected':
        icon = Icons.cancel_outlined;
        text = 'Cancelado';
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
      ),
      child: Button(bgColor: bgColor, text: text, icon: icon, action: action),
    );
  }

  void _showofferSheet() {
    int? selectedChipIndex;

    final basePrice = express.express[0].worker_price;
    final methodpayment = express.express[0].payment_method;
    final multipliers = [1.10, 1.20, 2, 3];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final surface = Theme.of(context).colorScheme.surface;
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
                    key: _formKey,
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
                              color: surface.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const FieldLabelDescription(
                          label: 'Enviar propuesta',
                          value:
                              'El cliente puede aceptar o rechazar tu propuesta antes de comenzar.',
                        ),
                        const SizedBox(height: 24),
                        if (isMantenimiento == false) ...[
                          Text(
                            'Tarifa de visita y diagnóstico',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: surface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(multipliers.length, (
                                index,
                              ) {
                                final value = basePrice * multipliers[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index == multipliers.length - 1
                                        ? 0
                                        : 10,
                                  ),
                                  child: PaymentChip(
                                    value: value,
                                    label: '\$${value.toStringAsFixed(0)}',
                                    icon: Icons.attach_money_rounded,
                                    isSelected: selectedChipIndex == index,
                                    onTap: () => setModalState(() {
                                      _diagnostic_cost = value;
                                      selectedChipIndex = index;
                                    }),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          'Tarifa de mano de obra',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: surface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextFormFieldPrice(
                          controller: _priceController,
                          label: '\$ 0.00',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa el precio';
                            }

                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Ingresa un precio válido';
                            }

                            if(price < 50) {
                              return 'El precio debe ser mayor o igual a \$50';
                            }

                            final minimumPrice = methodpayment == 'cash'
                                ? 2000
                                : 150000;

                            if (price > minimumPrice) {
                              return 'El precio debe ser menor o igual a \$${minimumPrice.toStringAsFixed(0)}';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Button(
                          text: 'Enviar propuesta',
                          icon: Icons.send_rounded,
                          bgColor: colorsecundario,
                          action: _Send,
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

  Widget _buildPaymentMethodCard() {
    return PaymentMethod(payment_method: express.express[0].payment_method);
  }

  Widget _buildActionsSection() {
    final status = express.express[0].job_status.toLowerCase();
    final bool canCancel = [
      'pending',
      'canceled',
      'finalized',
      'completed',
    ].contains(status);
    final bool canReport = [
      'canceled',
      'completed',
      'in_progress',
      'finalized',
    ].contains(status);

    if (canCancel && !canReport) return const SizedBox.shrink();

    return SectionCard(
      title: 'Acciones',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!canCancel)
            ActionsButton(
              text: 'Cuéntanos si algo salió mal',
              title: 'Cancelar solicitud',
              icon: Icons.cancel_rounded,
              action: _showcancelSheet,
              color: colorError,
            ),
          if (!canCancel && canReport) const SizedBox(height: 12),
          if (canReport)
            ActionsButton(
              text: 'Esta acción no se puede deshacer',
              title: 'Reportar un problema',
              icon: Icons.flag_rounded,
              action: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReportPage(
                      type: 'job',
                      id: widget.express_id,
                      user: "${express.express[0].problem}",
                      type_job: 'express',
                    ),
                  ),
                );
              },
              color: colorsecundario,
            ),
        ],
      ),
    );
  }

  void _showcancelSheet() {
    const List<String> motivos = [
      'No puedo acudir al servicio',
      'Tuve una emergencia personal',
      'El cliente no responde',
      'La ubicación es incorrecta',
      'No cuento con las herramientas necesarias',
      'Surgió un imprevisto',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final surface = Theme.of(context).colorScheme.surface;
            final bool habilitado = motivoSeleccionado != null;
            final mq = MediaQuery.of(context);
            final bool isCompact = mq.size.width < 360;

            return Padding(
              padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
              child: KeyboardDismisser(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 16 : 24,
                    8,
                    isCompact ? 16 : 24,
                    mq.padding.bottom + 20,
                  ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: surface.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const FieldLabelDescription(
                        label: '¿Por qué cancelas el servicio?',
                        value: 'Selecciona un motivo para continuar',
                      ),
                      const SizedBox(height: 20),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: motivos.map((motivo) {
                              final bool seleccionado =
                                  motivoSeleccionado == motivo;

                              return OptionsButton(
                                motivo: motivo,
                                seleccionado: seleccionado,
                                action: () {
                                  setModalState(() {
                                    motivoSeleccionado = motivo;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Button(
                        text: 'Cancelar servicio',
                        icon: Icons.send,
                        bgColor: colorsecundario,
                        action: habilitado
                            ? () {
                                _Cancelar();
                              }
                            : null,
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
}
