import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Components/CircleImage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/Components/Loaders/delete_loader%20copy.dart';
import 'package:gixt_worker/Components/Loaders/delete_loader.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/inputs/OtpBox.dart';
import 'package:gixt_worker/Config/SignalRService.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/services/Auth/delete_user_service.dart';
import 'package:gixt_worker/services/Auth/validarAccount.dart';
import 'package:gixt_worker/services/Auth/validarEmail.dart';
import 'package:gixt_worker/services/Auth/validarotp.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Deleteaccount extends StatefulWidget {
  const Deleteaccount({super.key, this.email, required this.img});
  final String? email;
  final String? img;
  @override
  State<Deleteaccount> createState() => _DeleteaccountState();
}

class _DeleteaccountState extends State<Deleteaccount> {
  final _formKey = GlobalKey<FormState>();
  final _formKeyinfo = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordconfirmarController = TextEditingController();
  final PageController _controller = PageController();
  final PreferencesService _preferencesService = PreferencesService();


  bool timeout = false;
  String _emailVerificado = '';
  bool _codigoVerificado = false;


    int _paginaActual = 0;
  String _codigo = '';
  String _recoveryToken = '';
  bool _errorCodigo = false;
  bool _enviado = false; // ya se envió un OTP al correo
  bool _verificado = false; // el OTP fue validado por el backend
  Timer? _timer;
  int _segundosRestantes = 120;
  bool _timeout = false;

  bool get _mismoCorroeQueVerificado =>
      _emailVerificado.isNotEmpty &&
      _emailController.text.trim() == _emailVerificado;

  /// true mientras el dedo está arrastrando algo
  bool _isDragging = false;

  /// true cuando el círculo está encima del bote
  bool _isOverTrash = false;

  static const int _otpLength = 5;

  /// El código está completo y todavía es válido.
  bool get _codigoOk => _codigo.length == _otpLength && !_timeout;

  void _delete() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteLoader(
      onRun: () =>  DeleteUserService.delete(recoveryToken: _recoveryToken,),
      onSuccess: (result) async {
      final prefs = await SharedPreferences.getInstance();
      bool ok = await SignalRService.disconnectServer();
      await prefs.clear();
      final data = result['data'];
      String message = "Cuenta eliminada correctamente.";
      Future.microtask(() async {
        await Toast(
          context,
          title: "Cuenta eliminada",
          message: message,
          type: alert_type.exito,
        );
        return;
      });
      }
      ));
    
  }


  /// Envía (o reenvía) el código OTP al correo.
  Future<bool> _crearToken() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Indicador(),
    );

    final result = await ValidarAccounthService.Crear(
      email: _emailController.text.trim(),
    );

    if (!mounted) return false;
    Navigator.pop(context); // cerrar loader

    if (result['success'] == true) {
      setState(() {
        _enviado = true;
        _verificado = false; // nuevo código → hay que volver a verificar
        _codigo = '';
        _errorCodigo = false;
      });
      _iniciarContador();
      return true;
    }

    await Toast(
      context,
      title: "Error",
      message: result['message'] ?? 'No se pudo enviar el código',
      type: alert_type.error,
    );
    return false;
  }

  /// Valida el OTP contra el backend y guarda el recoveryToken.
  Future<void> _validarToken() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Indicador(),
    );

    final result = await ValidarOtpService.Crear(
      email: _emailController.text.trim(),
      otp: _codigo,
    );

    if (!mounted) return;
    Navigator.pop(context); // cerrar loader

    if (result['success'] == true) {
      _timer?.cancel();
      setState(() {
        _recoveryToken = result['data'];
        _verificado = true;
        _errorCodigo = false;
        _paginaActual++;
      });
      return;
    }

    setState(() => _errorCodigo = true);
    await Toast(
      context,
      title: "Código incorrecto",
      message: result['message'] ?? 'Verifica el código e inténtalo de nuevo',
      type: alert_type.error,
    );
  }

  void _iniciarContador() {
    _timer?.cancel();

    setState(() {
      _segundosRestantes = 240;
      _timeout = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_segundosRestantes <= 1) {
        timer.cancel();
        setState(() {
          _segundosRestantes = 0;
          _timeout = true;
        });
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  String get _tiempoTexto {
    final min = _segundosRestantes ~/ 60;
    final sec = _segundosRestantes % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
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
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      if (_paginaActual == 0) _buildIntro(),
                      if (_paginaActual == 1) _buildVerificacion(),
                      if (_paginaActual == 2) _buidFormularioPassword(),
                      if (_paginaActual != 0) const SizedBox(height: 20),
                      if (_paginaActual != 0) _buildDots(),
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
          'Eliminar cuenta',
          style: GoogleFonts.poppins(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }

Widget _buildIntro() {
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: size.height,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.42,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Hero(
                tag: 'logo',
                child: Image.asset(
                  'assets/bye.png',
                  width: size.width * 0.55,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 42),
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
                      Icons.heart_broken_rounded,
                      color: colorsecundario,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 18),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.15,
                        color: cs.surface,
                      ),
                      children: [
                        const TextSpan(text: 'Lamentamos\nque te '),
                        TextSpan(
                          text: 'vayas',
                          style: const TextStyle(color: colorsecundario),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Antes de continuar, queremos que sepas qué pasará si eliminas tu cuenta:',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      height: 1.7,
                      color: cs.surface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                   _bullet(
                    Icons.person_off_outlined,
                    'Se eliminarán tu perfil y tus datos personales.',
                  ),
                  _bullet(
                    Icons.history_toggle_off_rounded,
                    'Perderás tu historial de servicios y tus chats.',
                  ),
                  _bullet(
                    Icons.lock_clock_rounded,
                    'Esta acción es permanente y no se puede deshacer.',
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDots(),
                      _circleNextButton(
                        () async {
                          final ok = await _crearToken();
                          if (ok && mounted) {
                            setState(() => _paginaActual++);
                          }
                        }
                      ),
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

   Widget _bullet(IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colorsecundario.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: colorsecundario),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                  color: cs.surface.withOpacity(0.65),
                ),
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
        decoration: BoxDecoration(
          color: colorsecundario,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorsecundario.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

 
  Widget _buildVerificacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          icon: Icons.mark_email_read_rounded,
          title: 'Verificación de correo electrónico',
          subtitle: 'Se enviará un código de 5 dígitos a ',
        ),
        const SizedBox(height: 4),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: colorsecundario.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _emailController.text.trim(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorsecundario,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Ya verificado ──────────────────────────────────────────────
        if (_verificado) ...[
          _buildBanner(
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
            text: 'Correo verificado. Puedes continuar.',
          ),
          const SizedBox(height: 20),
          _nextButton('Continuar', () => setState(() => _paginaActual++)),
          const SizedBox(height: 8),
        ]
        // ── Flujo normal ───────────────────────────────────────────────
        else ...[
          if (_enviado) ...[
            _buildTimer(),
            const SizedBox(height: 16),
            OtpBoxclass(
              isError: _errorCodigo,
              onChanged: (value) {
                setState(() {
                  _codigo = value;
                  _errorCodigo = false; // limpiar error al editar
                });
              },
            ),
            const SizedBox(height: 16),
          ],
          _buildValidarButton(),
          const SizedBox(height: 20),
          _buildInfoCard(
            icon: Icons.lightbulb,
            text:
                'En caso de no visualizar el correo en su bandeja principal, le recomendamos revisar la carpeta de spam o correo no deseado.',
          ),
        ],
      ],
    );
  }

  Widget _buildTimer() {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _timeout
              ? Colors.red.withOpacity(0.07)
              : Theme.of(context).colorScheme.surface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _timeout ? Icons.timer_off_outlined : Icons.timer_outlined,
              size: 14,
              color: _timeout
                  ? Colors.red.withOpacity(0.7)
                  : Theme.of(context).colorScheme.surface.withOpacity(0.45),
            ),
            const SizedBox(width: 6),
            Text(
              _timeout ? 'Código expirado' : 'Válido por $_tiempoTexto',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _timeout
                    ? Colors.red.withOpacity(0.8)
                    : Theme.of(context).colorScheme.surface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Botón que valida el OTP o lo reenvía cuando expiró.
  Widget _buildValidarButton() {
    final esReenviar = _timeout;
    final VoidCallback? onTap = esReenviar
        ? () => _crearToken()
        : (_codigoOk ? () => _validarToken() : null);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: colorsecundario,
          disabledBackgroundColor:
              Theme.of(context).colorScheme.surface.withOpacity(0.12),
          disabledForegroundColor:
              Theme.of(context).colorScheme.surface.withOpacity(0.4),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(esReenviar ? Icons.refresh_rounded : Icons.send_outlined,
                size: 20),
            const SizedBox(width: 8),
            Text(
              esReenviar ? 'Reenviar código' : 'Validar',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buidFormularioPassword() {
    return Form(
      key: _formKeyinfo,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            icon: Icons.delete_outlined,
            title: 'Eliminar cuenta',
            subtitle:
                'Arrastra tu foto hacia abajo, hasta el bote, para eliminar tu cuenta.',
          ),
          const SizedBox(height: 12),
          _buildDragToDeleteSection(),
          const SizedBox(height: 4),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _isOverTrash
                    ? 'Suelta para eliminar tu cuenta'
                    : _isDragging
                        ? 'Sigue bajando hasta el bote'
                        : 'Arrastra tu foto hacia el bote',
                key: ValueKey('$_isDragging$_isOverTrash'),
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _isOverTrash
                      ? colorError
                      : Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.4),
                ),
              ),
            )
          )
        ],
      ),
    );
  }

 Widget _buildDragToDeleteSection() {
  return SizedBox(
    height: 420,
    child: Stack(
      children: [
        Align(
          alignment: const Alignment(0, -0.75),
          child: _buildDraggableCircle(),
        ),

        Align(
          alignment: const Alignment(0, 0.15),
          child: Icon(
            Icons.keyboard_double_arrow_down_rounded,
            color: colorError,
            size: 26,
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .slideY(
                begin: -0.25,
                end: 0.35,
                duration: 550.ms,
                curve: Curves.easeInOut,
              )
              .fade(
                begin: 0.5,
                end: 1.0,
                duration: 550.ms,
              ),
        ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildTrash(),
        ),
      ],
    ),
  );
}

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Center(
          child:
              Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: colorsecundario.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorsecundario.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 40, color: colorsecundario),
                      ),
                    ),
                  )
                  // pulso sutil y continuo para que el ícono se sienta vivo
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 1,
                    end: 1.06,
                    duration: 1600.ms,
                    curve: Curves.easeInOut,
                  ),
        ),

        const SizedBox(height: 20),

        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
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

  void _onDropInTrash(int id) {
    setState(() => _paginaActual++);
  }

  Widget _buildDraggableCircle() {
    return Draggable<int>(
      data: 1,
      feedback: Material(color: Colors.transparent, child: _circle()),

      childWhenDragging: Opacity(opacity: 0.25, child: _circle()),

      onDragStarted: () {
        setState(() => _isDragging = true);
      },

      onDragEnd: (_) {
        setState(() {
          _isDragging = false;
          _isOverTrash = false;
        });
      },

      onDraggableCanceled: (_, __) {
        setState(() {
          _isDragging = false;
          _isOverTrash = false;
        });
      },

      child: _circle(),
    );
  }

  Widget _circle({bool dragging = false}) {
    return Container(
      width: 150,
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dragging ? 0.25 : 0.10),
            blurRadius: dragging ? 28 : 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Circleimage(
        w: double.infinity,
        h: double.infinity,
        image_url: widget.img,
      ),
    );
  }

  Widget _buildTrash() {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isOverTrash = true);
        return true;
      },
      onLeave: (_) => setState(() => _isOverTrash = false),
      onAcceptWithDetails: (details) {
        setState(() => _isOverTrash = false);
        _delete();
      },
      builder: (context, candidate, rejected) {
        final active = _isOverTrash || candidate.isNotEmpty;

        return SizedBox(
          width: double.infinity,
          height: 170,
          child: Center(
            // Anillo objetivo siempre visible para que se entienda a dónde soltar
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: active ? 132 : 112,
              height: active ? 132 : 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorError.withOpacity(active ? 0.12 : 0.05),
                border: Border.all(
                  color: colorError.withOpacity(active ? 0.9 : 0.25),
                  width: active ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorError.withOpacity(active ? 0.35 : 0),
                    blurRadius: active ? 26 : 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: active ? 86 : 70,
                  height: active ? 86 : 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? colorError : Colors.transparent,
                  ),
                  child: Icon(
                    active
                        ? Icons.delete_forever_rounded
                        : Icons.delete_outline_rounded,
                    color: active ? Colors.white : colorError.withOpacity(0.65),
                    size: active ? 46 : 36,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


    // ───────────────────────── Widgets reutilizables ─────────────────────────

  Widget _buildBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
