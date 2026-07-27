import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Cámara personalizada para capturar la INE.
/// Muestra el marco guía DENTRO de la cámara en vivo, recorta la foto
/// al área del marco y devuelve el File por Navigator.pop.
///
/// Uso:
///   final File? foto = await Navigator.push<File>(
///     context,
///     MaterialPageRoute(builder: (_) => CamaraInePage(titulo: 'Parte frontal de tu INE')),
///   );
class CamaraInePage extends StatefulWidget {
  const CamaraInePage({super.key, required this.titulo});

  /// Texto que se muestra arriba del marco (ej. "Parte frontal de tu INE")
  final String titulo;

  @override
  State<CamaraInePage> createState() => _CamaraInePageState();
}

class _CamaraInePageState extends State<CamaraInePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;

  bool _flashEncendido = false;
  bool _capturando = false;
  String? _error;

  /// Foto ya recortada esperando confirmación
  File? _fotoCapturada;

  // Proporción de una credencial (ISO ID-1): 85.6 x 53.98 mm
  static const double _ratioIne = 85.6 / 53.98;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamara();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamara();
    }
  }

  // pubspec.yaml → permission_handler: ^11.3.1

Future<void> _initCamara() async {
  try {
    // 1. Pedir permiso de cámara explícitamente
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _error =
          'Permiso de cámara denegado. Actívalo en los ajustes del teléfono.');
      return;
    }

    // 2. Buscar cámaras disponibles
    final camaras = await availableCameras();
    print('📷 Cámaras encontradas: $camaras');

    if (camaras.isEmpty) {
      setState(() => _error = 'No se encontró ninguna cámara en el dispositivo.');
      return;
    }

    final trasera = camaras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => camaras.first,
    );

    final controller = CameraController(
      trasera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;
    _initFuture = controller.initialize().then((_) async {
      await controller.setFlashMode(FlashMode.off);
      if (mounted) setState(() {});
    }).catchError((e) {
      print('❌ Error al inicializar: $e');
      if (mounted) setState(() => _error = 'Error al inicializar: $e');
    });
    setState(() {});
  } on CameraException catch (e) {
    print('❌ CameraException: ${e.code} - ${e.description}');
    setState(() => _error = 'CameraException: ${e.code}\n${e.description}');
  } catch (e, st) {
    print('❌ Error cámara: $e\n$st');
    setState(() => _error = 'Error: $e');
  }
}

  /// Rectángulo del marco guía sobre la pantalla
  Rect _marco(Size size) {
    final double ancho = size.width * 0.88;
    final double alto = ancho / _ratioIne;
    final double left = (size.width - ancho) / 2;
    // Un poco arriba del centro para dejar espacio al botón de captura
    final double top = (size.height - alto) / 2 - size.height * 0.06;
    return Rect.fromLTWH(left, top, ancho, alto);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    _flashEncendido = !_flashEncendido;
    await controller.setFlashMode(
      _flashEncendido ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<void> _tomarFoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturando) {
      return;
    }

    setState(() => _capturando = true);

    try {
      final XFile xfile = await controller.takePicture();
      final File recortada = await _recortarAlMarco(File(xfile.path));

      if (!mounted) return;
      setState(() {
        _fotoCapturada = recortada;
        _capturando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _capturando = false);
    }
  }

  /// Recorta la foto capturada al área del marco guía.
  /// La preview se muestra con "cover" centrado, así que se mapea
  /// el rect de pantalla a coordenadas de la imagen real.
  Future<File> _recortarAlMarco(File original) async {
    final bytes = await original.readAsBytes();
    final decodificada = img.decodeImage(bytes);
    if (decodificada == null) return original;

    // Corrige la rotación EXIF (las cámaras suelen guardar rotado)
    final imagen = img.bakeOrientation(decodificada);

    final Size pantalla = MediaQuery.of(context).size;
    final Rect marco = _marco(pantalla);

    // Escala tipo BoxFit.cover
    final double escala = math.max(
      imagen.width / pantalla.width,
      imagen.height / pantalla.height,
    );

    // Área de la imagen que realmente se ve en pantalla (centrada)
    final double offsetX = (imagen.width - pantalla.width * escala) / 2;
    final double offsetY = (imagen.height - pantalla.height * escala) / 2;

    int x = (offsetX + marco.left * escala).round();
    int y = (offsetY + marco.top * escala).round();
    int w = (marco.width * escala).round();
    int h = (marco.height * escala).round();

    // Asegura que el recorte quede dentro de la imagen
    x = x.clamp(0, imagen.width - 1);
    y = y.clamp(0, imagen.height - 1);
    w = w.clamp(1, imagen.width - x);
    h = h.clamp(1, imagen.height - y);

    final recorte = img.copyCrop(imagen, x: x, y: y, width: w, height: h);

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/ine_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final archivo = File(path);
    await archivo.writeAsBytes(img.encodeJpg(recorte, quality: 92));
    return archivo;
  }

  void _repetir() {
    setState(() => _fotoCapturada = null);
  }

  void _usarFoto() {
    Navigator.pop(context, _fotoCapturada);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null
          ? _buildError()
          : _fotoCapturada != null
              ? _buildConfirmacion()
              : _buildCamara(),
    );
  }

  // ---------------------------------------------------------
  // CÁMARA EN VIVO CON MARCO GUÍA
  // ---------------------------------------------------------
  Widget _buildCamara() {
    final size = MediaQuery.of(context).size;
    final marco = _marco(size);
    final controller = _controller;

    return Stack(
      children: [
        // Preview de la cámara (cover, centrado)
        if (controller != null)
          FutureBuilder<void>(
            future: _initFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done ||
                  !controller.value.isInitialized) {
                return const Center(
                  child: CircularProgressIndicator(color: colorsecundario),
                );
              }
              var scale = size.aspectRatio * controller.value.aspectRatio;
              if (scale < 1) scale = 1 / scale;
              return Transform.scale(
                scale: scale,
                child: Center(child: CameraPreview(controller)),
              );
            },
          )
        else
          const Center(
            child: CircularProgressIndicator(color: colorsecundario),
          ),

        // Capa oscura con hueco transparente en forma de credencial
        Positioned.fill(
          child: CustomPaint(
            painter: _OverlayMarcoPainter(hueco: marco, radio: 16),
          ),
        ),

        // Esquinas guía sobre el hueco
        Positioned.fromRect(
          rect: marco.inflate(4),
          child: CustomPaint(
            painter: _EsquinasPainter(color: colorsecundario),
          ),
        ),

        // Título e instrucción arriba del marco
        Positioned(
          left: 24,
          right: 24,
          top: marco.top - 92,
          child: Column(
            children: [
              Text(
                widget.titulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Coloca tu INE dentro del marco, con las 4 esquinas visibles y sin reflejos',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),

        // Barra superior: cerrar y flash
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _botonCircular(
                  icono: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                _botonCircular(
                  icono: _flashEncendido
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  activo: _flashEncendido,
                  onTap: _toggleFlash,
                ),
              ],
            ),
          ),
        ),

        // Botón de captura
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Center(
            child: GestureDetector(
              onTap: _tomarFoto,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                padding: const EdgeInsets.all(5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _capturando
                        ? colorsecundario.withOpacity(0.5)
                        : colorsecundario,
                  ),
                  child: _capturando
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // CONFIRMACIÓN DE LA FOTO
  // ---------------------------------------------------------
  Widget _buildConfirmacion() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            '¿Se ve bien tu INE?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Verifica que el texto sea legible y no haya reflejos',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_fotoCapturada!, fit: BoxFit.contain),
            ),
          ).animate().fadeIn(duration: 300.ms).scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
                duration: 300.ms,
                curve: Curves.easeOut,
              ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _repetir,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      'Repetir',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _usarFoto,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      'Usar foto',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorWhite,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: colorsecundario,
                      foregroundColor: colorWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // ERROR (ej. permiso denegado)
  // ---------------------------------------------------------
  Widget _buildError() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_rounded,
                size: 48,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.6,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: colorsecundario,
                  foregroundColor: colorWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Volver',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonCircular({
    required IconData icono,
    required VoidCallback onTap,
    bool activo = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: activo
              ? colorsecundario
              : Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icono, color: Colors.white, size: 22),
      ),
    );
  }
}

// ============================================================
// PAINTERS
// ============================================================

/// Capa oscura con un hueco transparente en forma de credencial
class _OverlayMarcoPainter extends CustomPainter {
  _OverlayMarcoPainter({required this.hueco, required this.radio});
  final Rect hueco;
  final double radio;

  @override
  void paint(Canvas canvas, Size size) {
    final fondo = Path()..addRect(Offset.zero & size);
    final agujero = Path()
      ..addRRect(RRect.fromRectAndRadius(hueco, Radius.circular(radio)));

    final recorte = Path.combine(PathOperation.difference, fondo, agujero);

    canvas.drawPath(
      recorte,
      Paint()..color = Colors.black.withOpacity(0.65),
    );

    // Borde sutil del hueco
    canvas.drawRRect(
      RRect.fromRectAndRadius(hueco, Radius.circular(radio)),
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayMarcoPainter oldDelegate) =>
      oldDelegate.hueco != hueco;
}

/// Esquinas tipo escáner (mismo estilo que en CrearDocumentos)
class _EsquinasPainter extends CustomPainter {
  _EsquinasPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double largo = 26;
    const double radio = 14;

    canvas.drawPath(
      Path()
        ..moveTo(0, largo)
        ..lineTo(0, radio)
        ..quadraticBezierTo(0, 0, radio, 0)
        ..lineTo(largo, 0),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - largo, 0)
        ..lineTo(size.width - radio, 0)
        ..quadraticBezierTo(size.width, 0, size.width, radio)
        ..lineTo(size.width, largo),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - largo)
        ..lineTo(0, size.height - radio)
        ..quadraticBezierTo(0, size.height, radio, size.height)
        ..lineTo(largo, size.height),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - largo, size.height)
        ..lineTo(size.width - radio, size.height)
        ..quadraticBezierTo(
            size.width, size.height, size.width, size.height - radio)
        ..lineTo(size.width, size.height - largo),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _EsquinasPainter oldDelegate) =>
      oldDelegate.color != color;
}