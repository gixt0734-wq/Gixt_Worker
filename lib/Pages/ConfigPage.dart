import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Auth/DeleteAccount.dart';
import 'package:gixt_worker/Auth/Login.dart';
import 'package:gixt_worker/Auth/UpdatePassword.dart';
import 'package:gixt_worker/Components/ActionAlert%20.dart';
import 'package:gixt_worker/Components/CircleImage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/registro_loader.dart';
import 'package:gixt_worker/Config/SignalRService.dart';
import 'package:gixt_worker/Config/cache.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/Reports/ReportsPage.dart';
import 'package:gixt_worker/Pages/Skeletor/ConfigSkeletor.dart';
import 'package:gixt_worker/Pages/UpdatePerfilPage.dart';
import 'package:gixt_worker/Pages/WalletPage.dart';
import 'package:gixt_worker/providers/theme_provider.dart' show ThemeProvider;
import 'package:gixt_worker/services/user/User_service.dart';
import 'package:gixt_worker/services/user/update_active_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  bool isLoading = false;
  bool hasMore = true;
  bool timeout = false;
  final User_service user = User_service();
  final ScrollController _scrollController = ScrollController();
  final PreferencesService _preferencesService = PreferencesService();
  String? _gender;
  String? _imageUrl;
  File? _image;
  String? _img;
  String? _user;
  bool is_working = false;

  @override
  void initState() {
    super.initState();
    _Initial();
  }

  Future<void> _onRefresh() async {
    setState(() {
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
    _Validation();
  }

  Future<void> _Validation() async {
    print('empezando contador');
    Future.delayed(const Duration(seconds: 5), () {
      if (isLoading) {
        setState(() {
          timeout = true;
        });
        print('terminando contador');
      }
    });
    if (!mounted) return;
    setState(() {
      if (user.user.isNotEmpty) {
        hasMore = true;
        _gender = user.user[0].gender;
        is_working = user.user[0].is_working;
      }
    });
  }

  void _logout() async {
    bool? continuar = await ActionAlert(
      context,
      title: "Logout",
      message: 'Seguro que deseas cerrar sesión?',
      type: action_type.advertencia,
    );
    if (!continuar!) return;
    final prefs = await SharedPreferences.getInstance();

    bool ok = await SignalRService.disconnectServer();
    if (ok) {
      await prefs.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return;
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.pop(context), // cerrar al tocar
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  void _active() async {
    await _preferencesService.clearPreferencesWorking();
    await _preferencesService.savePreferencesWorking(!is_working);
    setState(() {
      is_working = !is_working;
    });
    await UpdateActvieService.Send();
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),

                    if (user.user.isEmpty) ...[
                      const ConfigSkeletor(),
                    ] else ...[
                      // HEADER: foto + nombre + email
                      _buildProfileHeader()
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1),
                      const SizedBox(height: 32),

                      // STATS
                      _buildStatsRow()
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms)
                          .slideY(begin: 0.1),

                      const SizedBox(height: 40),

                      // ACCIONES (lista tipo iOS settings)
                      _buildActionsList().animate().fadeIn(
                        duration: 400.ms,
                        delay: 200.ms,
                      ),
                      const SizedBox(height: 20),
                      _buildActionsListDelete().animate().fadeIn(
                        duration: 400.ms,
                        delay: 200.ms,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: 70,
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
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

  Widget _buildProfileHeader() {
    _imageUrl = "${user.user[0].image_url}";
    final fullName = "${user.user[0].first_name} ${user.user[0].last_name}"
        .trim();

    return Column(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  _showFullImage(_imageUrl ?? '');
                },
                child: Circleimage(image_url: _imageUrl, w: 150, h: 150),
              ),
              if (is_working)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Nombre
        Text(
          fullName.isEmpty ? 'Usuario' : fullName,
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
          user.user[0].email,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

Widget _buildStatsRow() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: _statItem(
            value: '${user.user[0].workers}',
            label: 'Trabajos',
          ),
        ),
        _statDivider(),
        SizedBox(width: 10,),
        Expanded(
          child: _statItem(
            value: '\$ ${user.user[0].balance}',
            label: 'Wallet',
            icon: user.user[0].has_balance
                ? Icons.moving_rounded
                : Icons.trending_down_outlined,
            iconColor: user.user[0].has_balance
                ? const Color(0xFF10B981)
                : Colors.red,
          ),
        ),
        SizedBox(width: 10,),
        _statDivider(),
        Expanded(
          child: _statItem(
            value: '0',
            label: 'Meses',
          ),
        ),
      ],
    ),
  );
}

  Widget _statItem({
    required String value,
    required String label,
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
           maxLines: 1,
            overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statDivider() {
    return 
    Container(
      height: 28,
      width: 1,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.08),
    );
  }

  Widget _buildActionsList() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _actionRowscroll(
            icon: is_working ? Icons.work_outline : Icons.bedtime_outlined,
            iconBgColor: is_working
                ? const Color(0xFF10B981).withOpacity(0.12)
                : colorsecundario.withOpacity(0.12),
            iconColor: is_working ? const Color(0xFF10B981) : colorsecundario,
            title: is_working ? 'Modo Activo' : 'Modo Descanso',
            subtitle: is_working ? 'Descansar' : 'Activar',
            onTap: _active,
          ),
          _rowDivider(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isDark = themeProvider.themeMode == ThemeMode.dark;
              return _actionRowscroll(
                icon: isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                iconBgColor: colorsecundario.withOpacity(0.12),
                iconColor: colorsecundario,
                title: 'Modo ${isDark ? "Claro" : "Oscuro"}',
                subtitle: 'Activa el modo ${isDark ? "claro" : "oscuro"}',
                onTap: () => themeProvider.toggleTheme(),
              );
            },
          ),
          _rowDivider(),
          _actionRow(
            icon: Icons.account_balance_wallet_rounded,
            iconBgColor: colorsecundario.withOpacity(0.12),
            iconColor: colorsecundario,
            title: 'Mi Wallet',
            subtitle: 'Gestiona tus ingresos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletPage()),
              );
            },
          ),
          _rowDivider(),
          _actionRow(
            icon: Icons.report_outlined,
            iconBgColor: colorsecundario.withOpacity(0.12),
            iconColor: colorsecundario,
            title: 'Mis Reportes',
            subtitle: 'Gestiona tus reportes',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsPage()),
              );
            },
          ),
          
          _rowDivider(),
          _actionRow(
            icon: Icons.update_outlined,
            iconBgColor: colorsecundario.withOpacity(0.12),
            iconColor: colorsecundario,
            title: 'Mis Informacion',
            subtitle: 'Actualiza tus datos personales',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Updateperfilpage()),
              );
            },
          ),
          _rowDivider(),
          // _actionRow(
          //   icon: Icons.location_on_outlined,
          //   iconBgColor: colorsecundario.withOpacity(0.12),
          //   iconColor: colorsecundario,
          //   title: 'Mis ubicaciones',
          //   subtitle: 'Gestiona tus zonas de trabajo',
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => const StripePage()),
          //     );
          //   },
          // ),
          _rowDivider(),
          _actionRow(
            icon: Icons.lock_outline_rounded,
            iconBgColor: colorsecundario.withOpacity(0.12),
            iconColor: colorsecundario,
            title: 'Cambiar contraseña',
            subtitle: 'Actualiza tu seguridad',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      Updatepassword(email: user.user[0].email),
                ),
              );
            },
          ),
          _rowDivider(),
          _actionRow(
            icon: Icons.logout_rounded,
            iconBgColor: colorError.withOpacity(0.12),
            iconColor: colorError,
            title: 'Cerrar sesión',
            subtitle: 'Salir de tu cuenta',
            onTap: _logout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsListDelete() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _rowDivider(),
          _actionRow(
            icon: Icons.delete_forever,
            iconBgColor: colorError.withOpacity(0.12),
            iconColor: colorError,
            title: 'Borrar Cuenta',
            subtitle: 'borrar tu cuenta',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Deleteaccount(
                    email: user.user[0].email,
                    img: user.user[0].image_url,
                  ),
                ),
              );
            },
            isDestructive: true,
          ),
        ],
      ),
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

  Widget _actionRowscroll({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart, // o startToEnd
      // 👇 ESTO evita que se elimine el item
      confirmDismiss: (direction) async {
        onTap?.call(); // acción del swipe
        return false; // NO elimina el widget
      },
      onDismissed: (direction) {
        onTap(); // o tu función de swipe
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colorsecundario,
        child: const Icon(Icons.refresh_outlined, color: Colors.white),
      ),
      child: Material(
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
}
