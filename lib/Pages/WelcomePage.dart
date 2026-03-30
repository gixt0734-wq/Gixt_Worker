import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/routes/root.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  final PreferencesService _preferencesService = PreferencesService();
  int _paginaActual = 0;
  String? username = '';

  void initState() {
    super.initState();
    print("Entré a welcome");
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('user');
    });
  }

  bool salir() {
    if (_paginaActual != 0) {
      setState(() {
        _paginaActual--; // vuelve al formulario
      });
      return false;
    } else {
    
      return true;
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
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 30),
                    if (_paginaActual == 0)
                      _buildwelcome(
                        'Hola, ',
                        'Bienvenido',
                        '¡Bienvenido! Es un gusto que estés en nuestra plataforma.',
                        'assets/persona3.png',
                        Icons.waving_hand_rounded,
                      ),
                    if (_paginaActual == 1)
                      _buildwelcome(
                        'Servicios ',
                        'Express',
                        'Podrás solicitar servicios express con trabajadores cuando tengas una emergencia.',
                        'assets/persona3.png', // TODO: cambia a imagen única por paso
                        Icons.flash_on_rounded,
                      ),
                    if (_paginaActual == 2)
                      _buildwelcome(
                        'Gestiona tu ',
                        'Agenda',
                        'Podrás gestionar tus servicios con nuestra agenda y guardar varias ubicaciones.',
                        'assets/persona3.png', // TODO: cambia a imagen única por paso
                        Icons.calendar_month_rounded,
                      ),
                    if (_paginaActual == 3)
                      _buildwelcome(
                        'Pedir ',
                        'Servicio',
                        'Puedes seleccionar entre varias categorías de trabajadores para solicitar y agendar un servicio.',
                        'assets/persona3.png', // TODO: cambia a imagen única por paso
                        Icons.handyman_rounded,
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildwelcome(
    String title,
    String highlight,
    String description,
    String image,
    IconData icon,
  ) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height,
      child: Stack(
        children: [
          // Imagen persona (hero)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.58,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Hero(
                tag: 'logo',
                child: Image.asset(
                  image,
                  width: size.width * 0.65,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Contenido inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 72),
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
                    child: Icon(icon, color: colorsecundario, size: 22),
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
                      children: [
                        TextSpan(text: title),
                        TextSpan(
                          text: highlight,
                          style: TextStyle(color: colorsecundario),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    description,
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
                      _paginaActual == 3
                          ? _buildStartButton()
                          : _buildNextButton(),
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

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _paginaActual++;
        });
      },
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

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: () {
          Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RootPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: colorsecundario,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colorsecundario.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Comenzar',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
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
