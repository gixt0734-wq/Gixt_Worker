import 'package:didit_sdk/sdk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Auth/Login.dart';
import 'package:gixt_worker/Components/Loaders/documents_loader.dart';
import 'package:gixt_worker/Components/Sketor/opciones.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/Visorpdf.dart';
import 'package:gixt_worker/Components/categoriasoption.dart';
import 'package:gixt_worker/Components/inputs/Pick_Doc.dart';
import 'package:gixt_worker/Components/inputs/camara_ine.dart';
import 'package:gixt_worker/Components/registro_loader.dart';
import 'package:gixt_worker/Config/SignalRService.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/WelcomePage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/inputs/Input.dart' hide OtpBoxclass;
import 'package:gixt_worker/components/inputs/Input_Description.dart';
import 'package:gixt_worker/components/inputs/Input_Fecha.dart';
import 'package:gixt_worker/components/inputs/Input_Password.dart';
import 'package:gixt_worker/components/inputs/Input_Phone.dart';
import 'package:gixt_worker/components/inputs/Input_Price.dart';
import 'package:gixt_worker/components/inputs/OtpBox.dart';
import 'package:gixt_worker/components/inputs/Pick_Image.dart';
import 'package:gixt_worker/routes/root.dart';
import 'package:gixt_worker/services/Auth/SessionDiditService.dart';
import 'package:gixt_worker/services/Auth/cuenta_service.dart';
import 'package:gixt_worker/services/Auth/doc_service.dart';
import 'package:gixt_worker/services/Auth/info_service.dart';
import 'package:gixt_worker/services/Location/Geolocation_service.dart';
import 'package:gixt_worker/services/Location/geocoding_helper.dart';
import 'package:gixt_worker/services/servicios/categorias_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'dart:async';
import 'dart:io';

import 'package:pdfx/pdfx.dart';

class CrearDocumentos extends StatefulWidget {
  const CrearDocumentos({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  State<CrearDocumentos> createState() => _CrearDocumentostate();
}

class _CrearDocumentostate extends State<CrearDocumentos>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, Uint8List?> _pdfThumbs = {};

  int _paginaActual = 0;
  bool isloading = false;

  final Map<String, File?> _documentos = {
    'antecedentes': null,
    'domicilio': null,
  };

  final PreferencesService _preferencesService = PreferencesService();
  @override
  void initState() {
    super.initState();
    print(widget.data);
    // 👇 SE EJECUTA AL ENTRAR A LA PÁGINA
    print("Entré a crear info de trabajador");
  }

  Future<void> _CrearSession() async {
    try {
      setState(() {
        isloading = true;
      });
      final result = await SessionDiditService.crear(
        user_id: widget.data['id'],
        token: widget.data['token'],
      );
      if (result['success'] != true) {}
      print('data ${result['data']}');

      final sessionToken = result['data']['session_token'];

      if (sessionToken == null || sessionToken.toString().isEmpty) {
        print('No se recibió session_token');
        setState(() {
          isloading = false;
        });
        return;
      }

      final verificationResult = await DiditSdk.startVerification(
        sessionToken.toString(),
        config: const DiditConfig(languageCode: 'es', loggingEnabled: true),
      );

      print('Resultado Didit: $verificationResult');

      switch (verificationResult) {
        case VerificationCompleted(:final session):
          switch (session.status) {
            case VerificationStatus.approved:
              print('Approved! Session: ${session.sessionId}');
              setState(() {
                _paginaActual++;
                isloading = false;
              });
              break;
            // User is verified — grant access
            case VerificationStatus.pending:
            case VerificationStatus.declined:
              print('Declined. Session: ${session.sessionId}');
              setState(() {
                isloading = false;
              });
              await Toast(
                context,
                title: "Verificación rechazada",
                message: "Tu documento no pudo ser validado.",
                type: alert_type.error,
              );
              break;
          }
          print('Verificación completada');
          print('Session ID: ${session.sessionId}');
          print('Status: ${session.status}');

        case VerificationCancelled(:final session):
          print('Usuario canceló la verificación');
          setState(() {
            isloading = false;
          });
          if (session != null) {
            print('Session ID: ${session.sessionId}');
          }

        case VerificationFailed(:final error):
          setState(() {
            isloading = false;
          });
          print('Error Didit: ${error.type} - ${error.message}');
      }
    } catch (e) {
      Future.microtask(() async {
        await Toast(
          context,
          title: "Error",
          message: "A ocurrido un error vuelve a intentarlo",
          type: alert_type.error,
        );
        setState(() {
          isloading = false;
        });
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

  void _Create() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DocumentsLoader(
        onRun: () => DocumentsService.Crear(
          // (image_ine: _documentos['ine_frontal'],
          // image_ine_reverso: _documentos['ine_trasera'],
          image_cd: _documentos['domicilio'],
          image_canp: _documentos['antecedentes'],
          id: widget.data['id'],
          token: widget.data['token'],
        ),
        onSuccess: (result) async {
          await Toast(
            context,
            title: "Documentos enviados correctamente",
            message:
                'Documentos enviados correctamente, espera nuestra respuesta por correo',
            type: alert_type.exito,
          );
          return;
        },
      ),
    );
  }

  Future<void> _pickImage(String key) async {
    final File? image = await pickAndCropDoc(context);

    if (image != null) {
      setState(() {
        _documentos[key] = image;
      });
    }
  }

  // Future<void> _pickImageIne(String key) async {
  //   final bool esIne = key == 'ine_frontal' || key == 'ine_trasera';

  //   if (esIne) {
  //     // Cámara propia con el marco guía dentro de la vista en vivo
  //     final File? image = await Navigator.push<File>(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => CamaraInePage(
  //           titulo: key == 'ine_frontal'
  //               ? 'Parte frontal de tu INE'
  //               : 'Parte trasera de tu INE',
  //         ),
  //       ),
  //     );

  //     if (image != null) {
  //       setState(() {
  //         _documentos[key] = image;
  //       });
  //     }
  //     return;
  //   }
  // }

  bool _esPdf(File archivo) => archivo.path.toLowerCase().endsWith('.pdf');

  void _abrirPdf(File archivo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VisorPdfPage(archivo: archivo)),
    );
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
                    horizontal: 0,
                    vertical: 0,
                  ),
                  child: Column(
                    children: [
                      if (_paginaActual == 0) _buildwelcome(),
                      if (_paginaActual == 2) _buildcanp(),
                      if (_paginaActual == 1) _buildDomicialrio(),
                      const SizedBox(height: 5),
                      if (_paginaActual != 0) ...[
                        _buildDots(),
                        const SizedBox(height: 30),
                      ],
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
          // Halo radial detrás del héroe
          Positioned(
            top: size.height * 0.13,
            left: 0,
            right: 0,
            child: Center(
              child:
                  Container(
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

          // Ilustración (héroe)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.52,
            child:
                Center(
                      child: Hero(
                        tag: 'info',
                        child: Image.asset(
                          'assets/docts.png',
                          width: size.width * 0.56,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.06,
                      end: 0,
                      duration: 700.ms,
                      curve: Curves.easeOutCubic,
                    ),
          ),

          // Scrim inferior para que el texto siempre sea legible
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.55,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withOpacity(0.0),
                      Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withOpacity(0.85),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    stops: const [0.0, 0.45, 0.75],
                  ),
                ),
              ),
            ),
          ),

          // Contenido inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child:
                Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
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
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.1,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Hola, ${widget.data['username']} ',
                                ),
                                TextSpan(
                                  text: 'Bienvenido',
                                  style: TextStyle(color: colorsecundario),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ya casi terminamos. Solo necesitamos verificar tu identidad y estos documentos:',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              height: 1.6,
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _requisitosPreview(),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDots(),
                              _circleNextButton(() {
                                _CrearSession();
                              }),
                            ],
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 700.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.06,
                      end: 0,
                      duration: 800.ms,
                      curve: Curves.easeOutCubic,
                    ),
          ),
        ],
      ),
    );
  }

  /// Pequeña vista previa de los documentos que se pedirán, para dar contexto
  /// en la pantalla de bienvenida.
  Widget _requisitosPreview() {
    final items = [
      {'icon': Icons.badge_outlined, 'label': 'Identidad'},
      {'icon': Icons.home_outlined, 'label': 'Domicilio'},
      {'icon': Icons.verified_user_outlined, 'label': 'Antecedentes'},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((it) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(it['icon'] as IconData, size: 15, color: colorsecundario),
              const SizedBox(width: 7),
              Text(
                it['label'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.75),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _circleNextButton(VoidCallback onPressed) {
    return GestureDetector(
      onTap: isloading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 58,
        height: 58,
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
        alignment: Alignment.center,
        child: isloading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(
                Icons.arrow_forward_rounded,
                color: colorWhite,
                size: 22,
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
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Tus documentos',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }

  Widget _nextButton(
    String label,
    VoidCallback onPressed, {
    IconData icon = Icons.arrow_forward_rounded,
  }) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorsecundario.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildIdentificacion() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         _buildSectionHeader(
  //           number: '1',
  //           title: 'Tu identificación',
  //           subtitle: 'Sube fotos de ambos lados de tu identificación (INE).',
  //         ),

  //         const SizedBox(height: 12),
  //         _tutorialLink('¿Cómo tomar la foto?', _mostrarTutorialIne),

  //         const SizedBox(height: 20),
  //         Row(
  //           children: [
  //             Expanded(child:
  //             Text(
  //               'Parte frontal',
  //               style: GoogleFonts.poppins(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.w600,
  //                 color: Theme.of(context).colorScheme.surface,
  //               ),
  //             )),

  //             const SizedBox(width: 8),
  //              _estadoChip('ine_frontal'),
  //           ],
  //         ),
  //         const SizedBox(height: 20),
  //         imageIneBox(
  //           'ine_frontal',
  //           'Coloca la parte frontal de tu INE dentro del marco, con buena luz y sin reflejos',
  //         ),
  //         const SizedBox(height: 20),
  //         Row(
  //           children: [
  //             Expanded(child:
  //             Text(
  //               'Parte trasera',
  //               style: GoogleFonts.poppins(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.w600,
  //                 color: Theme.of(context).colorScheme.surface,
  //               ),
  //             )),

  //             const SizedBox(width: 8),
  //             _estadoChip('ine_trasera'),
  //           ],
  //         ),
  //         const SizedBox(height: 20),
  //         imageIneBox(
  //           'ine_trasera',
  //           'Coloca la parte trasera de tu INE dentro del marco, con buena luz y sin reflejos',
  //         ),
  //         const SizedBox(height: 30),
  //         _nextButton('Siguiente', () {
  //             if (_documentos['ine_trasera'] == null ||_documentos['ine_frontal'] == null ) {
  //             Toast(
  //               context,
  //               title: 'Sube tu identificación',
  //               message: 'Debes subir ambos lados de tu INE para continuar',
  //               type: alert_type.advertencia,
  //             );
  //             return;
  //           }
  //           setState(() {
  //             _paginaActual++;
  //           });
  //         }),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildcanp() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionHeader(
            number: '3',
            title: 'Tu carta de antecedentes penales',
            subtitle:
                'Sube una foto o archivo PDF de tu carta de antecedentes penales.',
          ),

          const SizedBox(height: 12),

          // _tutorialLink(
          //   '¿Cómo debe verse mi documento?',
          //   _mostrarTutorialAntecedentes,
          // ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Documento',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),

              const SizedBox(width: 8),
              _estadoChip('antecedentes'),
            ],
          ),
          const SizedBox(height: 20),
          imageDocBox(
            'antecedentes',
            'Toma una foto o sube un PDF. Debe verse completo, legible y sin reflejos',
          ),
          const SizedBox(height: 30),
          _nextButton('Enviar documentos', () {
            if (_documentos['antecedentes'] == null) {
              Toast(
                context,
                title: 'Sube tu carta de antecedentes',
                message:
                    'Debes subir tu carta de antecedentes penales para continuar',
                type: alert_type.advertencia,
              );
              return;
            }
            _Create();
          }, icon: Icons.send_rounded),
        ],
      ),
    );
  }

  Widget _buildDomicialrio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionHeader(
            number: '2',
            title: 'Tu comprobante de domicilio',
            subtitle: 'Sube una foto o archivo de tu comprobante de domicilio.',
          ),
          const SizedBox(height: 12),
          // _tutorialLink(
          //   '¿Cómo debe verse mi comprobante?',
          //   _mostrarTutorialDomicilio,
          // ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Comprobante',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),

              const SizedBox(width: 8),
              _estadoChip('domicilio'),
            ],
          ),
          const SizedBox(height: 20),
          imageDocBox(
            'domicilio',
            'Toma una foto o sube un PDF. Debe tener menos de 3 meses de antigüedad',
          ),
          const SizedBox(height: 30),
          _nextButton('Continuar', () {
            if (_documentos['domicilio'] == null) {
              Toast(
                context,
                title: 'Sube tu comprobante de domicilio',
                message:
                    'Debes subir tu comprobante de domicilio para continuar',
                type: alert_type.advertencia,
              );
              return;
            }
            setState(() {
              _paginaActual++;
            });
          }),
        ],
      ),
    );
  }

  Widget _estadoChip(String key) {
    final bool listo = _documentos[key] != null;
    final Color color = listo ? const Color(0xFF22A55C) : colorsecundario;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            listo ? Icons.check_rounded : Icons.schedule_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            listo ? 'Listo' : 'Pendiente',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Abre el tutorial ilustrado de la INE (bottom sheet con carrusel).
  // Future<void> _mostrarTutorialIne() {
  //   return showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (_) => _TutorialSheet(
  //       titulo: 'Cómo tomar la foto de tu INE',
  //       subtitulo: 'Sigue estos pasos para que tu documento sea aceptado',
  //       labelFinal: 'Entendido',
  //       iconoFinal: Icons.camera_alt_rounded,
  //       pasos: [
  //         _TutorialPaso(
  //           ilustracion: _IlustracionFondoGenerica(
  //             sujeto: const _MiniIne(width: 130),
  //           ),
  //           titulo: 'Fondo plano y oscuro',
  //           descripcion:
  //               'Coloca tu INE sobre una superficie plana y de color liso, de preferencia oscura, para que resalte el documento.',
  //         ),
  //         _TutorialPaso(
  //           ilustracion: _IlustracionLuzGenerica(
  //             sujeto: const _MiniIne(width: 130),
  //           ),
  //           titulo: 'Buena luz, sin reflejos',
  //           descripcion:
  //               'Busca un lugar bien iluminado y desactiva el flash. Evita reflejos y sombras sobre la credencial.',
  //         ),
  //         _TutorialPaso(
  //           ilustracion: _IlustracionEncuadreGenerica(
  //             sujeto: const _MiniIne(width: 140),
  //           ),
  //           titulo: 'Encuadra las 4 esquinas',
  //           descripcion:
  //               'La INE debe verse completa dentro del marco, con las 4 esquinas visibles y el texto legible. No la cortes ni la inclines.',
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // /// Abre el tutorial ilustrado de la carta de antecedentes penales.
  // Future<void> _mostrarTutorialAntecedentes() {
  //   return showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (_) => _TutorialSheet(
  //       titulo: 'Cómo subir tu carta de antecedentes',
  //       subtitulo: 'Sigue estos pasos para que tu documento sea aceptado',
  //       labelFinal: 'Entendido',
  //       iconoFinal: Icons.upload_file_rounded,
  //       pasos: [
  //         _TutorialPaso(
  //           ilustracion: _IlustracionEncuadreGenerica(
  //             sujeto: const _MiniDocumento(
  //               width: 110,
  //               icon: Icons.gavel_rounded,
  //             ),
  //           ),
  //           titulo: 'Documento completo',
  //           descripcion:
  //               'La hoja debe verse completa dentro del marco, sin recortes ni dobleces que tapen el contenido.',
  //         ),
  //         _TutorialPaso(
  //           ilustracion: _IlustracionLuzGenerica(
  //             sujeto: const _MiniDocumento(
  //               width: 100,
  //               icon: Icons.gavel_rounded,
  //             ),
  //           ),
  //           titulo: 'Buena luz, sin reflejos',
  //           descripcion:
  //               'Busca un lugar bien iluminado y desactiva el flash. Evita reflejos y sombras sobre el papel.',
  //         ),
  //         _TutorialPaso(
  //           ilustracion: _IlustracionLegibilidad(
  //             sujeto: const _MiniDocumento(
  //               width: 100,
  //               icon: Icons.gavel_rounded,
  //             ),
  //           ),
  //           titulo: 'Texto legible',
  //           descripcion:
  //               'Verifica que el texto y los sellos se lean claramente antes de subir la foto o el PDF.',
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // /// Abre el tutorial ilustrado del comprobante de domicilio.
  // Future<void> _mostrarTutorialDomicilio() {
  //   return showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (_) => _TutorialSheet(
  //       titulo: 'Cómo subir tu comprobante de domicilio',
  //       subtitulo: 'Sigue estos pasos para que tu documento sea aceptado',
  //       labelFinal: 'Entendido',
  //       iconoFinal: Icons.upload_file_rounded,
  //       pasos: [
  //         _TutorialPaso(
  //           ilustracion: _IlustracionVigencia(
  //             sujeto: const _MiniDocumento(
  //               width: 110,
  //               icon: Icons.home_outlined,
  //             ),
  //           ),
  //           titulo: 'Documento vigente',
  //           descripcion:
  //               'Debe tener una antigüedad menor a 3 meses (recibo de luz, agua o telefonía).',
  //         ),
  //         _TutorialPaso(
  //           ilustracion: _IlustracionLuzGenerica(
  //             sujeto: const _MiniDocumento(
  //               width: 100,
  //               icon: Icons.home_outlined,
  //             ),
  //           ),
  //           titulo: 'Buena luz, sin reflejos',
  //           descripcion:
  //               'Busca un lugar bien iluminado y desactiva el flash. Evita reflejos y sombras sobre el papel.',
  //         ),
  //         _TutorialPaso(
  //           ilustracion: _IlustracionEncuadreGenerica(
  //             sujeto: const _MiniDocumento(
  //               width: 100,
  //               icon: Icons.home_outlined,
  //             ),
  //           ),
  //           titulo: 'Datos visibles',
  //           descripcion:
  //               'Tu nombre y domicilio deben leerse claramente, sin partes cortadas.',
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // /// Link tipo "¿Cómo tomar la foto?" que abre el bottom sheet de tutorial.
  // Widget _tutorialLink(String texto, VoidCallback onTap) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(Icons.help_outline_rounded, size: 16, color: colorsecundario),
  //         const SizedBox(width: 6),
  //         Expanded(child:
  //         Text(
  //           texto,
  //           style: GoogleFonts.poppins(
  //             fontSize: 12.5,
  //             fontWeight: FontWeight.w600,
  //             color: colorsecundario,
  //             decoration: TextDecoration.underline,
  //             decorationColor: colorsecundario,
  //           ),
  //         )),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSectionHeader({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorsecundario,
                colorsecundario.withOpacity(0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: colorsecundario.withOpacity(0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorWhite,
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
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
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget imageDocBox(String key, String label) {
    final File? archivo = _documentos[key];
    final size = MediaQuery.of(context).size;
    final double boxH = (size.height * 0.46).clamp(360.0, 460.0);

    // Estado vacío: caja para subir.
    if (archivo == null) {
      return GestureDetector(
        onTap: () => _pickImage(key),
        child: SizedBox(
          width: double.infinity,
          height: boxH,
          child: _buildDoc(label),
        ),
      );
    }

    // Estado con archivo cargado.
    final Widget contenido = _esPdf(archivo)
        ? _fondoPdf(
            archivo,
            onDelete: () => setState(() => _documentos[key] = null),
          )
        : Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  archivo,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              // Franja inferior con estado + acción "Cambiar"
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 22, 14, 12),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF22A55C),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Foto cargada',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      _miniAccion(
                        icon: Icons.autorenew_rounded,
                        label: 'Cambiar',
                        onTap: () => _pickImage(key),
                      ),
                    ],
                  ),
                ),
              ),

              // Botón eliminar
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => setState(() => _documentos[key] = null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );

    return GestureDetector(
      onTap: () => _pickImage(key),
      child: SizedBox(
        width: double.infinity,
        height: boxH,
        child: contenido
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(
              begin: const Offset(0.97, 0.97),
              end: const Offset(1, 1),
              curve: Curves.easeOut,
            ),
      ),
    );
  }

  /// Botón compacto (sobre fondo oscuro) para acciones dentro de la caja.
  Widget _miniAccion({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _miniaturaPdf(File archivo) async {
    if (_pdfThumbs.containsKey(archivo.path)) {
      return _pdfThumbs[archivo.path];
    }
    try {
      final doc = await PdfDocument.openFile(archivo.path);
      final page = await doc.getPage(1);
      final render = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      await doc.close();
      _pdfThumbs[archivo.path] = render?.bytes;
      return render?.bytes;
    } catch (_) {
      _pdfThumbs[archivo.path] = null;
      return null;
    }
  }

  /// Tarjeta para PDF subido: miniatura de la primera página + datos
  Widget _fondoPdf(File archivo, {VoidCallback? onDelete}) {
    final surface = Theme.of(context).colorScheme.surface;
    final nombre = archivo.path.split(Platform.pathSeparator).last;
    final kb = archivo.lengthSync() / 1024;
    final tamano = kb > 1024
        ? '${(kb / 1024).toStringAsFixed(1)} MB'
        : '${kb.toStringAsFixed(0)} KB';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colorsecundario.withOpacity(0.06),
        border: Border.all(color: colorsecundario.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List?>(
        future: _miniaturaPdf(archivo),
        builder: (context, snapshot) {
          // Con miniatura: primera página de fondo + franja con datos
          if (snapshot.hasData && snapshot.data != null) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(color: colorWhite),
                Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                // Franja inferior con nombre y tamaño
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0),
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tamano,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botón eliminar (arriba izquierda)
                if (onDelete != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Si es un PDF ya subido, tocarlo lo abre en el visor.
                // El botón "Cambiar" (tocar la caja) reemplaza el archivo.
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      _abrirPdf(archivo);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ver',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Sin miniatura todavía (cargando o falló): tarjeta con ícono
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: surface,
                  ),
                ),
              ),
              Text(
                'Toca para ver · $tamano',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: surface.withOpacity(0.45),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget imageIneBox(String key, String label) {
  //   return GestureDetector(
  //     onTap: () => _pickImageIne(key),
  //     child: SizedBox(
  //       width: double.infinity,
  //       height: 200,
  //       child: Stack(
  //         alignment: Alignment.center,
  //         clipBehavior: Clip.none,
  //         children: [
  //           _documentos[key] == null
  //               ? _buildIne(label)
  //               : Stack(
  //                       children: [
  //                         ClipRRect(
  //                           borderRadius: BorderRadius.circular(20),
  //                           child: Image.file(
  //                             _documentos[key]!,
  //                             width: double.infinity,
  //                             height: double.infinity,
  //                             fit: BoxFit.cover,
  //                           ),
  //                         ),
  //                         Positioned(
  //                           top: 6,
  //                           right: 6,
  //                           child: GestureDetector(
  //                             onTap: () {
  //                               setState(() {
  //                                 _documentos[key] = null;
  //                               });
  //                             },
  //                             child: Container(
  //                               padding: const EdgeInsets.all(4),
  //                               decoration: BoxDecoration(
  //                                 color: Colors.black.withOpacity(0.6),
  //                                 shape: BoxShape.circle,
  //                               ),
  //                               child: const Icon(
  //                                 Icons.close_rounded,
  //                                 size: 12,
  //                                 color: Colors.white,
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     )
  //                     .animate()
  //                     .fadeIn(duration: 300.ms)
  //                     .scale(
  //                       begin: const Offset(0.92, 0.92),
  //                       end: const Offset(1, 1),
  //                       curve: Curves.easeOutBack,
  //                     ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildIne(String label) {
  //   return Container(
  //     width: double.infinity,
  //     height: double.infinity,
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).colorScheme.surface.withOpacity(0.05),
  //       border: Border.all(
  //         color: Theme.of(context).colorScheme.surface.withOpacity(0.12),
  //       ),
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     padding: const EdgeInsets.all(20),
  //     child: Stack(
  //       alignment: Alignment.center,
  //       children: [
  //         Positioned.fill(
  //           child: CustomPaint(
  //             painter: _EsquinasGuiaPainter(color: colorsecundario),
  //           ),
  //         ),

  //         Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Image.asset(
  //               'assets/ine.png',
  //               width: 50,
  //               height: 50,
  //               color: colorsecundario,
  //               fit: BoxFit.contain,
  //             ),
  //             const SizedBox(height: 12),
  //             Padding(
  //               padding: const EdgeInsets.symmetric(horizontal: 40),
  //               child:Expanded(child:  Text(
  //                 label,
  //                 textAlign: TextAlign.center,
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 11.5,
  //                   fontWeight: FontWeight.w500,
  //                   color: Theme.of(
  //                     context,
  //                   ).colorScheme.surface.withOpacity(0.45),
  //                 ),
  //               )),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildDoc(String label) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: surface.withOpacity(0.04),
        border: Border.all(color: surface.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _EsquinasGuiaPainter(color: colorsecundario),
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: colorsecundario.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/carpeta.png',
                  width: 40,
                  height: 40,
                  color: colorsecundario,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: surface.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorsecundario,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: colorsecundario.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 18, color: colorWhite),
                    const SizedBox(width: 6),
                    Text(
                      'Toca para subir',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colorWhite,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'JPG · PNG · PDF',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: surface.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EsquinasGuiaPainter extends CustomPainter {
  _EsquinasGuiaPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double largo = 22;
    const double radio = 10;

    // Superior izquierda
    canvas.drawPath(
      Path()
        ..moveTo(0, largo)
        ..lineTo(0, radio)
        ..quadraticBezierTo(0, 0, radio, 0)
        ..lineTo(largo, 0),
      paint,
    );
    // Superior derecha
    canvas.drawPath(
      Path()
        ..moveTo(size.width - largo, 0)
        ..lineTo(size.width - radio, 0)
        ..quadraticBezierTo(size.width, 0, size.width, radio)
        ..lineTo(size.width, largo),
      paint,
    );
    // Inferior izquierda
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - largo)
        ..lineTo(0, size.height - radio)
        ..quadraticBezierTo(0, size.height, radio, size.height)
        ..lineTo(largo, size.height),
      paint,
    );
    // Inferior derecha
    canvas.drawPath(
      Path()
        ..moveTo(size.width - largo, size.height)
        ..lineTo(size.width - radio, size.height)
        ..quadraticBezierTo(
          size.width,
          size.height,
          size.width,
          size.height - radio,
        )
        ..lineTo(size.width, size.height - largo),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _EsquinasGuiaPainter oldDelegate) =>
      oldDelegate.color != color;
}