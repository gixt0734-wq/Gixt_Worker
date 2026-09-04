import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gixt_worker/Components/ActionAlert%20.dart';
import 'package:gixt_worker/Components/Job/Button.dart';
import 'package:gixt_worker/Components/Job/FieldLabelDescription.dart';
import 'package:gixt_worker/Components/Job/PriceBreakdown.dart';
import 'package:gixt_worker/Components/Job/SectionCard.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/inputs/Input.dart';
import 'package:gixt_worker/Components/inputs/Input_Description.dart';
import 'package:gixt_worker/Components/inputs/Input_Price.dart';
import 'package:gixt_worker/Components/inputs/Pick_Image.dart';
import 'package:gixt_worker/Components/inputs/input_number.dart';
import 'package:gixt_worker/Config/Notifiers/express_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/home_notifiers.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/services/Evidence/Add_evidence_service.dart';
import 'package:gixt_worker/services/Express/Diagnostic_express_service.dart';
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
    required this.isExpress,
  });
  final double km_priece;
  final String job_id;
  final double price;
  final bool isExpress;
  @override
  State<PayJobPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayJobPage> {
  int _paginaActual = 0;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _priceMatController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<MaterialModel> _materiales = [];

  double get _subtotalMateriales =>
      _materiales.fold(0, (sum, m) => sum + m.cost);

  final List<String> _descriptionOptions = [
    'Se realizara el trabajo como lo pidio el cliente',
  ];

  double get _price{
    double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    double iva = price *0.16;
    double comision = price *0.10;
    return price +comision;
  }

  double get _price_iva {
    double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    double iva = _price *0.16;
    double comision = price *0.10;
    return iva;
  }
  double get _total {
    return _price + widget.km_priece + _subtotalMateriales + _price_iva;
  }

  double get _iva =>
      (widget.price + widget.km_priece + _subtotalMateriales) * 0.16;
  void _addMaterial() {
    final nombre =
        '${_nameController.text.trim()} (${_quantityController.text.trim()})';
    final precio = double.tryParse(_priceMatController.text.trim()) ?? 0;
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    final total = precio * quantity;
    if (nombre.isNotEmpty && total > 0) {
      setState(() {
        _materiales.add(MaterialModel(name: nombre, cost: total));
        _nameController.clear();
        _priceMatController.clear();
        _quantityController.clear();
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

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.price.toString();
  }

  bool salir() {
    Navigator.pop(context);
    return true;
  }

  void _Send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    bool? ok = await ActionAlert(
      context,
      title: 'Diagnostico',
      message:
          'Asegurate que los precios esten correctos ya que no se pueden modificar despues de finalizar',
      type: action_type.advertencia,
    );
    if (ok!) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Indicador(),
      );

      final result = await DiagnosticExpressService.Send(
        job_id: widget.job_id,
        total: _total,
        material: _subtotalMateriales,
        iva: _iva,
        labor_cost: double.tryParse(_priceController.text.trim()),
        description: _descriptionController.text,
        materials: _materiales,
        isexpress: widget.isExpress,
      );

      Navigator.pop(context); // cerrar loader

      if (result['success'] == true) {
        final data = result['data'];
        print(data);

        Future.microtask(() async {
          await Toast(
            context,
            title: "Costos enviado",
            message:
                "Se mostrarán los precios y espera la confirmación del pago.",
            type: alert_type.exito,
          );
          if (widget.isExpress) {
            expressNotifier.refresh();
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
    final surface = Theme.of(context).colorScheme.surface;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildSectionHeader(
            number: '1',
            title: 'Descripcion del diagnostico',
            subtitle: 'Agrega una descripción detallada del trabajo realizado',
          ),
          const SizedBox(height: 12),
          _buildDescriptionChips(),
          const SizedBox(height: 12),
          CustomDescriptionFormField(
            controller: _descriptionController,
            label: 'Descripción final',
            hint: 'Ej: Se tiene que cambiar lamaparas e cablerias',
            minLines: 3,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Por favor agrega una descripción';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(
            number: '2',
            title: 'Mano de obra',
            subtitle: 'Agrega el precio de la mano de obra',
          ),
          const SizedBox(height: 20),
          CustomTextFormFieldPrice(
            controller: _priceController,
            label: 'Precio de mano de obra',
            onChanged: (value) {
              setState(() {});
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese el precio';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(
            number: '3',
            title: 'Materiales utilizados',
            subtitle: 'Agrega los materiales utilizados en el trabajo',
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Desglose del servicio',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var material in _materiales) ...[
                  Row(
                    children: [
                      _removeitem(_materiales.indexOf(material)),
                      Expanded(
                        child: _priceLine(
                          material.name,
                          '\$${material.cost.toStringAsFixed(0)}',
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _buildAddMaterial(_materiales),
                if(_materiales.isNotEmpty)...[
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  thickness: 0.7,
                  color: surface.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: surface,
                        ),
                      ),
                    ),
                    Text(
                      '\$${_subtotalMateriales.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colorsecundario,
                      ),
                    ),
                  ],
                ),
                ]

              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(
            number: '4',
            title: 'Desglose de costo',
            subtitle: 'Revisa el desglose de los costos antes de enviar',
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Desglose del servicio',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _priceLine('Mano de obra + comsion', '${_price.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                  
                _priceLine('Mano de obra(IVA)', '${_price_iva.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _priceLine(
                  'Tarifa de traslado',
                  '${widget.km_priece.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _priceLine(
                  'Materiales',
                  '${_subtotalMateriales.toStringAsFixed(2)}',
                ),
              
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  thickness: 0.7,
                  color: surface.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: surface,
                        ),
                      ),
                    ),
                    Text(
                      '\$${_total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colorsecundario,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _descriptionOptions.map((option) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _descriptionController.text = option;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Text(
              option,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.7),
              ),
            ),
          ),
        );
      }).toList(),
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
          'Diagnosticar trabajo',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
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

  // Widget _buildRow(String label, String value) {
  //   return Column(
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 14),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               label,
  //               style: GoogleFonts.poppins(
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w400,
  //                 color: Theme.of(
  //                   context,
  //                 ).colorScheme.surface.withOpacity(0.65),
  //               ),
  //             ),
  //             Text(
  //               value,
  //               style: GoogleFonts.poppins(
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w500,
  //                 color: Theme.of(
  //                   context,
  //                 ).colorScheme.surface.withOpacity(0.85),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       Divider(
  //         height: 1,
  //         thickness: 0.5,
  //         color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
  //       ),
  //     ],
  //   );
  // }

  Widget _priceLine(String label, String value) {
    final surface = Theme.of(context).colorScheme.surface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: surface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Text(
          '\$${value}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: surface.withValues(alpha: 0.9),
          ),
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
                  '\$${_total.toStringAsFixed(2)}',
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
            child:Button(text: 'Enviar', icon: Icons.send, bgColor: colorsecundario, action: _Send,),
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
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color:Colors.transparent,
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

              const SizedBox(height: 8),
              FieldLabelDescription(label:'Nuevo material' , value: 'Añade los detalles del material',),
              const SizedBox(height: 20),

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cantidad',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.7),
                              letterSpacing: -0.1,
                            ),
                          ),

                          const SizedBox(height: 8),
                          CustomTextFormFieldNumber(
                            controller: _quantityController,
                            icon: Icons.numbers_rounded,
                            label: '1',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Cantidad';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 8),
                          CustomTextFormFieldPrice(
                            controller: _priceMatController,
                            label: '\$ 0.00',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Precio';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
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
