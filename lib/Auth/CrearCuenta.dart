import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Auth/Informacion.dart';
import 'package:gixt_worker/Auth/Login.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/registro_loader.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Config/device.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/inputs/Nacimientoformatter.dart';
import 'package:gixt_worker/components/inputs/Input.dart' hide OtpBoxclass;
import 'package:gixt_worker/components/inputs/Input_Fecha.dart';
import 'package:gixt_worker/components/inputs/Input_Password.dart';
import 'package:gixt_worker/components/inputs/Input_Phone.dart';
import 'package:gixt_worker/components/inputs/OtpBox.dart';
import 'package:gixt_worker/components/inputs/Pick_Image.dart';
import 'package:gixt_worker/services/Auth/cuenta_service.dart';
import 'package:gixt_worker/services/Auth/validarEmail.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class Crearcuenta extends StatefulWidget {
  const Crearcuenta({super.key});

  @override
  State<Crearcuenta> createState() => _CrearcuentaState();
}

class _CrearcuentaState extends State<Crearcuenta> {
  final _formKey = GlobalKey<FormState>();
  final _formKeyinfo = GlobalKey<FormState>();
  final _formKeyImg = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordconfirmarController = TextEditingController();
  final _first_nameController = TextEditingController();
  final _last_nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birth_dateControlle = TextEditingController();
  bool _isObscured = true;
  bool _isObscured1 = true;
  final PageController _controller = PageController();
  final PreferencesService _preferencesService = PreferencesService();
  int _paginaActual = 0;
  File? _image;
  String? _gender;

  bool? terms;
  GoogleMapController? mapController;
  LatLng? posicionActual = LatLng(20.9674, -89.5926);
  String codigo = '';
  String codigovalidation = '';
  bool errorCodigo = false;
  bool enviado = false;
  Timer? _timer;
  int segundosRestantes = 120;
  bool timeout = false;
  String _emailVerificado = '';
  bool _codigoVerificado = false;
  bool get _mismoCorroeQueVerificado =>
      _emailVerificado.isNotEmpty &&
      _emailController.text.trim() == _emailVerificado;

  /// El código ingresado es correcto y no ha expirado
  bool get _codigoOk =>
      codigo.length == 5 && codigo == codigovalidation && !timeout;

   

  void _Crear() async {
     var device = await DeviceService.getDeviceData();

    if (_image == null) {
      Toast(
        context,
        title: 'Imagen requerida',
        message: 'Por favor selecciona una imagen de perfil',
        type: alert_type.advertencia,
      );
      return;
    }
    if (!terms!) {
      Toast(
        context,
        title: 'Términos y condiciones',
        message: 'Debes aceptar los términos y condiciones para continuar.',
        type: alert_type.advertencia,
      );
      return;
    }

    showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => RegistroLoader(
      onRun: () =>   CuentaService.Crear(
      email: _emailController.text,
      password: _passwordController.text,
      firstName: _first_nameController.text,
      lastName: _last_nameController.text,
      image: _image ?? File(''),
      phone: _phoneController.text,
      gender: _gender ?? "",
      birth_date: _birth_dateControlle.text,
      terms: terms!,
      deviceId: device["deviceId"] ?? '',
      deviceName: device["deviceName"] ?? '',
      tokenFcm: device["tokenFcm"] ?? '',
    ),

      onSuccess: (result) async {
      final data = result['data'];
      print(data);
      String message = "Bienvenido ${data['username']}";

        await Toast(
          context,
          title: "Bienvenido",
          message: message,
          type: alert_type.exito,
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => CrearInfo(data: data)),  (route) => false,
        );
      
      },
    ),
  );
    
  }

  void _Validar() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await ValidarEmailService.Crear(email: _emailController.text);

    Navigator.pop(context);

    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        codigovalidation = data;
        enviado = true;
        iniciarContador();
      });
    } else {
      Future.microtask(() async {
        await Toast(
          context,
          title: "Error",
          message: result['message'],
          type: alert_type.error,
        );
      });
    }
  }

  void iniciarContador() {
    _timer?.cancel();

    setState(() {
      segundosRestantes = 120;
      timeout = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (segundosRestantes <= 0) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          timeout = true;
        });
      } else {
        if (!mounted) return;
        setState(() {
          segundosRestantes--;
        });
      }
    });
  }

  String get tiempoTexto {
    int min = segundosRestantes ~/ 60;
    int sec = segundosRestantes % 60;

    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  Future<void> _pickImage() async {
    final File? image = await pickAndCropImage(context);

    if (image != null) {
      setState(() {
        _image = image;
      });
    }
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
                      if (_paginaActual == 0) _buildwelcome(),
                      if (_paginaActual == 1) _buidFormulario(),
                      if (_paginaActual == 2) _buildverificacion(),
                      if (_paginaActual == 3) _buidFormularioInfo(),
                      if (_paginaActual == 4) _buidFormularioImg(),

                      const SizedBox(height: 20),
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

   Widget _buildwelcome() {
      final size = MediaQuery.of(context).size;
      return SizedBox(
        height: size.height,
        child: Stack(
          children: [
            // Imagen persona (hero)
              Positioned(
              top: size.height * 0.25,
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
              height: size.height * 0.88,
              child: Center(
                child: Hero(
                  tag: 'info',
                  child: Image.asset(
                    'assets/info.png',
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
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 42),
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
                        children: const [
                          TextSpan(text: 'Hola, '),
                          TextSpan(
                            text: 'Bienvenido',
                            style: TextStyle(color: colorsecundario),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '¡Nos alegra tenerte por aquí! Antes de empezar a recibir y ofrecer tus servicios, necesitamos que completes algunos datos básicos. Solo te tomará unos minutos y podrás disfrutar de todos los beneficios de la plataforma.',
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
          'Crear Cuenta',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }

  Widget _buidFormulario() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            number: '1',
            title: 'Crea tus credenciales de acceso',
            subtitle:
                'Ingresa un correo electrónico válido y crea una contraseña segura; los usarás cada vez que inicies sesión en la aplicación.',
          ),

          const SizedBox(height: 20),
          CustomTextFormField(
            controller: _emailController,
            label: 'Correo electrónico',
            readOnly: false,
            max: 50,
            keyboardType: TextInputType.emailAddress,
            icon: Icons.alternate_email_rounded,
            validator: _validateEmail,
          ),
          const SizedBox(height: 20),
          CustomPasswordFormField(
            controller: _passwordController,
            max: 20,
            validator: _validatePassword,
          ),
          const SizedBox(height: 20),
          CustomPasswordFormField(
            label: 'Confirmar Contraseña',
            controller: _passwordconfirmarController,
            max: 20,
          ),

          const SizedBox(height: 20),

          _buildInfoCard(
            icon: Icons.shield_outlined,
            text:
                'Utiliza una contraseña segura, combinando letras, números y símbolos, para mantener tu cuenta protegida.',
          ),
          const SizedBox(height: 40),
          _nextButton('Siguiente', () {
            if (_passwordController.text != _passwordconfirmarController.text) {
              Toast(
                context,
                title: 'Las contraseñas no coinciden',
                message: 'Por favor, revisa la contraseña',
                type: alert_type.advertencia,
              );
              return;
            }
            if (!(_formKey.currentState?.validate() ?? false)) return;
            setState(() {
              _paginaActual++;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildverificacion() {
    final yaVerificado = _codigoVerificado && _mismoCorroeQueVerificado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          number: '2',
          title: 'Verificación de correo electrónico',
          subtitle:
              'Enviaremos un código de seguridad de 5 dígitos a ${_emailController.text.trim()}. Ingrésalo a continuación para confirmar que la dirección te pertenece.',
        ),

        const SizedBox(height: 20),

        _buildInfoCard(
          icon: Icons.mark_email_unread_outlined,
          text:
              'Si no encuentras el correo en tu bandeja de entrada en unos minutos, revisa la carpeta de spam o correo no deseado antes de solicitar un nuevo código.',
        ),
        const SizedBox(height: 20),
        // ── CASO: ya verificado con el mismo correo ─────────────────────
        if (yaVerificado) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.green.withOpacity(0.22),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu correo electrónico ha sido verificado correctamente. Ya puedes continuar con el siguiente paso.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _nextButton('Continuar', () => setState(() => _paginaActual++)),
          const SizedBox(height: 8),
          _backButton(),
        ]
        // ── CASO: flujo normal (nuevo código o correo distinto) ─────────
        else ...[
          // Aviso si el correo cambió y había un caché previo
          if (_codigoVerificado && !_mismoCorroeQueVerificado) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.22),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Detectamos que cambiaste tu correo electrónico. Por seguridad, deberás verificarlo nuevamente antes de continuar.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Timer
          if (enviado) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  timeout ? Icons.timer_off_outlined : Icons.timer_outlined,
                  size: 14,
                  color: timeout
                      ? Colors.red.withOpacity(0.6)
                      : Theme.of(context).colorScheme.surface.withOpacity(0.35),
                ),
                const SizedBox(width: 6),
                Text(
                  timeout ? 'Código expirado' : 'Válido por $tiempoTexto',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: timeout
                        ? Colors.red.withOpacity(0.7)
                        : Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // OTP boxes
            OtpBoxclass(
              isError: errorCodigo,
              onChanged: (value) {
                setState(() {
                  codigo = value;
                  if (codigo.length == 5) {
                    if (_codigoOk) {
                      errorCodigo = false;
                      // Guardar caché de verificación
                      _codigoVerificado = true;
                      _emailVerificado = _emailController.text.trim();
                    } else {
                      errorCodigo = true;
                    }
                  } else {
                    errorCodigo = false;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
          ],

          // Botón enviar / reenviar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _Validar,
              icon: Icon(
                enviado ? Icons.refresh_rounded : Icons.send_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
              ),
              label: Text(
                enviado ? 'Reenviar código' : 'Enviar código',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.55),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Continuar — solo visible cuando el código es correcto
          if (enviado && _codigoOk && !errorCodigo) ...[
            _nextButton('Continuar', () => setState(() => _paginaActual++)),
            const SizedBox(height: 8),
          ],

          _backButton(),
        ],
      ],
    );
  }

  Widget _buidFormularioInfo() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Form(
      key: _formKeyinfo,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            number: '3',
            title: 'Información de perfil',
            subtitle:
                'Complete su perfil para conectarse con otros usuarios y ofrecer sus servicios de manera efectiva.',
          ),
          const SizedBox(height: 20),
          CustomTextFormField(
            controller: _first_nameController,
            label: 'Nombres',
            max: 50,
            readOnly: false,
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un Nombre';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),
          CustomTextFormField(
            controller: _last_nameController,
            label: 'Apellidos',
            max: 50,
            readOnly: false,
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un Apellido';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),
          CustomTextFormFieldPhone(
            controller: _phoneController,
            label: 'Teléfono',
            readOnly: false,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un teléfono';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),
          CustomTextFormFieldfecha(
            controller: _birth_dateControlle,
            validator: _validateDate,
          ),

          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GÉNERO',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  letterSpacing: 0.5,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.38),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  _genderChip('H', 'Hombre', Icons.male_rounded),
                  const SizedBox(width: 12),
                  _genderChip('M', 'Mujer', Icons.female_rounded),
                ],
              ),
            ],
          ),
          const SizedBox(height: 50),
          _nextButton('Siguiente', () {
            if (!(_formKeyinfo.currentState?.validate() ?? false)) return;
            if (_gender == null) {
              Toast(
                context,
                title: 'Género requerido',
                message: 'Por favor, selecciona tu género',
                type: alert_type.advertencia,
              );
              return;
            }
            setState(() {
              _paginaActual++;
            });
          }),

          _backButton(),
        ],
      ),
    );
  }

  Widget _buidFormularioImg() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Form(
      key: _formKeyImg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            number: '4',
            title: 'Foto de perfil',
            subtitle:
                'Seleccione una foto de perfil para que otros usuarios puedan conocerle mejor. Esta imagen es importante para facilitar la conexión y la oferta de sus servicios.',
          ),

          SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.07),
                      border: Border.all(
                        color: _image != null
                            ? colorsecundario.withOpacity(0.4)
                            : Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: _image == null
                        ? Icon(
                            Icons.person_outline_rounded,
                            size: 52,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.2),
                          )
                        : ClipOval(
                            child: Image.file(_image!, fit: BoxFit.cover),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  value: true,
                  fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Theme.of(context).colorScheme.surface;
                    }
                    return Theme.of(context).colorScheme.surface;
                  }),
                  groupValue: terms,
                  activeColor: Theme.of(context).colorScheme.surface,
                  title: Text(
                    'Acepto los términos y condiciones',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.7),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      terms = value;
                    });
                  },
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.surface,
                ),
                child: Text(
                  'Leer',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: colorsecundario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _nextButton('Crear', _Crear),
          _backButton(),
        ],
      ),
    );
  }



Widget _genderChip(String value, String label, IconData icon) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
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
      ),
    );
  }
  // Métodos auxiliares
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su correo';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingrese un correo válido';
    }
    return null;
  }

  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese fecha de nacimiento';
    }

    try {
      final parts = value.split('/');

      if (parts.length != 3) {
        return 'Formato inválido (DD/MM/AAAA)';
      }

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final birthDate = DateTime(year, month, day);
      final today = DateTime.now();

      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      if (age < 18) {
        return 'Debes ser mayor de 18 años';
      }

      return null;
    } catch (e) {
      return 'Fecha inválida';
    }
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

  Widget _backButton() {
    return TextButton(
      onPressed: salir,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(
          context,
        ).colorScheme.surface.withOpacity(0.45),
      ),
      child: Text('Regresar', style: GoogleFonts.poppins(fontSize: 13)),
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

}


