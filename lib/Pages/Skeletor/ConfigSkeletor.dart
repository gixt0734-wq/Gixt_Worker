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
import 'package:gixt_worker/Pages/UpdatePerfilPage.dart';
import 'package:gixt_worker/providers/theme_provider.dart' show ThemeProvider;
import 'package:gixt_worker/services/user/User_service.dart';
import 'package:gixt_worker/services/user/update_active_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigSkeletor extends StatelessWidget {
  const ConfigSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surface.withOpacity(0.4);
    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              
              _box(width: 140, height: 140, radius: 100, color: base),
              const SizedBox(height: 30),
              _box(width: 250, height: 20, radius: 50, color: base),
              const SizedBox(height: 16),
              _box(width: 200, height: 10, radius: 50, color: base),
              const SizedBox(height: 40),
              _box(width: double.infinity, height: 80, radius: 20, color: base),
              const SizedBox(height: 30),
              _box(width: double.infinity,height: 350, radius: 20, color: base, ),
              const SizedBox(height: 20),
              _box(width: double.infinity, height: 80, radius: 20, color: base),
              const SizedBox(height: 100),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1300.ms,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.07),
        )
        .fade(begin: 0.55, end: 1);
  }

  Widget _box({
    required double width,
    required double height,
    required double radius,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

 
}
