import 'package:flutter/material.dart';
import 'package:gixt_worker/config/colors.dart';
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

  // Controla la animación de "salto" en CADA cambio de status
  late final AnimationController _changeCtrl;
  late final Animation<double> _pop; // escala del centro
  static const Color _track = Color(0xFFE3E9F2);
  static const Color _descColor = Color(0xFF6B7A90);
  @override
  void initState() {
    super.initState();

    _changeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _pop = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.18,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_changeCtrl);

    if (widget.estadoTrabajo.toLowerCase() == 'completed') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _changeCtrl.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _changeCtrl.dispose();
    super.dispose();
  }

  String _labelForState(String state) {
    switch (state) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptado';
      case 'going':
        return 'En camino';
      case 'arrived':
        return 'En domicilio';
      case 'diagnosing':
        return 'Diagnosticando';
      case 'in_progress':
        return 'En proceso';
      case 'finalized':
        return 'Por finalizar';
      case 'completed':
        return 'Completado';
      case 'canceled':
        return 'Rechazado';
      case 'rejected':
        return 'Rechazado';
      default:
        return state;
    }
  }

  String _img(String state) {
    switch (state) {
      case 'pending':
        return 'assets/reloj.png';
      case 'accepted':
        return 'assets/manos.png';
      case 'going':
        return 'assets/truck.png';
      case 'arrived':
        return 'assets/house.png';
      case 'diagnosing':
        return 'assets/lupa.png';
      case 'in_progress':
        return 'assets/box.png';
      case 'finalized':
        return 'assets/aprobate.png';
      case 'completed':
        return 'assets/check.png';
      case 'canceled':
      case 'rejected':
        return 'assets/cancel.png';
      default:
        return state;
    }
  }

 String _descForState(String state) {
  switch (state) {
    case 'pending':
      return 'Estamos buscando un servicio disponible para ti.';
      
    case 'accepted':
      return 'Aceptaste el servicio. Revisa los detalles y prepárate para atenderlo.';
      
    case 'going':
      return 'Dirígete al domicilio del cliente para comenzar el servicio.';
      
    case 'arrived':
      return 'Llegaste al domicilio. Confirma tu llegada para continuar.';
      
    case 'diagnosing':
      return 'Evalúa el problema y determina el trabajo que se realizará.';
      
    case 'in_progress':
      return 'El servicio está en proceso. Completa el trabajo solicitado.';
      
    case 'finalized':
      return 'Terminaste el trabajo. Revisa los detalles y finaliza el servicio.';
      
    case 'completed':
      return '¡Servicio completado! El trabajo ha sido finalizado correctamente.';
      
    case 'canceled':
      return 'Este servicio fue cancelado y ya no requiere atención.';
      
    case 'rejected':
      return 'El servicio fue rechazado después del diagnóstico y ha finalizado.';
      
    default:
      return '';
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actual (centro, grande) + status
          AnimatedBuilder(
            animation: _changeCtrl,
            builder: (context, child) =>
                Transform.scale(scale: _pop.value, child: child),
            child: _centerBubble(current),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCanceled) ...[
                  _buildStepper(_currentIndex()),
                  const SizedBox(height: 5),
                ],
                Text(
                  textAlign: TextAlign.start,
                  _labelForState(current),
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: colorsecundario,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  _descForState(current),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Burbuja central: estado actual (grande) + label
  Widget _centerBubble(String state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          child: Image.asset(_img(state), fit: BoxFit.contain),
        ),
      ],
    );
  }


  Widget _buildStepper(int currentIndex) {
    final children = <Widget>[];
    for (var i = 0; i < _steps.length; i++) {
      final done = i < currentIndex;
      final active = i == currentIndex;
      children.add(_dot(done: done, active: active));
      if (i < _steps.length - 1) {
        children.add(Expanded(child: _connector(i < currentIndex)));
      }
    }
    return Row(children: children);
  }

  Widget _dot({required bool done, required bool active}) {
    final size = active ? 14.0 : 10.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (done || active) ? colorsecundario : _track,
       
      ),
    );
  }

  Widget _connector(bool filled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: filled ? colorsecundario : _track,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

}
