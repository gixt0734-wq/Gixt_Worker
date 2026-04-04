import 'package:flutter/material.dart';

class Gpsstatus extends StatefulWidget {
  const Gpsstatus({super.key, required this.status});
  final String status;

  @override
  State<Gpsstatus> createState() => _GpsstatusState();
}

class _GpsstatusState extends State<Gpsstatus>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _scale = Tween(begin: 1.0, end: 2.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _colorForState(String s) => switch (s) {
    'conectado' || 'ubicando'    => Colors.orange,
    'reconectando' || 'detenido' => Colors.red,
    'enviando ubicación'                       => Colors.green,
    _                             => Colors.grey,
  };



  @override
  Widget build(BuildContext context) {
    final color = _colorForState(widget.status);

    return Container(
          width: 42,
              height: 42,
    
      decoration: BoxDecoration(
        color:Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.5),
      ),
      child: 
        SizedBox(
          width: 20, height: 10,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Stack(alignment: Alignment.center, children: [
              Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(_opacity.value),
                  ),
                ),
              ),
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ]),
          ),
        ),
       
    );
  }
}