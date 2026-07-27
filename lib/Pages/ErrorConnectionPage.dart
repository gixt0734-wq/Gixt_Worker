import 'package:flutter/material.dart';
import 'package:gixt_worker/Config/SignalRService.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/WelcomePage.dart';
import 'package:gixt_worker/routes/root.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ErrorConnectionPage extends StatelessWidget {
  const ErrorConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 100,color: colorsecundario,),
              const SizedBox(height: 20),
              const Text(
                "Sin conexión",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: colorsecundario),
              ),
              const SizedBox(height: 10),
              Text(
                "No fue posible conectar con el servidor.\nVerifica tu conexión a internet e inténtalo nuevamente.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                
                onPressed: () async {
                  bool ok = await SignalRService.connectServer();
                  final prefs = await SharedPreferences.getInstance();

                  if (ok && context.mounted) {
                    String? inicio = prefs.getString('inicio');

                    if (inicio == 'true') {
                      if (ok) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => RootPage()),
                        );
                        return;
                      }
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => WelcomePage()),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 50),
                backgroundColor: colorsecundario,
                foregroundColor: colorWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
