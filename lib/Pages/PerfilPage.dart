import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gixt_worker/Auth/Login.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/GPS/gps_tracking_page.dart';
import 'package:gixt_worker/Pages/PerfilworkerPage.dart';
import 'package:gixt_worker/components/Indicador.dart';
import 'package:gixt_worker/components/alert.dart';
import 'package:gixt_worker/components/inputs/Input.dart';
import 'package:gixt_worker/components/inputs/Input_Fecha.dart';
import 'package:gixt_worker/components/inputs/Input_Phone.dart';
import 'package:gixt_worker/components/inputs/Pick_Image.dart';
import 'package:gixt_worker/providers/theme_provider.dart';
import 'package:gixt_worker/services/user/User_service.dart';
import 'package:gixt_worker/services/user/update_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';


class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
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
      mostrarAlerta(
        context,
        title: "Error",
        message: "No se pudo obtener la información",
        type: alert_type.error,
      );
    }

    setState(() {
      print('Iniciando home');
      hasMore = true;
    });
  }

  void _logout() async {
    bool? continuar = await mostrarAlerta(
      context,
      title: "Logout",
      message: 'Seguro que deseas cerrar sesión?',
      type: alert_type.advertencia,
    );
    if (!continuar!) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _Crear() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await UpdateService.Crear(
      first_name: _first_nameController.text,
      last_name: _last_nameController.text,
      image: _image,
      phone: _phoneController.text,
      gender: _gender ?? "",
      birth_date: _birth_dateController.text,
    );

    Navigator.pop(context);

    if (result['success'] == true) {
      final data = result['data'];
      mostrarAlerta(
        context,
        title: "Datos Actualizados",
        message: 'tus datos se actualizo correctamente',
        type: alert_type.exito,
      );
      await user.updatedata();
      _updateUser(user.user[0].username, user.user[0].image_url);
    } else {
      mostrarAlerta(
        context,
        title: "Error",
        message: result['message'],
        type: alert_type.error,
      );
    }
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
                    const SizedBox(height: 30),

                    _buildIMGPerfil().animate().fade().slideX(begin: -0.2),

                    const SizedBox(height: 30),

                    _buildopcions().animate().fade().slideX(begin: -0.2),

                    const SizedBox(height: 40),

                    _buidFormularioInfo().animate().fade().slideX(begin: -0.2),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildopcions() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _actionTile(
            icon: Icons.location_on_outlined,
            color: colorsecundario,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PerfilWorkerPage(),
                ),
              );
            }
          ),

          const SizedBox(width: 12),

          _actionTile(
            icon: Icons.lock_outline_rounded,
            color: colorsecundario,
            onTap: () {
              // TODO: Navegar a cambiar contraseña
            },
          ),

          const SizedBox(width: 12),
          _actionTile(
            icon: Icons.logout_rounded,
            color: colorError,
            onTap: _logout,
          ),

          // const SizedBox(width: 12),
          // Consumer<ThemeProvider>(
          //   builder: (context, themeProvider, child) {
          //     final isDark = themeProvider.themeMode == ThemeMode.dark;
          //     return _actionTile(
          //       icon: isDark
          //           ? Icons.dark_mode_outlined
          //           : Icons.light_mode_outlined,

          //       color: colorsecundario,
          //       onTap: () => themeProvider.toggleTheme(),
          //     );
          //   },
          // ),
        ],
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
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
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
          'Mi Perfil',
          style: GoogleFonts.poppins(
            fontSize: 30,
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
    _gender = user.user[0].gender;
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorsecundario.withOpacity(0.08)
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
                    ? colorsecundario
                    : Theme.of(context).colorScheme.surface.withOpacity(0.4),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? colorsecundario
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
          _PageHeader(
            'Informacion del Perfil',
            'Asegurate de que la información sea correcta, puedes actualizar tu foto de perfil, nombre, apellido, teléfono, fecha de nacimiento y género.',
          ),

          const SizedBox(height: 20),

          const SizedBox(height: 30),

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
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _Crear,

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

              icon: const Icon(Icons.update, size: 22),
              label: Text(
                'Actuzalizar',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  color: colorWhite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {},
            child: Text(
              'Eliminar Cuenta',
              style: TextStyle(color: Theme.of(context).colorScheme.surface),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.surface.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              child: Icon(icon, size: 20, color: color),
            ),
          ],
        ),
      ),
    );
  }
}


