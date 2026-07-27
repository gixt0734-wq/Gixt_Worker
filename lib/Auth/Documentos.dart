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

  final Map<String, File?> _documentos = {
    'ine_frontal': null,
    'ine_trasera': null,
    'antecedentes': null,
    'domicilio': null,
  };

  final PreferencesService _preferencesService = PreferencesService();

  void initState() {
    super.initState();
    print(widget.data);
    // 👇 SE EJECUTA AL ENTRAR A LA PÁGINA
    print("Entré a crear info de trabajador");
    _Initial();
  }

  Future<void> _Initial() async {}

  Future<void> _Validation() async {}

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
      onRun: () => DocumentsService.Crear
      (image_ine: _documentos['ine_frontal'],
      image_ine_reverso: _documentos['ine_trasera'],
      image_cd: _documentos['domicilio'] ,
      image_canp: _documentos['antecedentes'] ,
      id: widget.data['id']),
      onSuccess: (result) async {
          await Toast(
            context,
            title: "Documentos enviados correctamente",
            message: 'Documentos enviados correctamente, espera nuestra respuesta por correo',
            type: alert_type.exito,
          );

         
          return;
          }

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

  Future<void> _pickImageIne(String key) async {
    final bool esIne = key == 'ine_frontal' || key == 'ine_trasera';

    if (esIne) {
      // Cámara propia con el marco guía dentro de la vista en vivo
      final File? image = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (_) => CamaraInePage(
            titulo: key == 'ine_frontal'
                ? 'Parte frontal de tu INE'
                : 'Parte trasera de tu INE',
          ),
        ),
      );

      if (image != null) {
        setState(() {
          _documentos[key] = image;
        });
      }
      return;
    }
  }

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
                      if (_paginaActual == 1) _buildIdentificacion(),
                      if (_paginaActual == 3) _buildcanp(),
                      if (_paginaActual == 2) _buildDomicialrio(),
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
            // Imagen persona (hero)
              Positioned(
              top: size.height * 0.15,
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
              height: size.height * 0.58,
              child: Center(
                child: Hero(
                  tag: 'info',
                  child: Image.asset(
                    'assets/docts.png',
                    width: size.width * 0.58,
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
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 42),
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
                        children:  [
                          TextSpan(text: 'Hola, ${widget.data['username']} '),
                          TextSpan(
                            text: 'Bienvenido',
                            style: TextStyle(color: colorsecundario),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '¡Ya casi terminamos! Ahora necesitamos los siguientes documentos: tu identificación, un comprobante de domicilio y tu carta de antecedentes penales.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        height: 1.75,
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 0),
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

  Widget _buildIdentificacion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionHeader(
            number: '1',
            title: 'Tu identificación',
            subtitle: 'Sube fotos de ambos lados de tu identificación (INE).',
          ),

          const SizedBox(height: 12),
          _tutorialLink('¿Cómo tomar la foto?', _mostrarTutorialIne),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: 
              Text(
                'Parte frontal',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                ),
              )),

              const SizedBox(width: 8),
               _estadoChip('ine_frontal'),
            ],
          ),
          const SizedBox(height: 20),
          imageIneBox(
            'ine_frontal',
            'Coloca la parte frontal de tu INE dentro del marco, con buena luz y sin reflejos',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: 
              Text(
                'Parte trasera',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                ),
              )),

              const SizedBox(width: 8),
              _estadoChip('ine_trasera'),
            ],
          ),
          const SizedBox(height: 20),
          imageIneBox(
            'ine_trasera',
            'Coloca la parte trasera de tu INE dentro del marco, con buena luz y sin reflejos',
          ),
          const SizedBox(height: 30),
          _nextButton('Siguiente', () {
              if (_documentos['ine_trasera'] == null ||_documentos['ine_frontal'] == null ) {
              Toast(
                context,
                title: 'Sube tu identificación',
                message: 'Debes subir ambos lados de tu INE para continuar',
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

  Widget _buildcanp() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionHeader(
            number: '1',
            title: 'Tu carta de antecedentes penales',
            subtitle:
                'Sube una foto o archivo PDF de tu carta de antecedentes penales.',
          ),

          const SizedBox(height: 12),
          _tutorialLink(
            '¿Cómo debe verse mi documento?',
            _mostrarTutorialAntecedentes,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: 
              Text(
                'Documento',
                style: GoogleFonts.poppins(
                  fontSize:  18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                ),
              )),

              const SizedBox(width: 8),
              _estadoChip('antecedentes'),
            ],
          ),
          const SizedBox(height: 30),
          imageDocBox(
            'antecedentes',
            'Toma una foto o sube un PDF. Debe verse completo, legible y sin reflejos',
          ),
          const SizedBox(height: 30),
          _nextButton('Crear', () {
            if (_documentos['antecedentes'] == null) {
              Toast(
                context,
                title: 'Sube tu carta de antecedentes',
                message: 'Debes subir tu carta de antecedentes penales para continuar',
                type: alert_type.advertencia,
              );
              return;
            }
          _Create();
     
          }),
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
            number: '1',
            title: 'Tu comprobante de domicilio',
            subtitle: 'Sube una foto o archivo de tu comprobante de domicilio.',
          ),
          const SizedBox(height: 12),
          _tutorialLink(
            '¿Cómo debe verse mi comprobante?',
            _mostrarTutorialDomicilio,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: 
              Text(
                'Comprobante',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                ),
              )),

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
          _nextButton('Crear', () {
            if (_documentos['domicilio'] == null) {
              Toast(
                context,
                title: 'Sube tu comprobante de domicilio',
                message: 'Debes subir tu comprobante de domicilio para continuar',
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
  Future<void> _mostrarTutorialIne() {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TutorialSheet(
        titulo: 'Cómo tomar la foto de tu INE',
        subtitulo: 'Sigue estos pasos para que tu documento sea aceptado',
        labelFinal: 'Entendido',
        iconoFinal: Icons.camera_alt_rounded,
        pasos: [
          _TutorialPaso(
            ilustracion: _IlustracionFondoGenerica(
              sujeto: const _MiniIne(width: 130),
            ),
            titulo: 'Fondo plano y oscuro',
            descripcion:
                'Coloca tu INE sobre una superficie plana y de color liso, de preferencia oscura, para que resalte el documento.',
          ),
          _TutorialPaso(
            ilustracion: _IlustracionLuzGenerica(
              sujeto: const _MiniIne(width: 130),
            ),
            titulo: 'Buena luz, sin reflejos',
            descripcion:
                'Busca un lugar bien iluminado y desactiva el flash. Evita reflejos y sombras sobre la credencial.',
          ),
          _TutorialPaso(
            ilustracion: _IlustracionEncuadreGenerica(
              sujeto: const _MiniIne(width: 140),
            ),
            titulo: 'Encuadra las 4 esquinas',
            descripcion:
                'La INE debe verse completa dentro del marco, con las 4 esquinas visibles y el texto legible. No la cortes ni la inclines.',
          ),
        ],
      ),
    );
  }

  /// Abre el tutorial ilustrado de la carta de antecedentes penales.
  Future<void> _mostrarTutorialAntecedentes() {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TutorialSheet(
        titulo: 'Cómo subir tu carta de antecedentes',
        subtitulo: 'Sigue estos pasos para que tu documento sea aceptado',
        labelFinal: 'Entendido',
        iconoFinal: Icons.upload_file_rounded,
        pasos: [
          _TutorialPaso(
            ilustracion: _IlustracionEncuadreGenerica(
              sujeto: const _MiniDocumento(
                width: 110,
                icon: Icons.gavel_rounded,
              ),
            ),
            titulo: 'Documento completo',
            descripcion:
                'La hoja debe verse completa dentro del marco, sin recortes ni dobleces que tapen el contenido.',
          ),
          _TutorialPaso(
            ilustracion: _IlustracionLuzGenerica(
              sujeto: const _MiniDocumento(
                width: 100,
                icon: Icons.gavel_rounded,
              ),
            ),
            titulo: 'Buena luz, sin reflejos',
            descripcion:
                'Busca un lugar bien iluminado y desactiva el flash. Evita reflejos y sombras sobre el papel.',
          ),
          _TutorialPaso(
            ilustracion: _IlustracionLegibilidad(
              sujeto: const _MiniDocumento(
                width: 100,
                icon: Icons.gavel_rounded,
              ),
            ),
            titulo: 'Texto legible',
            descripcion:
                'Verifica que el texto y los sellos se lean claramente antes de subir la foto o el PDF.',
          ),
        ],
      ),
    );
  }

  /// Abre el tutorial ilustrado del comprobante de domicilio.
  Future<void> _mostrarTutorialDomicilio() {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TutorialSheet(
        titulo: 'Cómo subir tu comprobante de domicilio',
        subtitulo: 'Sigue estos pasos para que tu documento sea aceptado',
        labelFinal: 'Entendido',
        iconoFinal: Icons.upload_file_rounded,
        pasos: [
          _TutorialPaso(
            ilustracion: _IlustracionVigencia(
              sujeto: const _MiniDocumento(
                width: 110,
                icon: Icons.home_outlined,
              ),
            ),
            titulo: 'Documento vigente',
            descripcion:
                'Debe tener una antigüedad menor a 3 meses (recibo de luz, agua o telefonía).',
          ),
          _TutorialPaso(
            ilustracion: _IlustracionLuzGenerica(
              sujeto: const _MiniDocumento(
                width: 100,
                icon: Icons.home_outlined,
              ),
            ),
            titulo: 'Buena luz, sin reflejos',
            descripcion:
                'Busca un lugar bien iluminado y desactiva el flash. Evita reflejos y sombras sobre el papel.',
          ),
          _TutorialPaso(
            ilustracion: _IlustracionEncuadreGenerica(
              sujeto: const _MiniDocumento(
                width: 100,
                icon: Icons.home_outlined,
              ),
            ),
            titulo: 'Datos visibles',
            descripcion:
                'Tu nombre y domicilio deben leerse claramente, sin partes cortadas.',
          ),
        ],
      ),
    );
  }

  /// Link tipo "¿Cómo tomar la foto?" que abre el bottom sheet de tutorial.
  Widget _tutorialLink(String texto, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline_rounded, size: 16, color: colorsecundario),
          const SizedBox(width: 6),
          Expanded(child: 
          Text(
            texto,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colorsecundario,
              decoration: TextDecoration.underline,
              decorationColor: colorsecundario,
            ),
          )),
        ],
      ),
    );
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

    return GestureDetector(
      onTap: () => _pickImage(key),
      child: SizedBox(
        width: double.infinity,
        height: 450,
        child: Stack(
          children: [
            if (archivo == null)
              _buildDoc(label)
            else if (_esPdf(archivo))
              _fondoPdf(archivo)
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  archivo,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            if (archivo != null && !_esPdf(archivo))
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _documentos[key] = null);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
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
  Widget _fondoPdf(File archivo) {
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

                // Indicador de que se puede abrir

                // Si es un PDF ya subido, tocarlo lo abre en el visor.
                // El botón "Cambiar" es el que reemplaza el archivo.
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      _abrirPdf(archivo!);
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

  Widget imageIneBox(String key, String label) {
    return GestureDetector(
      onTap: () => _pickImageIne(key),
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _documentos[key] == null
                ? _buildIne(label)
                : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              _documentos[key]!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _documentos[key] = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildIne(String label) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.05),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.12),
        ),
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
              Image.asset(
                'assets/ine.png',
                width: 50,
                height: 50,
                color: colorsecundario,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child:Expanded(child:  Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.45),
                  ),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDoc(String label) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.05),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.12),
        ),
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
              Image.asset(
                'assets/carpeta.png',
                width: 50,
                height: 50,
                color: colorsecundario,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.45),
                  ),
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

// ============================================================
// BOTTOM SHEET DE TUTORIAL (carrusel ilustrado, reutilizable)
// ============================================================

/// Un paso individual dentro de un tutorial (ilustración + texto).
class _TutorialPaso {
  const _TutorialPaso({
    required this.ilustracion,
    required this.titulo,
    required this.descripcion,
  });

  final Widget ilustracion;
  final String titulo;
  final String descripcion;
}

/// Bottom sheet genérico con un carrusel de pasos ilustrados.
class _TutorialSheet extends StatefulWidget {
  const _TutorialSheet({
    required this.titulo,
    required this.subtitulo,
    required this.pasos,
    required this.labelFinal,
    required this.iconoFinal,
  });

  final String titulo;
  final String subtitulo;
  final List<_TutorialPaso> pasos;
  final String labelFinal;
  final IconData iconoFinal;

  @override
  State<_TutorialSheet> createState() => _TutorialSheetState();
}

class _TutorialSheetState extends State<_TutorialSheet> {
  final PageController _controller = PageController();
  int _paso = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _siguiente() {
    if (_paso < widget.pasos.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final totalPasos = widget.pasos.length;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: surface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: surface,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.subtitulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: surface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 290,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _paso = i),
              children: widget.pasos
                  .map(
                    (p) => _PasoTutorial(
                      ilustracion: p.ilustracion,
                      titulo: p.titulo,
                      descripcion: p.descripcion,
                    ),
                  )
                  .toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPasos, (i) {
              final activo = _paso == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: activo ? 24 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: activo ? colorsecundario : surface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (_paso < totalPasos - 1)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Saltar',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: surface.withOpacity(0.4),
                      ),
                    ),
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _siguiente,
                  icon: Icon(
                    _paso < totalPasos - 1
                        ? Icons.arrow_forward_rounded
                        : widget.iconoFinal,
                    size: 18,
                  ),
                  label: Text(
                    _paso < totalPasos - 1 ? 'Siguiente' : widget.labelFinal,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
}

/// Página individual del tutorial (ilustración + título + descripción).
class _PasoTutorial extends StatelessWidget {
  const _PasoTutorial({
    required this.ilustracion,
    required this.titulo,
    required this.descripcion,
  });

  final Widget ilustracion;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        children: [
          SizedBox(height: 160, child: Center(child: ilustracion))
              .animate()
              .fadeIn(duration: 350.ms)
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                duration: 350.ms,
                curve: Curves.easeOut,
              ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: surface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: surface.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ILUSTRACIONES DEL TUTORIAL (dibujadas en Flutter, sin assets)
// ============================================================

/// Mini credencial INE genérica.
class _MiniIne extends StatelessWidget {
  const _MiniIne({this.width = 150});
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 0.63;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorsecundario.withOpacity(0.18),
            colorsecundario.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorsecundario.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(width * 0.06),
      ),
      padding: EdgeInsets.all(width * 0.07),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: width * 0.22,
            height: height * 0.55,
            decoration: BoxDecoration(
              color: colorsecundario.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.person,
              size: width * 0.15,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(width: width * 0.06),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lineaIne(width * 0.5, width),
                SizedBox(height: width * 0.035),
                _lineaIne(width * 0.38, width),
                SizedBox(height: width * 0.035),
                _lineaIne(width * 0.44, width),
                SizedBox(height: width * 0.035),
                _lineaIne(width * 0.3, width),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineaIne(double w, double base) {
    return Container(
      width: w,
      height: base * 0.028,
      decoration: BoxDecoration(
        color: colorsecundario.withOpacity(0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Mini hoja de documento genérica (carta / comprobante), con un ícono
/// central y líneas de texto simulando encabezado y cuerpo.
class _MiniDocumento extends StatelessWidget {
  const _MiniDocumento({this.width = 100, required this.icon});
  final double width;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.3;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorsecundario.withOpacity(0.16),
            colorsecundario.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorsecundario.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(width * 0.08),
      ),
      padding: EdgeInsets.all(width * 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: width * 0.22, color: colorsecundario),
          SizedBox(height: width * 0.1),
          _lineaDoc(width * 0.6, width),
          SizedBox(height: width * 0.06),
          _lineaDoc(width * 0.45, width),
          SizedBox(height: width * 0.06),
          _lineaDoc(width * 0.5, width),
          SizedBox(height: width * 0.06),
          _lineaDoc(width * 0.35, width),
          const Spacer(),
          _lineaDoc(width * 0.4, width),
        ],
      ),
    );
  }

  Widget _lineaDoc(double w, double base) {
    return Container(
      width: w,
      height: base * 0.045,
      decoration: BoxDecoration(
        color: colorsecundario.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Ilustración: [sujeto] sobre un fondo plano.
class _IlustracionFondoGenerica extends StatelessWidget {
  const _IlustracionFondoGenerica({required this.sujeto});
  final Widget sujeto;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      width: 200,
      height: 140,
      decoration: BoxDecoration(
        color: surface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: sujeto),
    );
  }
}

/// Ilustración: [sujeto] con buena luz (sol) y flash desactivado (prohibido).
class _IlustracionLuzGenerica extends StatelessWidget {
  const _IlustracionLuzGenerica({required this.sujeto});
  final Widget sujeto;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        sujeto,
        Positioned(
          top: -18,
          left: -14,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: Colors.amber,
              size: 26,
            ),
          ),
        ),
        Positioned(
          bottom: -14,
          right: -14,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flash_off_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ilustración: [sujeto] encuadrado con las 4 esquinas guía visibles.
class _IlustracionEncuadreGenerica extends StatelessWidget {
  const _IlustracionEncuadreGenerica({required this.sujeto});
  final Widget sujeto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _EsquinasGuiaPainter(color: colorsecundario),
            ),
          ),
          sujeto,
        ],
      ),
    );
  }
}

/// Ilustración: [sujeto] con un sello de vigencia (calendario), para
/// documentos que deben tener una antigüedad máxima.
class _IlustracionVigencia extends StatelessWidget {
  const _IlustracionVigencia({required this.sujeto});
  final Widget sujeto;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        sujeto,
        Positioned(
          top: -12,
          right: -18,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorsecundario.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: colorsecundario,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ilustración: [sujeto] con una lupa, indicando que el texto debe ser legible.
class _IlustracionLegibilidad extends StatelessWidget {
  const _IlustracionLegibilidad({required this.sujeto});
  final Widget sujeto;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        sujeto,
        Positioned(
          bottom: -10,
          right: -16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorsecundario.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_rounded,
              color: colorsecundario,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}
