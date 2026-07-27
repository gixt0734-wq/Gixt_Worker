import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfx/pdfx.dart';

/// Visor de PDF a pantalla completa con zoom (pinch) y contador de páginas.
///
/// Uso:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => VisorPdfPage(archivo: miArchivo, titulo: 'Carta de antecedentes'),
///   ));
class VisorPdfPage extends StatefulWidget {
  const VisorPdfPage({super.key, required this.archivo, this.titulo});

  final File archivo;
  final String? titulo;

  @override
  State<VisorPdfPage> createState() => _VisorPdfPageState();
}

class _VisorPdfPageState extends State<VisorPdfPage> {
  late final PdfControllerPinch _controller;

  int _paginaActual = 1;
  int _totalPaginas = 0;
  bool _errorCarga = false;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openFile(widget.archivo.path),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final nombre =
        widget.titulo ?? widget.archivo.path.split(Platform.pathSeparator).last;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: surface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: surface,
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_errorCarga)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 48,
                    color: surface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No se pudo abrir el PDF',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: surface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          else
            PdfViewPinch(
              controller: _controller,
              onDocumentLoaded: (doc) {
                setState(() => _totalPaginas = doc.pagesCount);
              },
              onPageChanged: (pagina) {
                setState(() => _paginaActual = pagina);
              },
              onDocumentError: (_) {
                setState(() => _errorCarga = true);
              },
              builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) => const Center(
                  child: CircularProgressIndicator(color: colorsecundario),
                ),
                pageLoaderBuilder: (_) => const Center(
                  child: CircularProgressIndicator(color: colorsecundario),
                ),
              ),
            ),

          // Contador de páginas
          if (_totalPaginas > 0 && !_errorCarga)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Página $_paginaActual de $_totalPaginas',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}