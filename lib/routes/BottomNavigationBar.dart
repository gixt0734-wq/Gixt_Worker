import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:gixt_worker/Components/CardInfo.dart';
import 'package:gixt_worker/Config/TutorialKeys.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Pages/HomePage.dart';
import 'package:gixt_worker/Pages/JobsPage.dart';
import 'package:gixt_worker/Pages/PerfilworkerPage.dart';
import 'package:gixt_worker/pages/AgendaPage.dart';
import 'package:gixt_worker/pages/ConfigPage.dart';
import 'package:gixt_worker/Pages/AddService.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class AppBottomNavigation extends StatefulWidget {
  const AppBottomNavigation({
    Key? key,
    required this.index,
    this.showTuto = false,
  }) : super(key: key);
  final int index;
  final bool showTuto;
  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();

  static void showTutorial(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppBottomNavigationState>();
    state?._createTutorial();
    state?.tutorialCoachMark.show(context: context);
  }
}

class _AppBottomNavigationState extends State<AppBottomNavigation> {
  int _currentIndex = 0; // Iniciamos en el medio (Home)
  int _page = 0;
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  late TutorialCoachMark tutorialCoachMark;
  final List<TargetFocus> targets = [];
  bool isTutorialActive = false;

  Future<void> _startTutorial() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Ir a la página 0 y esperar a que termine la animación del nav (450ms)
    if (_currentIndex != 0) {
      _bottomNavigationKey.currentState?.setPage(0);
    }

    _createTutorial();
    tutorialCoachMark.show(context: context);
  }

  void _createTutorial() {
    final pasos = TutorialKeys.tutorialSteps;
    const int totalPaginas = 5;
    targets.clear();
    for (var i = 0; i < pasos.length; i++) {
      final step = pasos[i];
      targets.add(
        TargetFocus(
          identify: step.id,
          keyTarget: step.key,
          shape: ShapeLightFocus.Circle,
          enableTargetTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: CardInfo(
                title: step.title,
                description: step.description,
                paso: i + 1,
                total: pasos.length,
                onSelected: (_) {
                  debugPrint("Tutorial: $i");
                  debugPrint("Página actual: $_currentIndex");

                  // =====================================
                  // CAMBIAR PÁGINA SOLO SI EXISTE
                  // =====================================

                  final siguientePagina = i + 1;

                  if (siguientePagina < totalPaginas) {
                    debugPrint("Cambiando a página $siguientePagina");

                    _bottomNavigationKey.currentState?.setPage(siguientePagina);
                  } else {
                    debugPrint(
                      "Límite de páginas alcanzado. "
                      "No se cambia BottomNavigation.",
                    );
                  }

                  // =====================================
                  // EL TUTORIAL SÍ CONTINÚA
                  // =====================================

                  if (i < pasos.length - 1) {
                    tutorialCoachMark.next();
                  } else {
                    tutorialCoachMark.finish();
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      textSkip: "Saltar",
      paddingFocus: 10,
      onFinish: () {
        debugPrint("Tutorial terminado");
      },
      onSkip: () {
        debugPrint("Tutorial saltado");
        return true;
      },
    );
  }

  final List<Widget> _pages = const [
    HomePage(),
    AgendaPage(),
    JobsPage(),
    PerfilWorkerPage(),
    ConfigPage(),
  ];

  @override
  void initState() {
    super.initState();

    if (mounted) {
      setState(() {
        _currentIndex = widget.index;
      });
    }

   widget.showTuto
        ? WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _startTutorial();
            tutorialCoachMark.show(context: context);
          })
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CurvedNavigationBar(
            key: _bottomNavigationKey,
            index: _currentIndex,
            // ⚠️ NO pases `index: _currentIndex` aquí — deja que el nav maneje su propio estado visual
            height: 75,
            backgroundColor: Colors.transparent,
            color: colorsecundario,
            buttonBackgroundColor: colorsecundario,
            animationCurve: Curves.easeOutCubic,
            animationDuration: const Duration(milliseconds: 450),
            items: <Widget>[
              _buildNavIcon(HugeIcons.strokeRoundedHome02, 0, isCenter: false),
              _buildNavIcon(
                HugeIcons.strokeRoundedCalendar02,
                1,
                isCenter: false,
              ),
              _buildNavIcon(
                HugeIcons.strokeRoundedAddInvoice,
                2,
                isCenter: true,
              ),
              _buildNavIcon(HugeIcons.strokeRoundedLabor, 3, isCenter: false),
              _buildNavIcon(
                HugeIcons.strokeRoundedSettings02,
                4,
                isCenter: false,
              ),
            ],
            onTap: _onTabTapped,
          ),
          IgnorePointer(
            child: SizedBox(
              height: 75, // altura máxima/fija
              child: Row(
                children: [
                  _tutorialAnchor(TutorialKeys.homeKey, index: 0),
                  _tutorialAnchor(TutorialKeys.agendaKey, index: 1),
                  _tutorialAnchor(TutorialKeys.jobsKey, index: 2),
                  _tutorialAnchor(TutorialKeys.workerKey, index: 3),
                  _tutorialAnchor(TutorialKeys.configKey, index: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(dynamic icons, int index, {bool isCenter = false}) {
    return HugeIcon(icon: icons, size: 28, color: colorWhite);
  }

  Future<void> _onTabTapped(int index) async {
    // // Si estamos saliendo de Express (2), confirmar primero
    // if (_currentIndex == 2 && index != 2) {
    //   final salir = await _confirmarSalirExpress();
    //   if (!salir) {
    //     // Esperamos a que termine la animación actual antes de revertir
    //     await Future.delayed(const Duration(milliseconds: 50));
    //     if (mounted) {
    //       _bottomNavigationKey.currentState?.setPage(2);
    //     }
    //     return;
    //   }
    // }
    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }

  Widget _tutorialAnchor(GlobalKey key, {required int index}) {
    final bool isSelected = _currentIndex == index;
    final double lado = isSelected ? 58 : 48;
    final double desdeAbajo = isSelected ? 40 : 26;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint("Tutorial target: $index");

          _bottomNavigationKey.currentState?.setPage(index);
        },
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: desdeAbajo,
              child: Center(
                child: SizedBox(key: key, width: lado, height: lado),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmarSalirExpress() async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¿Salir de Add Service',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Perderás el progreso de tu servicio.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.5,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.45),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.55),
                          ),
                        ),
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
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          'Salir',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
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
