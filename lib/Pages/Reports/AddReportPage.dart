import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/inputs/Input.dart';
import 'package:gixt_worker/Components/inputs/Input_Description.dart';
import 'package:gixt_worker/Components/inputs/Pick_Image.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/NotificationPage.dart';
import 'package:gixt_worker/services/Reports/Add_report_service.dart';
import 'package:gixt_worker/services/Reports/MotivesModel.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddReportPage extends StatefulWidget {
  const AddReportPage({
    super.key,
    required this.type,
    required this.id,
    required this.user,
    required this.type_job,
  });
  final String type;
  final String id;
  final String user;
  final String? type_job;
  @override
  State<AddReportPage> createState() => _AddReportPageState();
}

class _AddReportPageState extends State<AddReportPage> {
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _image;

  bool hayNotificacion = false;
  int _currentPage = 0;
  bool _isForward = true; // 👈 controla la dirección de la transición

  @override
  void initState() {
    super.initState();
  }

    Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
  print(widget.id);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await AddReportService.Create(
      id: widget.id,
      type: widget.type, 
      reason: _nameController.text, 
      description: _descriptionController.text,
      type_job: widget.type_job,
      image: _image,
    );
    

    Navigator.pop(context);

    if (result['success'] == true) {
      Future.microtask(() async {
        await Toast(
          context,
          title: "Reporte exitoso",
          message:"Nuestro equipo de Gixt revisara el reporte, espera la respuesta",
          type: alert_type.exito,
        );
        if (mounted) Navigator.pop(context);

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

  Future<void> _pickImage() async {
    final File? image = await pickAndCropImage(context);
    if (image != null) setState(() => _image = image);
  }

  bool salir() {
    if (_currentPage != 0) {
      setState(() {
        _isForward = false; // 👈 vamos hacia atrás
        _currentPage--; // vuelve al formulario
      });
      return false;
    } else {
      Navigator.pop(context);
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
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        // la página entrante se desliza desde el lado correcto
                        final isIncoming =
                            child.key == ValueKey(_currentPage);
                        final dx = (_isForward ? 1 : -1) *
                            (isIncoming ? 0.12 : -0.12);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(dx, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      ),
                      child: _currentPage == 0
                          ? _buildMotivosView(key: const ValueKey(0))
                          : KeyedSubtree(
                              key: const ValueKey(1),
                              child: _buildform(),
                            ),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _currentPage == 1 ? _bottomBar(context) : null,
        ),
      ),
    );
  }

  Widget _buildMotivosView({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildHeroIcon()
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
              duration: 500.ms,
            ),
        const SizedBox(height: 20),
        _buildHeader()
            .animate()
            .fadeIn(duration: 400.ms, delay: 120.ms)
            .slideY(begin: 0.12, curve: Curves.easeOutCubic),
        const SizedBox(height: 32),
        _buildActionsList(),
      ],
    );
  }

  Widget _buildform() {
    final items = <Widget>[
      _buildSectionHeader(
        number: '1',
        title: 'Datos del reporte',
        subtitle:
            'Puedes editar el título y la descripción del reporte antes de enviarlo.',
      ),
      const SizedBox(height: 25),
      CustomTextFormField(
        controller: _nameController,
        label: 'Tipo de reporte',
        icon: Icons.report_problem_outlined,
        readOnly: false,
        validator: (value) {
          if (value == null || value.isEmpty)
            return 'Por favor ingresa el problema';
          return null;
        },
      ),
      const SizedBox(height: 25),
      CustomDescriptionFormField(
        controller: _descriptionController,
        minLines: 3,
        maxLines: 5,
        validator: (value) {
          if (value == null || value.isEmpty)
            return 'Por favor agrega una descripción';
          return null;
        },
      ),
      const SizedBox(height: 25),
      _buildSectionHeader(
        number: '2',
        title: 'Evidencia del reporte',
        subtitle: 'Agrega una imagen de evidencia (Opcional).',
      ),
      const SizedBox(height: 20),
      imageBox(),
    ];

    // animación escalonada por cada bloque del formulario
    final animatedItems = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      animatedItems.add(
        items[i]
            .animate()
            .fadeIn(duration: 350.ms, delay: (50 * i + 100).ms)
            .slideY(begin: 0.12, curve: Curves.easeOutCubic),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: animatedItems,
      ),
    );
  }

  Widget _buildHeroIcon() {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: colorsecundario.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorsecundario.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              color: colorsecundario,
              size: 30,
            ),
          ),
        ),
      )
          // pulso sutil y continuo para que el ícono se sienta vivo
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1,
            end: 1.06,
            duration: 1600.ms,
            curve: Curves.easeInOut,
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
      iconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.surface, // 👈 color del ícono
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Reportes',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              color: Theme.of(context).colorScheme.surface,
              iconSize: 28,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationPage()),
                );
                setState(() {
                  hayNotificacion = false;
                });
              },
            ),

            if (hayNotificacion)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Nombre
        Text(
          'Por que quieres reportar a ${widget.user}?',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        // Email
        Text(
          'Tu reporte es anónimo, ${widget.user} no sabrá que fuiste tú quien lo reportó.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsList() {
    final motivos;
    switch (widget.type) {
      case 'client':
        motivos = (ReportMotivesService.getMotives(ReportType.workerToUser));
      case 'job':
        motivos = (ReportMotivesService.getMotives(ReportType.jobDispute));
      default:
        return const SizedBox();
    }

    final rows = <Widget>[];
    int i = 0;
    for (var motivo in motivos) {
      rows.add(_rowDivider());
      rows.add(
        _actionRow(
          icon: Icons.report_outlined,
          iconBgColor: colorsecundario.withOpacity(0.12),
          iconColor: colorsecundario,
          title: motivo.motive,
          subtitle: motivo.description,
          onTap: () {
            setState(() {
              _nameController.text = motivo.motive;
              _descriptionController.text = motivo.description;
              _isForward = true; // 👈 hacia adelante
              _currentPage++;
            });
          },
        )
            .animate()
            .fadeIn(duration: 350.ms, delay: (60 * i + 200).ms)
            .slideY(begin: 0.18, curve: Curves.easeOutCubic),
      );
      i++;
    }

    rows.add(_rowDivider());
    rows.add(
      _actionRow(
        icon: Icons.report_outlined,
        iconBgColor: colorsecundario.withOpacity(0.12),
        iconColor: colorsecundario,
        title: 'Otro',
        subtitle: 'Otro motivo que no esté en la lista.',
        onTap: () {
          setState(() {
            _isForward = true; // 👈 hacia adelante
            _currentPage++;
          });
        },
      )
          .animate()
          .fadeIn(duration: 350.ms, delay: (60 * i + 200).ms)
          .slideY(begin: 0.18, curve: Curves.easeOutCubic),
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: rows),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDestructive
                            ? colorError
                            : Theme.of(context).colorScheme.surface,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
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

  Widget imageBox() {
    return GestureDetector(
      onTap: () => _pickImage(),
      child: SizedBox(
        width: 150,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _image == null
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
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 28,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.25),
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          _image!,
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
                              _image = null;
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

  Widget _bottomBar(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _onSubmit,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: colorsecundario,
            foregroundColor: colorWhite,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.send_rounded, size: 20),
          label: Text(
            'Enviar reporte',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.3, curve: Curves.easeOutCubic),
    );
  }
}