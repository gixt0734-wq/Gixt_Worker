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

class PerfilWorkerSkeletor extends StatelessWidget {
  const PerfilWorkerSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surface.withOpacity(0.4);
    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSectionHeader( color: base),
              const SizedBox(height: 30),
              _box(width: double.infinity, height: 80, radius: 20, color: base),
              const SizedBox(height: 15),
              Row(
              children: [
                _box(width: 150, height: 80, radius: 20, color: base),
                const SizedBox(width: 16),
                _box(width: 150, height: 80, radius: 20, color: base),
              ]
              ),
              const SizedBox(height: 40),
              _buildSectionHeader( color: base),
              const SizedBox(height: 40),
              _box(width: double.infinity, height: 180, radius: 20, color: base),
              const SizedBox(height: 30),
        
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

   Widget _buildSectionHeader({ required Color color,}) {
    
    return Row(
      children: [
        _box(width: 32, height: 32, radius: 10, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _box(width: double.infinity, height: 30, radius: 10, color: color),
               const SizedBox(height: 10),
                _box(width: double.infinity, height: 15, radius: 10, color: color),
            ],
          ),
        ),
      ],
    );
  }
}
