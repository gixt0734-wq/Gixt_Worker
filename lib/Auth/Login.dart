import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gixt_worker/Auth/CrearCuenta.dart';
import 'package:gixt_worker/Auth/Informacion.dart';
import 'package:gixt_worker/Components/alert.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/WelcomePage.dart';
import 'package:gixt_worker/components/Indicador.dart';
import 'package:gixt_worker/components/inputs/input.dart';
import 'package:gixt_worker/components/inputs/Input_Password.dart';
import 'package:gixt_worker/config/device.dart';
import 'package:gixt_worker/services/Auth/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario
  final _emailController =
      TextEditingController(); // Controlador para el nombre de usuario
  final _passwordController =
      TextEditingController(); // Controlador para la contraseña
  bool _isObscured = true;
  final PreferencesService _preferencesService = PreferencesService();


  Future<void> _saveToken(
    String token,
    String inicio,
    String id,
    String user,
    String img,
  ) async {
    await _preferencesService.savePreferences(token, inicio, id, img, user);

  }

  void _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    var device = await DeviceService.getDeviceData();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await AuthService.login(
      email: _emailController.text,
      password: _passwordController.text,
      deviceId: device["deviceId"] ?? '',
      deviceName: device["deviceName"] ?? '',
      tokenFcm: device["tokenFcm"] ?? '',
    );

    Navigator.pop(context); // cerrar loader
 
    if (result['success'] == true) {
      final data = result['data'];
      print(data);
      String message = "Bienvenido ${data['username']}";
      if(data['info'] == false)
      {
        Future.microtask(() async {
        
        await mostrarAlerta(
          context,
          title: "Bienvenido, antes de comensar necesitamos que termines tu registro",
          message: message,
          type: alert_type.exito,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CrearInfo(data: data)),
        );
      });
return;
      }
     
      Future.microtask(() async {
        await _saveToken(
          data['token'],
          "true",
          data['id'].toString(),
          data['username'],
          data['img'],
        );
        await mostrarAlerta(
          context,
          title: "Bienvenido",
          message: message,
          type: alert_type.exito,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomePage()),
        );
      });
    } else {
      mostrarAlerta(
        context,
        title: "Error",
        message: result['message'],
        type: alert_type.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(children: [_buildLogo(), _buildFormulario()]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Hero(
          tag: 'logo',
          child: Image.asset(
            'assets/logo.png',
            width: 150,
            height: 150,
            color: colorsecundario,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
            'Iniciar sesion',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.surface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Ingresa tus datos para continuar',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
            const SizedBox(height: 40),
            CustomTextFormField(
              controller: _emailController,
              label: 'Correo',
              readOnly: false,
              keyboardType: TextInputType.emailAddress,
              icon: Icons.email,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un correo';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            CustomPasswordFormField(controller: _passwordController),

            const SizedBox(height: 10),

            // Recuperar contraseña
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.6,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.45),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botón de inicio de sesión
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: colorsecundario,
                foregroundColor: colorWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Iniciar sesión',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorWhite,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botón de registro
            TextButton(
              onPressed: _handleNavigateToRegister,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                '¿No tienes cuenta? Regístrate',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.6,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.45),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
            children: [
              Expanded(
                child: Divider(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withOpacity(0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'o continuar con',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withOpacity(0.4),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withOpacity(0.12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botones sociales con texto descriptivo
          Row(
            children: [
              Expanded(
                child: _socialButton(
                  assetPath: 'assets/google.png',
                  label: 'Google',
                  onTap: () {
               
                  },
                ),
              ),
              
            ],
          ),

           
          ],
        ),
      ),
    );
  }

Widget _socialButton({
    required String assetPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.surface.withOpacity(0.12),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(assetPath, width: 20, height: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.surface,
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese una contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  void _handleForgotPassword() {
    // Implementa la lógica de recuperación de contraseña
    print('Recuperar Contraseña presionado');
    // Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordPage()));
  }

  void _handleNavigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Crearcuenta()),
    );
  }
}
