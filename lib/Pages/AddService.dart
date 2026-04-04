import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/components/Indicador.dart';
import 'package:gixt_worker/components/alert.dart';
import 'package:gixt_worker/components/categoriasoption.dart';
import 'package:gixt_worker/components/inputs/Input.dart';
import 'package:gixt_worker/components/inputs/Input_Description.dart';
import 'package:gixt_worker/components/inputs/Input_Price.dart';
import 'package:gixt_worker/components/inputs/Pick_Image.dart';
import 'package:gixt_worker/components/inputs/input_number.dart';
import 'package:gixt_worker/components/sketor/opciones.dart';
import 'package:gixt_worker/routes/root.dart';
import 'package:gixt_worker/services/servicios/Add_servicio_service.dart';
import 'package:gixt_worker/services/servicios/categorias_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // Importar el paquete http
import 'dart:convert'; // Para trabajar con JSON
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/services.dart';

class AddServicePage extends StatefulWidget {
  const AddServicePage({super.key});
  static bool tieneDatos = false;
  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _timeController = TextEditingController();
  final Categorias_service category = Categorias_service();
  int? _categoriaSeleccionada;

  int _paginaActual = 0;
  List<File?> _images = List.generate(5, (_) => null);

  bool isLoading = false;
  bool hasMore = true;
  bool timeout = false;

  void _Crear() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await AddServicioService.Crear(
      name: _nameController.text,
      description: _descriptionController.text,
      time: int.parse(_timeController.text),
      price: double.parse(_priceController.text),
      category_id: _categoriaSeleccionada!,
      images: _images.sublist(1), // Las imágenes adicionales
      image: _images[0]!, // La imagen principal
    );

    Navigator.pop(context);

    if (result['success'] == true) {
      final data = result['data'];
      String message =
          "Revisa tu nuevo servicio en la sección de mis servicios";
      Future.microtask(() async {
        await mostrarAlerta(
          context,
          title: "Creado exitosamente",
          message: message,
          type: alert_type.exito,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RootPage()),
        );
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

  Future<void> _pickImage(int index) async {
    final File? image = await pickAndCropImage(context);

    if (image != null) {
      setState(() {
        _images[index] = image;
      });
    }
  }

  Future<void> _Initial() async {
    setState(() {
      isLoading = true;
      timeout = false;
    });
    bool okData = await category.fetchCategoriasData();
    if (!okData) {
      if (!mounted) return;
      setState(() {});
      mostrarAlerta(
        context,
        title: "Error",
        message: "No se pudo obtener la información",
        type: alert_type.error,
      );
    }
    _Validation();
  }

  Future<void> _Validation() async {
    print('empezando contador');
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (isLoading) {
        setState(() {
          timeout = true;
        });
        print('terminando contador');
      }
    });
    if (!mounted) return;
    setState(() {
      if (category.categorias.isNotEmpty) {
        isLoading = false;
      }
    });
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

  void initState() {
    super.initState();
    // 👇 SE EJECUTA AL ENTRR A LA PÁGINA
    print("Entré a crear servicio");
    _Initial();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return salir();
      },
      child: KeyboardDismisser(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (_paginaActual == 0) _buidFormularioCategoria(),
                    if (_paginaActual == 1) _buidFormularioInfo(),
                    if (_paginaActual == 2) _buidFormularioImg(),
                    const SizedBox(height: 20),
                    _buildDots(),
                    const SizedBox(height: 150),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: 80,
      pinned: true, //  deja solo la barra pequeña visible
      floating: false, //  NO aparece al subir
      snap: false, // NO animación automática
      elevation: 0,
      toolbarHeight: 80,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Nuevo Servicio',
          style: GoogleFonts.poppins(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: colorsecundario,
          ),
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

  Widget _buidFormularioInfo() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PageHeader(
                  'Informacion del servicio',
                  'La categoria seleccionada es: ${category.categorias.firstWhere((cat) => cat.category_id == _categoriaSeleccionada)?.name ?? ''}',
                ),

                const SizedBox(height: 15),
                _buidText(label: 'Nombre de servicio'),
                const SizedBox(height: 15),
                CustomTextFormField(
                  controller: _nameController,
                  label: 'Nombre del servicio',
                  icon: Icons.person,
                  hint: 'Ej: Reparación de grifos',
                  readOnly: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el nombre del servicio';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),
                _buidText(label: 'Descripción de servicio'),
                const SizedBox(height: 15),

                /// DESCRIPCIÓN (multiline, se deja normal)
                CustomDescriptionFormField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 6,
                  hint:
                      'Ej: Ofrezco servicios de reparación de grifos, incluyendo instalación, mantenimiento y solución de problemas. Con años de experiencia, garantizo un trabajo de calidad y satisfacción del cliente.',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor descripcion';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buidText(label: 'Precio promedio'),
                          const SizedBox(height: 15),

                          CustomTextFormFieldPrice(
                            controller: _priceController,
                            label: 'Precio promedio',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese el precio';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 25),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buidText(label: 'Precio promedio'),
                          const SizedBox(height: 15),

                          CustomTextFormFieldNumber(
                            controller: _timeController,
                            label: 'Tiempo promedio',
                            icon: Icons.access_time,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese el tiempo en minutos';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildInfoCard(
            icon: Icons.tips_and_updates_outlined,
            text: 'Consejo: Investiga precios de servicios similares '
                  'en tu zona para ser competitivo.',
        
          ),
 SizedBox(height: 20),
            _nextButton('Siguiente', () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              setState(() {
                _paginaActual++;
              });
            }),

            const SizedBox(height: 20),
            _backButton(),
          ],
        ),
      ),
    );
  }

  Widget _buidText({required String label}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.6,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
          ),
        ),
      ],
    );
  }

  Widget _buidFormularioCategoria() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Categoría del servicio',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Selecciona la categoría que mejor describa tu servicio',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.6,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.45),
                ),
              ),

              _buildCategoriaItem(),
              const SizedBox(height: 0),
              ElevatedButton.icon(
                onPressed: () {
                  if (_categoriaSeleccionada == null) {
                    mostrarAlerta(
                      context,
                      title: 'Categoría requerida',
                      message: 'Por favor selecciona una categoría',
                      type: alert_type.advertencia,
                    );
                    return;
                  }
                  setState(() {
                    _paginaActual++;
                  });
                },

                /// 🔥 ESTILO
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: colorsecundario,
                  foregroundColor: colorWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                icon: const Icon(Icons.arrow_forward, size: 22),
                label: Text(
                  'Siguiente',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                    color: colorWhite,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _PageHeader(String title, String subtitle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            height: 1.6,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriaItem() {
    final isLoading = category.categorias.isEmpty;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: 16,
        childAspectRatio: 4,
      ),
      itemCount: isLoading ? 3 : category.categorias.length,
      itemBuilder: (context, index) {
        if (isLoading) {
          return const OptionsSkeleton();
        }
        final categoria = category.categorias[index];
        return OptionsCategorias(
          nombre: categoria.name,
          img: categoria.image_url,
          id: categoria.category_id,
          selectedId: _categoriaSeleccionada,
          onSelected: (id) {
            setState(() {
              _categoriaSeleccionada = id;
            });
          },
        );
      },
    ).animate().fade().slideX(begin: -0.2);
  }

  Widget _buidFormularioImg() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Column(
        children: [
          _PageHeader(
            'Imagen principal del servicio',
            'Agrega la imagen principal que represente tu servicio',
          ),
          SizedBox(height: 10),
          imageperBox(0),
          SizedBox(height: 20),
          _PageHeader(
            'Imágenes del servicio',
            'Agrega imágenes que representen tu servicio (4 imágenes)',
          ),

          SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                imageBox(1),
                const SizedBox(width: 30),
                imageBox(2),
                const SizedBox(width: 30),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                imageBox(3),
                const SizedBox(width: 30),
                imageBox(4),
                const SizedBox(width: 30),
              ],
            ),
          ),
          SizedBox(height: 20),
          _buildInfoCard(      icon: Icons.photo_camera_outlined,
          text: 'Usa fotos de alta calidad con buena iluminación. '
                'Las imágenes profesionales aumentan las contrataciones.'),SizedBox(height: 20),
          _nextButton('Crear', () {
            if (_images.where((image) => image != null).length < 4) {
              mostrarAlerta(
                context,
                title: 'Imagen requerida',
                message: 'Por favor llena los 4 campos de imagen',
                type: alert_type.advertencia,
              );
              return;
            }
            _Crear();
          }),
          const SizedBox(height: 20),
          _backButton(),
        ],
      ),
    );
  }
  Widget imageperBox(int index) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: SizedBox(
        width: 350,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _images[index] == null
                ? Container(
                    width: 350,
                    height: 200,
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
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      _images[index]!,
                      width: 350,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  Widget imageBox(int index) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _images[index] == null
                ? Container(
                    width: 130,
                    height: 130,
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
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      _images[index]!,
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
          ],
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

  Widget _backButton() {
    return TextButton(
      onPressed: salir,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(
          context,
        ).colorScheme.surface.withOpacity(0.45),
      ),
      child: Text('Regresar', style: GoogleFonts.poppins(fontSize: 13)),
    );
  }


   Widget _buildInfoCard({
    required IconData icon,
    required String text,

  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:colorsecundario.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorsecundario.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: colorsecundario,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.55)
                    
              ),
            ),
          ),
        ],
      ),
    );
  }
}
