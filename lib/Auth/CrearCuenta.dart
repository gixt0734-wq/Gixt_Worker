import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Auth/Informacion.dart';
import 'package:gixt_worker/Auth/Login.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/components/Indicador.dart';
import 'package:gixt_worker/components/inputs/Nacimientoformatter.dart';
import 'package:gixt_worker/components/inputs/Input.dart' hide OtpBoxclass;
import 'package:gixt_worker/components/inputs/Input_Fecha.dart';
import 'package:gixt_worker/components/inputs/Input_Password.dart';
import 'package:gixt_worker/components/inputs/Input_Phone.dart';
import 'package:gixt_worker/components/inputs/OtpBox.dart';
import 'package:gixt_worker/components/inputs/Pick_Image.dart';
import 'package:gixt_worker/services/Auth/cuenta_service.dart';
import 'package:gixt_worker/services/Auth/validar.dart';
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

  Future<void> _saveToken(
    String token,
    String inicio,
    String id,
    String user,
    String img,
  ) async {
    await _preferencesService.savePreferences(token, inicio, id, img, user);

  }

  void _Crear() async {
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
      builder: (_) => Indicador(),
    );

    final result = await CuentaService.Crear(
      email: _emailController.text,
      password: _passwordController.text,
      firstName: _first_nameController.text,
      lastName: _last_nameController.text,
      image: _image ?? File(''),
      phone: _phoneController.text,
      gender: _gender ?? "",
      birth_date: _birth_dateControlle.text,
      terms: terms!,
    );

    Navigator.pop(context);

    if (result['success'] == true) {
      final data = result['data'];
      String message = "Bienvenido ${data['username']}";
      Future.microtask(() async {
        await _saveToken(
          data['token'],
          "true",
          data['id'].toString(),
          data['username'],
          data['img'],
        );
        await Toast(
          context,
          title: "Bienvenido",
          message: message,
          type: alert_type.exito,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CrearInfo(data: data,)),
        );
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

  void _Validar() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await ValidarService.Crear(email: _emailController.text);

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
              if (_paginaActual != 0)_buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
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
            top: 0,
            left: 0, right: 0,
            height: size.height * 0.58,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Hero(
                tag: 'logo',
                child: Image.asset(
                  'assets/persona3.png',
                  width: size.width * 0.65,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Contenido inferior
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    '¡Bienvenido! Para comenzar a usar nuestra plataforma, por favor completa tus datos correctamente.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      height: 1.75,
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDots(),
                      _circleNextButton((){setState(() {
                        _paginaActual++;
                      });}),
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
  
  Widget _circleNextButton(VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56, height: 56,
        decoration: const BoxDecoration(
          color: colorsecundario,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Crear Cuenta',
          style: GoogleFonts.poppins(
            fontSize: 25,
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

  Widget _buidFormulario() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageHeader(
            'Credenciales de la cuenta',
            'Ingresa tu correo electrónico y una contraseña segura para crear tu cuenta.',
          ),

          const SizedBox(height: 40),

          CustomTextFormField(
            controller: _emailController,
            label: 'Correo',
            readOnly: false,
            keyboardType: TextInputType.emailAddress,
            icon: Icons.person,
            validator:_validateEmail
          ),
          const SizedBox(height: 20),
          CustomPasswordFormField(controller: _passwordController,validator: _validatePassword,),
          const SizedBox(height: 20),
          CustomPasswordFormField(
            label: 'Confirmar Contraseña',
            controller: _passwordconfirmarController,
            
          ),

          const SizedBox(height: 70),
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

  Widget _genderChip(String value, String label, IconData icon) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorsecundario.withOpacity(0.08)
                : Colors.transparent,
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
                    ? colorsecundario
                    : Theme.of(context).colorScheme.surface.withOpacity(0.4),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? colorsecundario
                      : Theme.of(context).colorScheme.surface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildverificacion() {
    final yaVerificado = _codigoVerificado && _mismoCorroeQueVerificado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PageHeader(
          'Verifica tu correo',
          'Enviaremos un código de 5 dígitos a ${_emailController.text.trim()}',
        ),
        const SizedBox(height: 24),

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
                    'Correo verificado. Puedes continuar.',
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
                      'Cambiaste el correo. Debes verificar de nuevo.',
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
          _PageHeader(
            'Informacion de Perfil',
            'Completa tu perfil para conectar con otros usuarios y ofrecer tus servicios de manera efectiva.',
          ),
          const SizedBox(height: 40),
          CustomTextFormField(
            controller: _first_nameController,
            label: 'Nombre',
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
            label: 'Apellido',
            readOnly: false,
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un Apelldo';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),
          CustomTextFormFieldPhone(
            controller: _phoneController,
            label: 'Telefono',
            readOnly: false,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un telefono';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),
          CustomTextFormFieldfecha(controller: _birth_dateControlle),

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
          _PageHeader(
            'Foto de perfil',
            'selecciona una foto de perfil para que otros usuarios puedan conocerte mejor. Esta imagen es importante para conectar con otros y ofrecer tus servicios de manera efectiva.',
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
                    'Acepto los terminos y condiciones',
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
          _nextButton('crear', _Crear),
          _backButton(),
        ],
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese una contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }
}
