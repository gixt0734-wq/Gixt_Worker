import 'package:flutter/material.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/HomePage.dart';
import 'package:gixt_worker/pages/PerfilPage.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBottomNavigation extends StatefulWidget {
  const AppBottomNavigation({Key? key}) : super(key: key);

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation> {
  int _currentIndex = 0; // Iniciamos en el medio (Home)

  final List<Widget> _pages = const [
    HomePage(),
    // AgendaPage(),
    // AddServicePage(),
    Center(
      child: Text(
        'Trabajo',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    ),
     Center(
      child: Text(
        'Trabajo',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    ),
     Center(
      child: Text(
        'Trabajo',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    ),

    PerfilPage()
  ];

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: colorfondo,
      body: _pages[_currentIndex],
      // Usamos extendBody para que el contenido se vea detrás de la barra si es translúcida
      extendBody: true,
      bottomNavigationBar: isKeyboardOpen
          ? const SizedBox.shrink()
          : _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 25), // Margen para que flote
      height: 70,
      decoration: BoxDecoration(
        color: colorprimario,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, Icons.home_rounded, 0, "Home"),
          _buildNavItem(
            Icons.calendar_today_rounded,
            Icons.calendar_today,
            1,
            "Agenda",
          ),
         
          // BOTÓN CENTRAL ESTILO "CHIC"
          _buildMiddleItem(Icons.add_circle, 2),
          _buildNavItem(Icons.home_repair_service, Icons.home_repair_service, 3, "Trabajo"),
          _buildNavItem(Icons.person_rounded, Icons.person, 4, "Perfil"),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    int index,
    String label,
  ) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () async {
        if (_currentIndex == 2 && index != 2) {
          final salir = await _confirmarSalirExpress();
          if (!salir) return;
        }
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? colorsecundario : colorWhite.withOpacity(0.6),
            size: 28,
          ),
         Text(
            label,
           style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colorsecundario : colorWhite.withOpacity(0.4),
              ),
          ),
        ],
      ),
    );
  }

  // El botón circular "Chic" del centro (como en tu imagen)
  Widget _buildMiddleItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          // Si está seleccionado brilla, si no, mantiene un color sólido
          color: isSelected ? colorsecundario : colorsecundario.withOpacity(0.6),
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorsecundario..withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Icon(
          isSelected ? Icons.add_circle : Icons.add_circle,
          color: isSelected ?  colorWhite: Colors.white,
          size: 30,
        ),
      ),
    );
  }

 Future<bool> _confirmarSalirExpress() async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: colorprimario,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: colorWhite.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('¿Salir de Add Service',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600, color: colorWhite)),
                const SizedBox(height: 6),
                Text('Perderás el progreso de tu servicio.',
                    style: GoogleFonts.poppins(
                        fontSize: 13, height: 1.5,
                        color: colorWhite.withOpacity(0.45))),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: colorWhite.withOpacity(0.12)),
                        ),
                        child: Text('Cancelar',
                            style: GoogleFonts.poppins(fontSize: 14, color: colorWhite.withOpacity(0.55))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.red.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.red.withOpacity(0.3)),
                          ),
                        ),
                        child: Text('Salir',
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;
  }
}

// Colors.grey.withOpacity(0.6)
