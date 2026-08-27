import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Auth/Login.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Config/location.dart';
import 'package:gixt_worker/routes/root.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Logoutpage extends StatefulWidget {
  const Logoutpage({super.key});

  @override
  State<Logoutpage> createState() => _LogoutpageState();
}

class _LogoutpageState extends State<Logoutpage> {
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  final PreferencesService _preferencesService = PreferencesService();
  int _paginaActual = 0;
  String? username = '';

  void initState() {
    super.initState();
    print("Entré a welcome");
    LocationService.stop();
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
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 0),
                    _buildwelcome(
                      'Sesión ',
                      'cerrada',
                      'Tu sesión ha finalizado. Inicia sesión nuevamente para continuar usando Gixt.',
                      'assets/candado.png',
                      0.66,
                      Icons.lock_clock_rounded,
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
    double width,
    IconData icon,
  ) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      key: ValueKey<int>(_paginaActual),
      height: size.height,
      child: Stack(
        children: [
          // Imagen persona (hero)
           Positioned(
              top: size.height * 0.18,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: size.width * 1.12,
                  height: size.width * 1.12,
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
                      width: size.width * width,
                      fit: BoxFit.contain,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    duration: 450.ms,
                    curve: Curves.easeOutBack,
                  ),
            ),
          ),

          // Contenido inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 52),
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
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms)
                      .slideY(
                        begin: 0.4,
                        end: 0,
                        duration: 400.ms,
                        delay: 100.ms,
                        curve: Curves.easeOutCubic,
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
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 180.ms)
                      .slideY(
                        begin: 0.4,
                        end: 0,
                        duration: 400.ms,
                        delay: 180.ms,
                        curve: Curves.easeOutCubic,
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
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 260.ms)
                      .slideY(
                        begin: 0.4,
                        end: 0,
                        duration: 400.ms,
                        delay: 260.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 36),
                  Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           _buildStartButton()
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 340.ms)
                      .slideY(
                        begin: 0.4,
                        end: 0,
                        duration: 400.ms,
                        delay: 340.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: () {
          Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
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
              'Iniciar sesión',
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

 
  
}
