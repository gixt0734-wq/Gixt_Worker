import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Auth/Login.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/Components/Loaders/update_loader.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/inputs/Input.dart';
import 'package:gixt_worker/Components/inputs/Input_Password.dart';
import 'package:gixt_worker/Components/inputs/OtpBox.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/services/Auth/updatepasswor_service.dart';
import 'package:gixt_worker/services/Auth/validarAccount.dart';
import 'package:gixt_worker/services/Auth/validarotp.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Updatepassword extends StatefulWidget {
  const Updatepassword({super.key, this.email});

  final String? email;

  @override
  State<Updatepassword> createState() => _UpdatepasswordState();
}

class _UpdatepasswordState extends State<Updatepassword> {
  final _formKey = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmarController = TextEditingController();

  int _paginaActual = 0;
  String _codigo = '';
  String _recoveryToken = '';
  bool _errorCodigo = false;
  bool _enviado = false; // ya se envió un OTP al correo
  bool _verificado = false; // el OTP fue validado por el backend
  Timer? _timer;
  int _segundosRestantes = 120;
  bool _timeout = false;

  static const int _otpLength = 5;

  /// El código está completo y todavía es válido.
  bool get _codigoOk => _codigo.length == _otpLength && !_timeout;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmarController.dispose();
    super.dispose();
  }

  // ───────────────────────── Lógica de red ─────────────────────────

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

  /// Actualiza la contraseña con el recoveryToken obtenido.
  void _update() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateLoader(
        onRun: () => UpdatePasswordService.Update(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          recoveryToken: _recoveryToken,
        ),
        onSuccess: (result) async {
          if (!mounted) return;
          Navigator.pop(context); // cerrar loader

          await Toast(
            context,
            title: "Password actualizado",
            message:
                "Contraseña actualizada correctamente. Ahora puedes iniciar sesión con tu nueva contraseña.",
            type: alert_type.exito,
          );

          if (!mounted) return;

          if (widget.email != null) {
            Navigator.pop(context); // cerrar UpdatePassword
            return;
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
        },
      ),
    );
  }

  // ───────────────────────── Contador ─────────────────────────

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

  // ───────────────────────── Navegación ─────────────────────────


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

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return  WillPopScope(
      onWillPop: () async {
        return salir();
      },
      child: KeyboardDismisser(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      if (_paginaActual == 0) _buildFormulario(),
                      if (_paginaActual == 1) _buildVerificacion(),
                      if (_paginaActual == 2) _buildFormularioPassword(),
                      const SizedBox(height: 20),
                      _buildDots(),
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
      pinned: true,
      floating: false,
      snap: false,
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
        onPressed: salir,
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Recuperar Contraseña',
          style: GoogleFonts.poppins(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Página 0: correo ─────────────────────────

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            icon: Icons.lock_reset_rounded,
            title: 'Credenciales de cuenta',
            subtitle:
                'Ingrese su correo electrónico para recibir un código de verificación y establecer una nueva contraseña.',
          ),
          const SizedBox(height: 20),
          CustomTextFormField(
            controller: _emailController,
            label: 'Correo',
            max: 50,
            readOnly: false,
            keyboardType: TextInputType.emailAddress,
            icon: Icons.person,
            validator: _validateEmail,
          ),
          const SizedBox(height: 50),
          _nextButton('Siguiente', () async {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final ok = await _crearToken();
            if (ok && mounted) {
              setState(() => _paginaActual++);
            }
          }),
        ],
      ),
    );
  }

  // ───────────────────────── Página 1: verificación ─────────────────────────

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

  // ───────────────────────── Página 2: nueva contraseña ─────────────────────────

  Widget _buildFormularioPassword() {
    return Form(
      key: _formKeyPassword,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            icon: Icons.key_rounded,
            title: 'Nuevas credenciales de cuenta',
            subtitle: 'Ingrese su nueva contraseña.',
          ),
          const SizedBox(height: 20),
          CustomPasswordFormField(
            controller: _passwordController,
            validator: _validatePassword,
            max: 10,
          ),
          const SizedBox(height: 20),
          CustomPasswordFormField(
            label: 'Confirmar Contraseña',
            controller: _passwordConfirmarController,
            max: 10,
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            icon: Icons.shield_outlined,
            text:
                'Utiliza al menos 6 caracteres combinando letras y números para proteger tu cuenta.',
          ),
          const SizedBox(height: 40),
          _nextButton('Siguiente', () {
            if (!(_formKeyPassword.currentState?.validate() ?? false)) return;
            if (_passwordController.text != _passwordConfirmarController.text) {
              Toast(
                context,
                title: 'Las contraseñas no coinciden',
                message: 'Por favor, revisa la contraseña',
                type: alert_type.advertencia,
              );
              return;
            }
            _update();
          }),
        ],
      ),
    );
  }

  // ───────────────────────── Validadores ─────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingrese su correo';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingrese un correo válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese una contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
}