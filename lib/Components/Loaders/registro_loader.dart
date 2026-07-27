import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum _Estado { cargando, exito, error }

class RegistroLoader extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() onRun;
  final Future<void> Function(Map<String, dynamic> result) onSuccess;

  const RegistroLoader({
    super.key,
    required this.onRun,
    required this.onSuccess,
  });

  @override
  State<RegistroLoader> createState() => _RegistroLoaderState();
}

class _RegistroLoaderState extends State<RegistroLoader>
    with SingleTickerProviderStateMixin {
  static const _pasos = <String>[
    'Conectando...',
    'Subiendo imágenes...',
    'Guardando datos...',
    'Casi listo...',
  ];

  // Tiempo que se muestra cada paso como mínimo.
  static const _duracionPaso = Duration(seconds: 2);

  static const _bg = Color(0xFF0A0018);
  static const _purple = Color(0xFF820AD1);
  static const _green = Color(0xFF30C45E);
  static const _red = Color(0xFFFF4D6A);

  int _index = 0;
  Timer? _timer;
  Timer? _ultimoPasoTimer;
  _Estado _estado = _Estado.cargando;
  String _errorMsg = '';

  // Coordinación pasos <-> servidor
  bool _pasosCompletos = false;
  bool _finalizado = false;
  Map<String, dynamic>? _resultadoPendiente;

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _run() {
    _timer?.cancel();
    _ultimoPasoTimer?.cancel();

    setState(() {
      _estado = _Estado.cargando;
      _index = 0;
    });

    _pasosCompletos = false;
    _finalizado = false;
    _resultadoPendiente = null;

    // Avance de pasos independiente de la respuesta del servidor.
    _timer = Timer.periodic(_duracionPaso, (t) {
      if (_index < _pasos.length - 1) {
        setState(() => _index++);

        // Al llegar al último paso, lo dejamos visible su tiempo y marcamos
        // los pasos como completos.
        if (_index == _pasos.length - 1) {
          t.cancel();
          _ultimoPasoTimer = Timer(_duracionPaso, () {
            _pasosCompletos = true;
            _maybeFinish();
          });
        }
      }
    });

    widget.onRun().then((result) {
      if (!mounted) return;

      // Si falló, mostramos el error de inmediato (no esperamos los pasos).
      if (result['success'] != true) {
        _finalizado = true;
        _timer?.cancel();
        _ultimoPasoTimer?.cancel();
        setState(() {
          _estado = _Estado.error;
          _errorMsg = result['message']?.toString() ?? 'Ocurrió un error';
        });
        return;
      }

      // Éxito: guardamos el resultado y esperamos a que terminen los pasos.
      _resultadoPendiente = result;
      _maybeFinish();
    }).catchError((e) {
      if (!mounted) return;
      _finalizado = true;
      _timer?.cancel();
      _ultimoPasoTimer?.cancel();
      setState(() {
        _estado = _Estado.error;
        _errorMsg = 'No se pudo conectar. Revisa tu conexión.';
      });
    });
  }

  // Solo finaliza con éxito cuando los pasos terminaron Y el servidor respondió.
  void _maybeFinish() {
    if (_finalizado) return;
    if (!_pasosCompletos) return;
    if (_resultadoPendiente == null) return;

    _finalizado = true;
    _mostrarExito(_resultadoPendiente!);
  }

  Future<void> _mostrarExito(Map<String, dynamic> result) async {
    if (!mounted) return;
    setState(() {
      _index = _pasos.length - 1;
      _estado = _Estado.exito;
    });
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    await widget.onSuccess(result);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ultimoPasoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   return PopScope(
      canPop: _estado == _Estado.error,
      child: Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_estado) {
      case _Estado.cargando:
        return _buildCargando();
      case _Estado.exito:
        return _buildExito();
      case _Estado.error:
        return _buildError();
    }
  }

  Widget _buildCargando() {
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Persona con glow pulsante detrás
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Hero(
                tag: 'logo',
                child: Image.asset(
                  'assets/logo.png',
                  width: size.width * 0.60,
                  fit: BoxFit.contain,
                  color: colorsecundario,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 1,
                    end: 1.06,
                    duration: 1600.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
          const SizedBox(height: 48),

          // Contador de paso
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              'Paso ${_index + 1} de ${_pasos.length}',
              key: ValueKey('count_$_index'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                color: cs.surface.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Paso actual (texto grande)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.18),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            ),
            child: Text(
              _pasos[_index],
              key: ValueKey(_index),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 34,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: colorsecundario,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Barra de progreso continua
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  color: colorsecundario.withValues(alpha: 0.18),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  widthFactor: (_index + 1) / _pasos.length,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorsecundario,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: colorsecundario,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildExito() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CirculoCheck(color: _green)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              begin: 1,
              end: 1.06,
              duration: 1600.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: 36),
        Text(
          '¡Todo listo!',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.5,
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 10),
        Text(
          'Tu información fue guardada\ncorrectamente.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.surface,
            height: 1.6,
          ),
        )
            .animate(delay: 350.ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _red.withValues(alpha: 0.12),
              border: Border.all(color: _red.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.close_rounded, color: _red, size: 42),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1,
                end: 1.06,
                duration: 1600.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 32),
          Text(
            'Algo salió mal',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.surface,
              letterSpacing: -0.3,
            ),
          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 10),
          Text(
            _errorMsg,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              height: 1.6,
            ),
          ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _run,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorsecundario,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Reintentar',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.3, end: 0),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
              ),
            ),
          ).animate(delay: 420.ms).fadeIn(),
        ],
      ),
    );
  }
}

class _CirculoCheck extends StatelessWidget {
  final Color color;
  const _CirculoCheck({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.08),
          ),
        ),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
          ),
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ],
    );
  }
}