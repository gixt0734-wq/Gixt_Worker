import 'package:flutter/material.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class Barstatus extends StatefulWidget {
  const Barstatus({super.key, required this.estadoTrabajo});

  final String estadoTrabajo;

  @override
  State<Barstatus> createState() => _BarstatusState();
}

class _BarstatusState extends State<Barstatus> with TickerProviderStateMixin {
  // Orden lineal de estados
  static const List<String> _steps = [
    'pending',
    'accepted',
    'in_progress',
    'finalized',
    'completed',
  ];

  // Controla el "cierre -> círculo -> apertura" en CADA cambio de status
  late final AnimationController _changeCtrl;
  late final Animation<double> _collapseAnim; // 0 -> 1 -> 0

  @override
  void initState() {
    super.initState();

    _changeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    // Secuencia: cerrar -> mantener -> abrir
    _collapseAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 40,
      ),
    ]).animate(_changeCtrl);

    // Si arranca ya completado, reproducimos la animación una vez
    if (widget.estadoTrabajo.toLowerCase() == 'completed') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _changeCtrl.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant Barstatus oldWidget) {
    super.didUpdateWidget(oldWidget);

    // En CUALQUIER cambio de status, reproducir la animación
    if (oldWidget.estadoTrabajo.toLowerCase() !=
        widget.estadoTrabajo.toLowerCase()) {
      _changeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _changeCtrl.dispose();
    super.dispose();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  // Aclara un color (para gradientes)
  Color _lighten(Color c, [double amt = 0.22]) =>
      Color.lerp(c, Colors.white, amt) ?? c;

  Color _colorForState(String state) {
    switch (state) {
      case 'pending':   return const Color(0xFF8B5CF6); // violeta
      case 'accepted':  return colorsecundario;          // #1E6AE1
      case 'going':
      case 'arrived':
      case 'diagnosing':
      case 'in_progress': return const Color(0xFFFB8C00); // naranja
      case 'finalized': return const Color.fromARGB(255, 80, 220, 239);  // rojo suave
      case 'completed': return const Color(0xFF22C55E);  // verde
      case 'canceled':  return const Color(0xFFEF5350);
      default:          return Colors.grey;
    }
  }

  IconData _iconForState(String state) {
    switch (state) {
      case 'pending':     return Icons.schedule_rounded;
      case 'accepted':    return Icons.thumb_up_alt_rounded;
      case 'going':       return Icons.directions_car_rounded;
      case 'arrived':     return Icons.location_on_rounded;
      case 'diagnosing':  return Icons.search_rounded;
      case 'in_progress': return Icons.autorenew_rounded;
      case 'finalized':   return Icons.price_check_rounded;
      case 'completed':   return Icons.check_rounded;
      case 'canceled':    return Icons.close_rounded;
      default:            return Icons.circle_outlined;
    }
  }

  // Ícono más simple para los puntos de la barra
  IconData _dotIconForState(String state) {
    switch (state) {
      case 'pending':     return Icons.schedule_outlined;
      case 'accepted':    return Icons.check_outlined;
      case 'in_progress': return Icons.autorenew_rounded;
      case 'finalized':   return Icons.price_check_outlined;
      case 'completed':   return Icons.check_circle_outline;
      default:            return Icons.circle_outlined;
    }
  }

  String _labelForState(String state) {
    switch (state) {
      case 'pending':     return 'Pendiente';
      case 'accepted':    return 'Aceptado';
      case 'going':       return 'En camino';
      case 'arrived':     return 'En domicilio';
      case 'diagnosing':  return 'Diagnosticando';
      case 'in_progress': return 'En proceso';
      case 'finalized':   return 'Por finalizar';
      case 'completed':   return 'Completado';
      case 'canceled':    return 'Cancelado';
      default:            return state;
    }
  }

  int _currentIndex() {
    final s = widget.estadoTrabajo.toLowerCase();
    final mapped = (s == 'going' || s == 'arrived' || s == 'diagnosing')
        ? 'in_progress'
        : s;
    final idx = _steps.indexOf(mapped);
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.estadoTrabajo.toLowerCase();
    final isCanceled = current == 'canceled';
    final activeColor = _colorForState(current);
    final currentIdx = _currentIndex();
    final targetIndex = currentIdx.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          'Estado del trabajo',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 22),

        // Barra de progreso con animación en cada cambio
        if (!isCanceled)
          SizedBox(
            height: 56,
            child: AnimatedBuilder(
              animation: _changeCtrl,
              builder: (context, _) {
                final collapse = _collapseAnim.value;
                final appear = collapse.clamp(0.0, 1.0);
                final backed = Curves.easeOutBack.transform(appear);

                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // La barra: se encoge/oculta hacia el centro
                    Opacity(
                      opacity: (1 - collapse).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scaleX: _lerp(1.0, 0.25, collapse),
                        alignment: Alignment.center,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: targetIndex),
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.easeInOutCubic,
                          builder: (context, animatedIndex, __) {
                            return _buildBar(
                              context,
                              animatedIndex,
                              currentIdx,
                              activeColor,
                            );
                          },
                        ),
                      ),
                    ),

                    // Círculo del estado actual (se queda al cerrar la barra)
                    if (collapse > 0.01) ...[
                      // Anillo que se expande
                      Opacity(
                        opacity: (appear * 0.30).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: _lerp(0.9, 1.7, appear),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: activeColor, width: 2),
                            ),
                          ),
                        ),
                      ),
                      // Burbuja principal
                      Opacity(
                        opacity: appear,
                        child: Transform.scale(
                          scale: _lerp(0.5, 1.0, backed),
                          child: _stateBurst(context, current, activeColor),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

        const SizedBox(height: 0),

        // Chip de estado — pill tipo glass, animado al cambiar
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.35),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(current),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeColor,
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _labelForState(current),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Fila de la barra (círculos + líneas) con relleno animado y gradientes
  Widget _buildBar(
    BuildContext context,
    double animatedIndex,
    int currentIdx,
    Color activeColor,
  ) {
    final surface = Theme.of(context).colorScheme.surface;

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        // Línea
        if (i.isOdd) {
          final lineIdx = i ~/ 2;
          final fill = (animatedIndex - lineIdx).clamp(0.0, 1.0);
          return Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: surface.withOpacity(0.10),
                borderRadius: BorderRadius.circular(0),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fill,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    gradient: LinearGradient(
                      colors: [activeColor, _lighten(activeColor)],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // Círculo
        final stepIdx = i ~/ 2;
        final stepState = _steps[stepIdx];
        final isActive = stepIdx == currentIdx;
        final isDone = stepIdx < currentIdx;

        return _stepDot(
          context,
          icon: _dotIconForState(stepState),
          isActive: isActive,
          isDone: isDone,
          activeColor: activeColor,
        );
      }),
    );
  }

  // Burbuja grande del estado actual durante la animación
  Widget _stateBurst(BuildContext context, String state, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_lighten(color, 0.10), color],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(_iconForState(state), size: 26, color: colorWhite),
    );
  }

  Widget _stepDot(
    BuildContext context, {
    required IconData icon,
    required bool isActive,
    required bool isDone,
    required Color activeColor,
  }) {
    if (isActive) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_lighten(activeColor, 0.10), activeColor],
          ),
          boxShadow: [
            BoxShadow(
              color: activeColor.withOpacity(0.40),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, size: 15, color: colorWhite),
      );
    }

    if (isDone) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_lighten(activeColor, 0.10), activeColor],
          ),
        ),
        child: const Icon(Icons.check_rounded, size: 15, color: colorWhite),
      );
    }

    // Pendiente
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.18),
          width: 1.5,
        ),
      ),
      child: Icon(
        icon,
        size: 14,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.25),
      ),
    );
  }
}