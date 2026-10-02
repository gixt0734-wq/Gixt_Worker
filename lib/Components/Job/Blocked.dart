import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Components/Job/InfoCard.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/ExpressPage.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/pages/ViewJobPage.dart';
import 'package:google_fonts/google_fonts.dart';

class Blocked extends StatelessWidget {
  const Blocked({
    super.key,

  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // Botón volver
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: cs.surface,
                  ),
                ),
              ),

              Hero(
                    tag: 'alerta',
                    child: Image.asset(
                      'assets/alerta.png',
                      width: size.width * 0.45,
                      fit: BoxFit.contain,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                    duration: 450.ms,
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 32),

              // Título
              Text(
                'Trabajo bloqueado',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: cs.surface,
                ),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 20),
              Text(
                'Tienes un saldo pendiente en tu wallet. Liquídalo para poder continuar con este trabajo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.5,
                  color: cs.surface.withValues(alpha: 0.6),
                ),
              ).animate().fade(duration: 450.ms, delay: 180.ms).slideX(begin: -0.2),

              const SizedBox(height: 36),

              const InfoCard(
                icon: Icons.account_balance_wallet_outlined,
                text: 'Puedes aceptar trabajos pagados con tarjeta para pagar tu adeudo.',
              ).animate().fade(duration: 450.ms, delay: 240.ms).slideX(begin: -0.2),

              const Spacer(),

              // ── Acción secundaria ──────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    'Regresar',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorsecundario,
                    ),
                  ),
                ),
              ).animate().fade(duration: 450.ms, delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
