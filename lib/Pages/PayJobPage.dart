import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gixt_worker/Components/Indicador.dart';
import 'package:gixt_worker/Components/alert.dart';
import 'package:gixt_worker/Components/inputs/Input.dart';
import 'package:gixt_worker/Components/inputs/Input_Price.dart';
import 'package:gixt_worker/Components/inputs/Pick_Image.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/services/Evidence/Add_evidence_service.dart';
import 'package:gixt_worker/services/Job/finish_serivicio_service.dart';
import 'package:gixt_worker/services/material/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class PayJobPage extends StatefulWidget {
  const PayJobPage({
    super.key,
    required this.km_priece,
    required this.price,
    required this.job_id,
  });
  final double km_priece;
  final String job_id;
  final double price;
  @override
  State<PayJobPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayJobPage> {
  int _paginaActual = 0;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final List<MaterialModel> _materiales = [];

  double get _subtotalMateriales =>
      _materiales.fold(0, (sum, m) => sum + m.cost);

  double get _total =>
      widget.price + widget.km_priece + _subtotalMateriales + _iva;

  double get _iva =>
      (widget.price + widget.km_priece + _subtotalMateriales) * 0.16;
  void _addMaterial() {
    final nombre = _nameController.text.trim();
    final precio = double.tryParse(_priceController.text.trim()) ?? 0;

    if (nombre.isNotEmpty && precio > 0) {
      setState(() {
        _materiales.add(MaterialModel(name: nombre, cost: precio));
        _nameController.clear();
        _priceController.clear();
      });
    }
  }

  void deleteMaterial(index) {
    setState(() {
      _materiales.removeAt(index);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool salir() {
    Navigator.pop(context);
    return true;
  }

  void _Send() async {
    FocusScope.of(context).unfocus();
    bool? ok = await mostrarAlerta(
      context,
      title: 'Finalizar',
      message:
          'Asegurate que los precios esten correctos ya que no se pueden modificar despues de finalizar',
      type: alert_type.advertencia,
    );
    if (ok!) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Indicador(),
      );

      final result = await FinishSerivicioService.Send(
        job_id: widget.job_id,
        labor_cost: widget.price,
        km_cost: widget.km_priece,
        total: _total,
        material: _subtotalMateriales,
        iva: _iva,
        materials: _materiales,
      );

      Navigator.pop(context); // cerrar loader

      if (result['success'] == true) {
        final data = result['data'];
        print(data);

        Future.microtask(() async {
          await mostrarAlerta(
            context,
            title: "Costos enviado",
            message:
                "Se mostrarán los precios y espera la confirmación del pago.",
            type: alert_type.exito,
          );
          jobsStatusNotifierFinish.refresh();
          Navigator.pop(context);
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
                    Column(children: [_buildPay()]),
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

  Widget _buildPay() {
    return Column(
      children: [
        _buildSectionHeader('Desglose del servicio'),
        _buildRow('Mano de obra', '\$${widget.price.toStringAsFixed(0)}'),
        _buildRow(
          'Precio de visita',
          '\$${widget.km_priece.toStringAsFixed(0)}',
        ),
        _buildRow('Materiales', '\$${_subtotalMateriales.toStringAsFixed(0)}'),
        _buildRow('Iva', '\$${_iva.toStringAsFixed(0)}'),
        _buildSubtotal('\$${_total.toStringAsFixed(0)}'),
        const SizedBox(height: 28),

        _buildSectionHeader('Materiales utilizados'),
        for (var material in _materiales) ...[
          Row(
            children: [
              _removeitem(_materiales.indexOf(material)),
              Expanded(
                child: _buildRow(
                  material.name,
                  '\$${material.cost.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
        ],
        _buildSubtotal('\$${_subtotalMateriales.toStringAsFixed(0)}'),
        _buildAddMaterial(_materiales),

        const SizedBox(height: 28),

        _buildSectionHeader('Método de pago'),
        _buildPaymentMethodCard(),
        const SizedBox(height: 28),

        const SizedBox(height: 32),
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Finalizar trabajo',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Text(
            'Método de pago',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.money_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 15,
                ),
                SizedBox(width: 6),
                Text(
                  'Efectivo',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.surface,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.65),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
        ),
      ],
    );
  }

  Widget _buildSubtotal(String value) {
    final color = Theme.of(context).colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Subtotal',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.surface,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Precio
          if (_paginaActual == 2)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${_total.toStringAsFixed(0)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
            ),

          const SizedBox(width: 20),

          // Botón
          Expanded(
            child: GestureDetector(
              onTap: () {
                _Send();
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: colorsecundario,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 6),
                    Text(
                      'Finalizar',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMaterial(material) {
    return GestureDetector(
      onTap: () {
        _showAddMaterialSheet();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Agregar material',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.surface,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMaterialSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: KeyboardDismisser(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar centrado
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuevo material',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.surface,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Añade los detalles del material',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                Text(
                  'Nombre del material',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.7),
                    letterSpacing: -0.1,
                  ),
                ),

                const SizedBox(height: 10),
                CustomTextFormField(
                  controller: _nameController,
                  label: 'Ej. Cemento, Arena, Varilla...',
                  readOnly: false,
                  keyboardType: TextInputType.text,
                  icon: Icons.build_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el nombre del material';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 22),
                Text(
                  'Precio unitario',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.7),
                    letterSpacing: -0.1,
                  ),
                ),

                const SizedBox(height: 10),
                CustomTextFormFieldPrice(
                  controller: _priceController,
                  label: '\$ 0.00',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el precio';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Botones de acción
                ElevatedButton(
                  onPressed: () {
                    _addMaterial();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorsecundario,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Agregar',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _removeitem(material) {
    return GestureDetector(
      onTap: () {
        print("Eliminar material: ${material}");
        deleteMaterial(material);
        setState(() {});
      },
      child: Container(
        width: 30,
        height: 30,
        child: Icon(
          Icons.remove_rounded,
          color: Theme.of(context).colorScheme.surface,
          size: 20,
        ),
      ),
    );
  }
}
