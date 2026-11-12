import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/inputs/Input.dart';
import 'package:gixt_worker/Components/inputs/Input_Description.dart';
import 'package:gixt_worker/Components/inputs/Input_Price.dart';
import 'package:gixt_worker/Components/inputs/Pick_Image.dart';
import 'package:gixt_worker/Config/Notifiers/express_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/home_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/services/Job/Add_extra_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:uuid/uuid.dart';

class AddExtraJobPage extends StatefulWidget {
  const AddExtraJobPage({
    super.key,
    required this.job_id,
    required this.isExpress,
    required this.methodpayment,
  });

  final String job_id;
  final String methodpayment;
  final bool isExpress;

  @override
  State<AddExtraJobPage> createState() => _AddExtraJobPageState();
}

class _AddExtraJobPageState extends State<AddExtraJobPage> {
  static const double _minPrice = 50;
  static const double _maxPriceCash = 2000;
  static const double _maxPriceCard = 150000;

  final _formKey = GlobalKey<FormState>();
  final _problemController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  File? _image;

  final String idempotencyKey = const Uuid().v4();
  double get _maxPrice =>
      widget.methodpayment == 'cash' ? _maxPriceCash : _maxPriceCard;

  @override
  void dispose() {
    _problemController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ---------------------------- Acciones --------------------------------------

  Future<void> _pickImage() async {
    final File? image = await pickAndCropImage(context);
    if (image != null) setState(() => _image = image);
  }

  void _removeImage() => setState(() => _image = null);

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_image == null) {
      Toast(
        context,
        title: 'Falta la imagen',
        message: 'Agrega una imagen como evidencia del nuevo problema',
        type: alert_type.error,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await AddExtraService.Send(
      job_id: widget.job_id,
      is_express: widget.isExpress,
      problem: _problemController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text),
      image: _image,
      idempotency_key: idempotencyKey,
    );

    if (!mounted) return;
    Navigator.pop(context); // cerrar loader

    if (result['success'] == true) {
      Future.microtask(() async {
        if (widget.isExpress) {
          expressNotifier.refresh();
        } else {
          jobsStatusNotifierFinish.refresh();
        }
        homeNotifier.refresh();
        Navigator.pop(context);
        await Toast(
          context,
          title: 'Extra enviado',
          message: 'Se notificará a tu cliente para que lo apruebe',
          type: alert_type.exito,
        );
      });
    } else {
      Navigator.pop(context);
      Toast(
        context,
        title: 'Error',
        message: result['message'],
        type: alert_type.error,
      );
    }
  }

  // ---------------------------- Validaciones ----------------------------------

  String? _requiredValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _priceValidator(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa el precio';

    final price = double.tryParse(value);
    if (price == null || price <= 0) return 'Ingresa un precio válido';
    if (price < _minPrice) {
      return 'El precio debe ser mayor o igual a \$${_minPrice.toStringAsFixed(0)}';
    }
    if (price > _maxPrice) {
      return 'El precio debe ser menor o igual a \$${_maxPrice.toStringAsFixed(0)}';
    }
    return null;
  }

  // ---------------------------- UI --------------------------------------------

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              sliver: SliverToBoxAdapter(child: _buildForm()),
            ),
          ],
        ),
        bottomNavigationBar: _bottomBar(context),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    final surface = Theme.of(context).colorScheme.surface;
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      pinned: true,
      elevation: 0,
      toolbarHeight: 70,
      centerTitle: true,
      iconTheme: IconThemeData(color: surface),
      title: Text(
        'Trabajo extra',
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: surface,
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      _buildSectionHeader(
        number: '1',
        title: 'Datos del extra',
        subtitle: 'Describe el problema adicional que encontraste.',
      ),
      const SizedBox(height: 20),
      CustomTextFormField(
        controller: _problemController,
        label: 'Problema',
        icon: Icons.report_problem_outlined,
        readOnly: false,
        validator: (v) => _requiredValidator(v, 'Por favor ingresa el problema'),
      ),
      const SizedBox(height: 20),
      CustomDescriptionFormField(
        controller: _descriptionController,
        minLines: 3,
        maxLines: 5,
        validator: (v) =>
            _requiredValidator(v, 'Por favor agrega una descripción'),
      ),
      const SizedBox(height: 25),
      _buildSectionHeader(
        number: '2',
        title: 'Precio del extra',
        subtitle:
            'Entre \$${_minPrice.toStringAsFixed(0)} y \$${_maxPrice.toStringAsFixed(0)}.',
      ),
      const SizedBox(height: 20),
      CustomTextFormFieldPrice(
        controller: _priceController,
        label: '\$ 0.00',
        validator: _priceValidator,
      ),
      const SizedBox(height: 25),
      _buildSectionHeader(
        number: '3',
        title: 'Imagen del nuevo problema',
        subtitle: 'Agrega una imagen de evidencia.',
      ),
      const SizedBox(height: 20),
      _imageBox(),
    ]



      ),
    );
  }

  Widget _buildSectionHeader({
    required String number,
    required String title,
    required String subtitle,
  }) {
    final surface = Theme.of(context).colorScheme.surface;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorsecundario.withValues(alpha: 0.12),
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
                  color: surface,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: surface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageBox() {
    return GestureDetector(
      onTap: _pickImage,
      child: SizedBox(
        width: 150,
        height: 200,
        child: _image == null ? _emptyImage() : _selectedImage(),
      ),
    );
  }

  Widget _emptyImage() {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.05),
        border: Border.all(color: surface.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.add_photo_alternate_outlined,
        size: 28,
        color: surface.withValues(alpha: 0.25),
      ),
    );
  }

  Widget _selectedImage() {
    return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(_image!, fit: BoxFit.cover),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
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
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child:
          SizedBox(
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
                    'Enviar',
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
