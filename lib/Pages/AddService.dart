import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/inputs/InputTap.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
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
  final _categoryController = TextEditingController();
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
        await Toast(
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
      Toast(
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
      Toast(
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
                    if (_paginaActual == 1) _buidFormularioCategoria(),
                    if (_paginaActual == 0) _buidFormularioInfo(),
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
      expandedHeight: 70,
      pinned: true, //  deja solo la barra pequeña visible
      floating: false, //  NO aparece al subir
      snap: false, // NO animación automática
      elevation: 0,
      toolbarHeight: 70,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      // bottom: PreferredSize(
      //   preferredSize: const Size.fromHeight(1),
      //   child: Divider(
      //     height: 1,
      //     thickness: 0.5,
      //     color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      //   ),
      // ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Nuevo Servicio',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
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
              // Imagen principal: scale + fade (entrada protagónica)
              imageperBox(0)
                  .animate()
                  .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 15),
              const SizedBox(height: 28),

              // ============ SECCIÓN 1: Información básica ============
              _buildSectionHeader(
                number: '1',
                title: 'Información básica',
                subtitle: 'Cuéntanos sobre tu servicio',
              )
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.15, curve: Curves.easeOutCubic),

              const SizedBox(height: 18),

              // Label + campo entran juntos desde abajo
              _fieldLabel('Categoria de servicio')
                  .animate(delay: 250.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
              const SizedBox(height: 16),
              CustomTextFormFieldTap(
                controller: _categoryController,
                label: 'Tipo de ayuda que necesitas',
                icon: Icons.category_outlined,
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona una categoría';
                  }
                  return null;
                },
                tap: () => setState(() => _paginaActual++),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.25, curve: Curves.easeOutCubic),

              const SizedBox(height: 16),
              _fieldLabel('Nombre de servicio')
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
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
              )
                  .animate(delay: 450.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.25, curve: Curves.easeOutCubic),

              const SizedBox(height: 15),
              _fieldLabel('Descripción de servicio')
                  .animate(delay: 550.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
              const SizedBox(height: 15),

              // Descripción: entrada con blur (más sutil para campo grande)
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
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 500.ms)
                  .blurXY(begin: 8, end: 0, duration: 500.ms)
                  .slideY(begin: 0.15, curve: Curves.easeOut),

              const SizedBox(height: 28),

              // ============ SECCIÓN 2: Precio y tiempo ============
              _buildSectionHeader(
                number: '2',
                title: 'Precio y tiempo',
                subtitle: 'Configura tu tarifa',
              )
                  .animate(delay: 750.ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.15, curve: Curves.easeOutCubic),

              const SizedBox(height: 18),

              Row(
                children: [
                  // Precio: entra desde la izquierda
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Precio promedio'),
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
                    )
                        .animate(delay: 850.ms)
                        .fadeIn(duration: 450.ms)
                        .slideX(begin: -0.3, curve: Curves.easeOutCubic),
                  ),
                  const SizedBox(width: 25),
                  // Tiempo: entra desde la derecha (efecto espejo)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Precio promedio'),
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
                    )
                        .animate(delay: 950.ms)
                        .fadeIn(duration: 450.ms)
                        .slideX(begin: 0.3, curve: Curves.easeOutCubic),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Card de consejo: scale + fade (llama la atención)
          _buildInfoCard(
            icon: Icons.tips_and_updates_outlined,
            text:
                'Consejo: Investiga precios de servicios similares '
                'en tu zona para ser competitivo.',
          )
              .animate(delay: 1100.ms)
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              )
              .shimmer(
                delay: 1600.ms,
                duration: 1200.ms,
                color: Colors.white.withValues(alpha: 0.3),
              ),

          const SizedBox(height: 28),

          // ============ SECCIÓN 3: Galería ============
          _buildSectionHeader(
            number: '3',
            title: 'Galería de imágenes',
            subtitle:
                'Agrega imágenes que representen tu servicio (4 imágenes)',
          )
              .animate(delay: 1250.ms)
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.15, curve: Curves.easeOutCubic),

          const SizedBox(height: 18),

          // Galería: cada imagen aparece en cascada con scale
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                imageBox(1)
                    .animate(delay: 1400.ms)
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(width: 30),
                imageBox(2)
                    .animate(delay: 1500.ms)
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(width: 30),
                imageBox(3)
                    .animate(delay: 1600.ms)
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(width: 30),
                imageBox(4)
                    .animate(delay: 1700.ms)
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(width: 30),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botón: entrada con bounce desde abajo (CTA principal)
          _nextButton('Crear', () {
           if (!(_formKey.currentState?.validate() ?? false)) return;
           _Crear();
          })
              .animate(delay: 1900.ms)
              .fadeIn(duration: 500.ms)
              .slideY(
                begin: 0.5,
                end: 0,
                curve: Curves.elasticOut,
                duration: 800.ms,
              ),
        ],
      ),
    ),
  );
}
  Widget _fieldLabel(String label) {
    return Row(
      children: [
        Expanded(child: 
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        )),
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
            ],
          ),
        ),
      ),
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
          isSelected: true,
          onSelected: (id) {
            setState(() {
              _categoriaSeleccionada = id;
              _categoryController.text = categoria.name;
              _paginaActual--;
            });
          },
        ).animate(delay: (index * 50).ms).fade().slideX(begin: -0.15);
      },
    ).animate().fade().slideX(begin: -0.2);
  }

  Widget imageperBox(int index) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: SizedBox(
        width: 450,
        height: 200,
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
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorsecundario.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 32,
                              color: colorsecundario,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Foto de portada',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toca para agregar la imagen principal',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
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
                        top: 15,
                        left: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Portada',
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

                      // Botón editar cuando hay imagen
                      Positioned(
                        top: 15,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: Colors.grey[800],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Cambiar',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
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

  Widget imageBox(int index) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: SizedBox(
        width: 130,
        height: 150,
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

}
