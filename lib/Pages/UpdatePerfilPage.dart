import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/Components/Loaders/update_loader.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/inputs/Input.dart';
import 'package:gixt_worker/Components/inputs/Input_Fecha.dart';
import 'package:gixt_worker/Components/inputs/Input_Phone.dart';
import 'package:gixt_worker/Components/inputs/Pick_Image.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/services/user/Update_service.dart';
import 'package:gixt_worker/services/user/User_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class Updateperfilpage extends StatefulWidget {
  const Updateperfilpage({super.key});

  @override
  State<Updateperfilpage> createState() => _UpdateperfilpageState();
}

class _UpdateperfilpageState extends State<Updateperfilpage> {
  bool isLoading = false;
  bool hasMore = true;
  final User_service user = User_service();
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _first_nameController = TextEditingController();
  final _last_nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birth_dateController = TextEditingController();
  final PreferencesService _preferencesService = PreferencesService();
  String? _gender;
  String? _imageUrl;
  File? _image;
  String? _img;
  String? _user;

  Future<void> _updateUser(String user, String img) async {
    await _preferencesService.clearPreferencesUser();
    await _preferencesService.savePreferencesUser(img, user);
    setState(() {
      _img = img;
      _user = user;
    });
  }

  void initState() {
    super.initState();
    print("Entré a Mi perfil");
    _Initial();
  }

  Future<void> _onRefresh() async {
    setState(() {
      print('Actualizando datos...');
      user.updatedata();
      hasMore = true;
    });
  }

  Future<void> _Initial() async {
    bool ok = await user.fetchUserData();
    if (!ok) {
      if (!mounted) return;
      Toast(
        context,
        title: "Error",
        message: "No se pudo obtener la información",
        type: alert_type.error,
      );
    }

    setState(() {
      print('Iniciando perfil');
      hasMore = true;
      _gender = user.user[0].gender;
    });
  }

 

   void _Crear() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateLoader(
        onRun: () => UpdateService.Crear(
          first_name: _first_nameController.text,
          last_name: _last_nameController.text,
          image: _image,
          phone: _phoneController.text,
          gender: _gender ?? "",
          birth_date: _birth_dateController.text,
        ),
        onSuccess: (result) async {
          final data = result['data'];
          Navigator.pop(context);
          Future.microtask(() async {
            Toast(
              context,
              title: "Datos Actualizados",
              message: 'tus datos se actualizo correctamente',
              type: alert_type.exito,
            );
            await user.updatedata();
            _updateUser(user.user[0].username, user.user[0].image_url);
          });
        },
      ),
    );
  }
  
  Future<void> _pickImage() async {
    final File? image = await pickAndCropImage(context);

    if (image != null) {
      setState(() {
        _image = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user.user.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Indicador()),
      );
    }

    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                     _PageHeader(
            'Informacion del Perfil',
            'Asegurate de que la información sea correcta, puedes actualizar tu foto de perfil, nombre, apellido, teléfono, fecha de nacimiento y género.',
          ),

                    const SizedBox(height: 20),
                    _buildIMGPerfil().animate().fade().slideX(begin: -0.2),
                    const SizedBox(height: 30),
                    _buidFormularioInfo().animate().fade().slideX(begin: -0.2),
                  ]),
                ),
              ),
            ],
          ),
        ),bottomNavigationBar: _bottomBar(context),
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
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.surface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
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
          'Mi Perfil',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
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

  Widget _genderChip(String value, String label, IconData icon) {
    
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorsecundario
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorsecundario
                  : Theme.of(context).colorScheme.surface.withOpacity(0.12),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorWhite
                    : Theme.of(context).colorScheme.surface.withOpacity(0.4),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? colorWhite
                      : Theme.of(context).colorScheme.surface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIMGPerfil() {
    _imageUrl = "${user.user[0].image_url}";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.07),
                    ),
                    child: ClipOval(
                      child: _image != null
                          ? Image.file(_image!, fit: BoxFit.cover)
                          : (_imageUrl != null && _imageUrl!.isNotEmpty)
                          ? Image(
                              image: CachedNetworkImageProvider(_imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.person_outline_rounded,
                              size: 52,
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.2),
                            ),
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

  Widget _buidFormularioInfo() {
    _first_nameController.text = user.user[0].first_name;
    _last_nameController.text = user.user[0].last_name;
    _emailController.text = user.user[0].email;
    _phoneController.text = user.user[0].phone;
    _birth_dateController.text = user.user[0].birth_date;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          const SizedBox(height: 20),
          /// NOMBRE
          CustomTextFormField(
            controller: _first_nameController,
            label: 'Nombre',
            readOnly: false,
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un nombre';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          /// APELLIDO
          CustomTextFormField(
            controller: _last_nameController,
            label: 'Apellido',
            readOnly: false,
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un apellido';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          /// CORREO
          CustomTextFormField(
            controller: _emailController,
            label: 'Correo',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            readOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un correo';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          /// TELÉFONO
          CustomTextFormFieldPhone(
            controller: _phoneController,
            label: 'Telefono',
            readOnly: false,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un telefono';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          /// FECHA NACIMIENTO (se queda como TextFormField por formatter)
          CustomTextFormFieldfecha(controller: _birth_dateController),

          const SizedBox(height: 20),

          /// GÉNERO
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GÉNERO',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  letterSpacing: 0.5,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.38),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  _genderChip('H', 'Hombre', Icons.male_rounded),
                  const SizedBox(width: 12),
                  _genderChip('M', 'Mujer', Icons.female_rounded),
                ],
              ),
            ],
          ),
          
          // TextButton(
          //   onPressed: () {},
          //   child: Text(
          //     'Eliminar Cuenta',
          //     style: TextStyle(color: Theme.of(context).colorScheme.surface),
          //   ),
          // ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              child: Icon(icon, size: 20, color: colorWhite),
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
          onPressed: () {_Crear();},
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: colorsecundario,
            foregroundColor: colorWhite,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.update, size: 20),
          label: Text(
            'Actualizar',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
