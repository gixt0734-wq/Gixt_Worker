import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Components/Job/Button.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/inputs/Input.dart';
import 'package:gixt_worker/Components/inputs/Input_Price.dart';
import 'package:gixt_worker/Components/inputs/Pick_Image.dart';
import 'package:gixt_worker/Config/Notifiers/express_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/home_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/services/Evidence/Add_evidence_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class Evidencejobpage extends StatefulWidget {
  const Evidencejobpage({
    super.key,
    required this.job_id,
    required this.isExpress,
  });
  final String job_id;
  final bool isExpress;
  @override
  State<Evidencejobpage> createState() => _EvidencejobpageState();
}

class _Material {
  String nombre;
  double precio;
  _Material({required this.nombre, required this.precio});
}

class _EvidencejobpageState extends State<Evidencejobpage> {
  List<File?> _images = List.generate(2, (_) => null);
  int get _filledCount => _images.where((image) => image != null).length;
  bool get _isComplete => _filledCount >= 2;

  @override
  void dispose() {
    super.dispose();
  }

  bool salir() {
    Navigator.pop(context);
    return true;
  }

  Future<void> _pickImage(int index) async {
    final File? image = await pickAndCropImage(context);

    if (image != null) {
      setState(() {
        _images[index] = image;
      });
    }
  }

  void sendevidence() async {
    FocusScope.of(context).unfocus();
    if (_images.where((image) => image != null).length < 2) {
      Toast(
        context,
        title: 'Imagen requerida',
        message: 'Por favor llena los 2 campos de imagen',
        type: alert_type.advertencia,
      );
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await AddEvidenceService.Send(
      job_id: widget.job_id,
      images: _images,
      is_express: widget.isExpress,
    );

    Navigator.pop(context); // cerrar loader

    if (result['success'] == true) {
      final data = result['data'];
      print(data);

      Future.microtask(() async {
        await Toast(
          context,
          title: "Evidencia enviada",
          message:
              "Tu evidencia ha sido enviada correctamente, el cliente verificará el trabajo y te notificará si es necesario realizar algún cambio",
          type: alert_type.exito,
        );
        if (widget.isExpress) {
          finishexpressNotifier.refresh();
        } else {
          jobsStatusNotifierFinish.refresh();
        }
        homeNotifier.refresh();
        Navigator.pop(context);
      });
    } else {
      Toast(
        context,
        title: "Error",
        message: result['message'],
        type: alert_type.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => salir(),
      child: KeyboardDismisser(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Column(children: [_buildEvidence()]),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _bottomBar(context),
        ),
      ),
    );
  }

  Widget _buildEvidence() {
    return Column(
      children: [
        _PageHeader(
              'Imágenes de evidencia',
              'Agrega 2 fotos del trabajo realizado para que el cliente pueda verificarlo',
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.12, curve: Curves.easeOut),
        const SizedBox(height: 22),
        _buildProgress()
            .animate()
            .fadeIn(delay: 80.ms, duration: 400.ms)
            .slideY(begin: 0.12, curve: Curves.easeOut),
        const SizedBox(height: 16),
        SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [imageBox(0), SizedBox(width: 20), imageBox(1)]),
        ),
      ],
    );
  }

  Widget imageBox(int index) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: SizedBox(
        width: 150,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _images[index] == null
                ? Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.05),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.12),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(
                            Icons.add_a_photo_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.35),
                            size: 24,
                          ),
                        
                        const SizedBox(height: 12),
                        Text(
                          'Foto ${index + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Toca para agregar',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.35),
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          _images[index]!,
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
                              _images[index] = null;
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
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      children: [
        Text(
          '$_filledCount de 2 fotos',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
          ),
        ),
        const Spacer(),
        Row(
          children: List.generate(2, (i) {
            final active = i < _filledCount;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(left: 6),
              width: active ? 24 : 12,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? colorsecundario
                    : Theme.of(context).colorScheme.surface.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _PageHeader(String title, String subtitle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorsecundario.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.photo_library_outlined,
            color: colorsecundario,
            size: 26,
          ),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.6,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
            ),
          ),
        ),
      ],
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: Theme.of(context).colorScheme.surface,
        onPressed: () => salir(),
      ),
      // bottom: PreferredSize(
      //   preferredSize: const Size.fromHeight(1),
      //   child: Divider(
      //     height: 1,
      //     thickness: 0.5,
      //     color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
      //   ),
      // ),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Evidencia',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Button(
        text: 'Enviar evidencia',
        icon: Icons.send,
        bgColor: colorsecundario,
        action: _isComplete ? sendevidence : null,
      ),
    );
  }
}
