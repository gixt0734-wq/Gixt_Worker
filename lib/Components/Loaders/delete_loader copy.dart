// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:gixt_worker/Config/colors.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// enum _Estado { cargando, exito, error }

// class DeleteLoader extends StatefulWidget {
//   final Future<Map<String, dynamic>> Function() onRun;
//   final Future<void> Function(Map<String, dynamic> result) onSuccess;

//   const DeleteLoader({
//     super.key,
//     required this.onRun,
//     required this.onSuccess,
//   });

//   @override
//   State<DeleteLoader> createState() => _DeleteLoaderState();
// }

// class _DeleteLoaderState extends State<DeleteLoader> {
//   static const _pasos = <String>[
//     'Verificando tu identidad...',
//     'Eliminando tu información...',
//     'Cerrando tus sesiones...',
//     'Casi listo...',
//   ];

//   // Tiempo que se muestra cada paso como mínimo.
//   static const _duracionPaso = Duration(seconds: 2);

//   static const _red = Color(0xFFFF4D6A);

//   int _index = 0;
//   Timer? _timer;
//   Timer? _ultimoPasoTimer;
//   _Estado _estado = _Estado.cargando;
//   String _errorMsg = '';

//   // Coordinación pasos <-> servidor
//   bool _pasosCompletos = false;
//   bool _finalizado = false;
//   Map<String, dynamic>? _resultadoPendiente;
//   Map<String, dynamic>? _resultadoExito;

//   @override
//   void initState() {
//     super.initState();
//     _run();
//   }

//   void _run() {
//     _timer?.cancel();
//     _ultimoPasoTimer?.cancel();

//     setState(() {
//       _estado = _Estado.cargando;
//       _index = 0;
//     });

//     _pasosCompletos = false;
//     _finalizado = false;
//     _resultadoPendiente = null;
//     _resultadoExito = null;

//     // Avance de pasos independiente de la respuesta del servidor.
//     _timer = Timer.periodic(_duracionPaso, (t) {
//       if (_index < _pasos.length - 1) {
//         setState(() => _index++);

//         if (_index == _pasos.length - 1) {
//           t.cancel();
//           _ultimoPasoTimer = Timer(_duracionPaso, () {
//             _pasosCompletos = true;
//             _maybeFinish();
//           });
//         }
//       }
//     });

//     widget.onRun().then((result) {
//       if (!mounted) return;

//       if (result['success'] != true) {
//         _finalizado = true;
//         _timer?.cancel();
//         _ultimoPasoTimer?.cancel();
//         setState(() {
//           _estado = _Estado.error;
//           _errorMsg = result['message']?.toString() ??
//               'No pudimos eliminar tu cuenta en este momento.';
//         });
//         return;
//       }

//       _resultadoPendiente = result;
//       _maybeFinish();
//     }).catchError((e) {
//       if (!mounted) return;
//       _finalizado = true;
//       _timer?.cancel();
//       _ultimoPasoTimer?.cancel();
//       setState(() {
//         _estado = _Estado.error;
//         _errorMsg = 'No se pudo conectar. Revisa tu conexión e inténtalo otra vez.';
//       });
//     });
//   }

//   // Solo finaliza con éxito cuando los pasos terminaron Y el servidor respondió.
//   void _maybeFinish() {
//     if (_finalizado) return;
//     if (!_pasosCompletos) return;
//     if (_resultadoPendiente == null) return;

//     _finalizado = true;
//     _mostrarExito(_resultadoPendiente!);
//   }

//   Future<void> _mostrarExito(Map<String, dynamic> result) async {
//     if (!mounted) return;
//     setState(() {
//       _index = _pasos.length - 1;
//       _estado = _Estado.exito;
//       _resultadoExito = result;
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _ultimoPasoTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Bloquea el back mientras se elimina (evita estados a medias).
//     return PopScope(
//       canPop: _estado == _Estado.error,
//       child: Dialog(
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         elevation: 0,
//         insetPadding: EdgeInsets.zero,
//         child: SizedBox(
//           width: double.infinity,
//           height: double.infinity,
//           child: SafeArea(
//             child: AnimatedSwitcher(
//               duration: const Duration(milliseconds: 400),
//               child: _buildBody(),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBody() {
//     switch (_estado) {
//       case _Estado.cargando:
//         return _buildCargando();
//       case _Estado.exito:
//         return _buildExito();
//       case _Estado.error:
//         return _buildError();
//     }
//   }

//   // ══════════════════════════════════════════════════════════
//   // CARGANDO
//   // ══════════════════════════════════════════════════════════
//   Widget _buildCargando() {
//     final size = MediaQuery.of(context).size;
//     final cs = Theme.of(context).colorScheme;

//     return Padding(
//       key: const ValueKey('cargando'),
//       padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Center(
//             child: Hero(
//               tag: 'logo',
//               child: Image.asset(
//                 'assets/logo.png',
//                 width: size.width * 0.55,
//                 fit: BoxFit.contain,
//                 color: colorError,
//               ),
//             )
//                 .animate(onPlay: (c) => c.repeat(reverse: true))
//                 .scaleXY(
//                   begin: 1,
//                   end: 1.06,
//                   duration: 1600.ms,
//                   curve: Curves.easeInOut,
//                 ),
//           ),
//           const SizedBox(height: 48),

//           // Contador de paso
//           AnimatedSwitcher(
//             duration: const Duration(milliseconds: 350),
//             child: Text(
//               'PASO ${_index + 1} DE ${_pasos.length}',
//               key: ValueKey('count_$_index'),
//               textAlign: TextAlign.center,
//               style: GoogleFonts.poppins(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//                 letterSpacing: 2,
//                 color: cs.surface.withValues(alpha: 0.45),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),

//           // Paso actual
//           AnimatedSwitcher(
//             duration: const Duration(milliseconds: 400),
//             transitionBuilder: (child, anim) => FadeTransition(
//               opacity: anim,
//               child: SlideTransition(
//                 position: Tween(
//                   begin: const Offset(0, 0.18),
//                   end: Offset.zero,
//                 ).animate(CurvedAnimation(
//                   parent: anim,
//                   curve: Curves.easeOutCubic,
//                 )),
//                 child: child,
//               ),
//             ),
//             child: Text(
//               _pasos[_index],
//               key: ValueKey(_index),
//               textAlign: TextAlign.center,
//               style: GoogleFonts.poppins(
//                 fontSize: 30,
//                 height: 1.15,
//                 fontWeight: FontWeight.w700,
//                 color: colorError,
//                 letterSpacing: -0.4,
//               ),
//             ),
//           ),
//           const SizedBox(height: 14),

//           Text(
//             'No cierres la aplicación mientras\nprocesamos tu solicitud.',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.poppins(
//               fontSize: 12.5,
//               height: 1.6,
//               fontWeight: FontWeight.w400,
//               color: cs.surface.withValues(alpha: 0.45),
//             ),
//           ),
//           const SizedBox(height: 36),

//           // Barra de progreso
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: Stack(
//               children: [
//                 Container(
//                   height: 6,
//                   width: double.infinity,
//                   color: colorError.withValues(alpha: 0.15),
//                 ),
//                 AnimatedFractionallySizedBox(
//                   duration: const Duration(milliseconds: 500),
//                   curve: Curves.easeOutCubic,
//                   widthFactor: (_index + 1) / _pasos.length,
//                   child: Container(
//                     height: 6,
//                     decoration: BoxDecoration(
//                       color: colorError,
//                       borderRadius: BorderRadius.circular(10),
//                       boxShadow: [
//                         BoxShadow(
//                           color: colorError.withValues(alpha: 0.6),
//                           blurRadius: 10,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 50),
//         ],
//       ),
//     );
//   }

//   // ══════════════════════════════════════════════════════════
//   // ÉXITO
//   // ══════════════════════════════════════════════════════════
//   Widget _buildExito() {
//     final cs = Theme.of(context).colorScheme;

//     return Padding(
//       key: const ValueKey('exito'),
//       padding: const EdgeInsets.symmetric(horizontal: 32),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Center(
//             child: _CirculoIcono(color: colorError, icon: Icons.check_rounded)
//                 .animate()
//                 .scaleXY(
//                   begin: 0.7,
//                   end: 1,
//                   duration: 500.ms,
//                   curve: Curves.easeOutBack,
//                 )
//                 .fadeIn(duration: 300.ms),
//           ),
//           const SizedBox(height: 36),
//           Text(
//             'Cuenta eliminada',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.poppins(
//               fontSize: 26,
//               fontWeight: FontWeight.w700,
//               color: cs.surface,
//               letterSpacing: -0.5,
//             ),
//           )
//               .animate(delay: 200.ms)
//               .fadeIn(duration: 400.ms)
//               .slideY(begin: 0.2, end: 0),
//           const SizedBox(height: 10),
//           Text(
//             'Tu cuenta y tu información fueron eliminadas de forma permanente.',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.poppins(
//               fontSize: 13.5,
//               fontWeight: FontWeight.w400,
//               color: cs.surface.withValues(alpha: 0.55),
//               height: 1.7,
//             ),
//           )
//               .animate(delay: 350.ms)
//               .fadeIn(duration: 400.ms)
//               .slideY(begin: 0.2, end: 0),
//           const SizedBox(height: 26),

//           // Recordatorios
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: cs.surface.withValues(alpha: 0.04),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: cs.surface.withValues(alpha: 0.08)),
//             ),
//             child: Column(
//               children: [
//                 _itemInfo(
//                   Icons.login_rounded,
//                   'Ya no podrás iniciar sesión con esta cuenta.',
//                 ),
//                 const SizedBox(height: 12),
//                 _itemInfo(
//                   Icons.person_add_alt_rounded,
//                   'Si cambias de opinión, puedes registrarte de nuevo cuando quieras.',
//                 ),
//               ],
//             ),
//           )
//               .animate(delay: 450.ms)
//               .fadeIn(duration: 400.ms)
//               .slideY(begin: 0.2, end: 0),
//           const SizedBox(height: 32),

//           SizedBox(
//             height: 54,
//             child: ElevatedButton(
//               onPressed: _resultadoExito == null
//                   ? null
//                   : () => widget.onSuccess(_resultadoExito!),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: colorError,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//               child: Text(
//                 'Salir de Gixt',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 15,
//                 ),
//               ),
//             ),
//           ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3, end: 0),
//           const SizedBox(height: 14),
//           Text(
//             'Gracias por haber sido parte de Gixt 💙',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.poppins(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//               color: cs.surface.withValues(alpha: 0.35),
//             ),
//           ).animate(delay: 700.ms).fadeIn(),
//         ],
//       ),
//     );
//   }

//   Widget _itemInfo(IconData icon, String text) {
//     final cs = Theme.of(context).colorScheme;
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, size: 18, color: cs.surface.withValues(alpha: 0.45)),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Text(
//             text,
//             style: GoogleFonts.poppins(
//               fontSize: 12,
//               height: 1.55,
//               fontWeight: FontWeight.w400,
//               color: cs.surface.withValues(alpha: 0.55),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ══════════════════════════════════════════════════════════
//   // ERROR
//   // ══════════════════════════════════════════════════════════
//   Widget _buildError() {
//     final cs = Theme.of(context).colorScheme;

//     return Padding(
//       key: const ValueKey('error'),
//       padding: const EdgeInsets.symmetric(horizontal: 32),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Center(
//             child: Container(
//               width: 88,
//               height: 88,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _red.withValues(alpha: 0.12),
//                 border:
//                     Border.all(color: _red.withValues(alpha: 0.3), width: 2),
//               ),
//               child: const Icon(
//                 Icons.priority_high_rounded,
//                 color: _red,
//                 size: 42,
//               ),
//             )
//                 .animate(onPlay: (c) => c.repeat(reverse: true))
//                 .scaleXY(
//                   begin: 1,
//                   end: 1.06,
//                   duration: 1600.ms,
//                   curve: Curves.easeInOut,
//                 ),
//           ),
//           const SizedBox(height: 32),
//           Text(
//             'No pudimos eliminar tu cuenta',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.poppins(
//               fontSize: 21,
//               fontWeight: FontWeight.w700,
//               color: cs.surface,
//               letterSpacing: -0.3,
//             ),
//           ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2, end: 0),
//           const SizedBox(height: 10),
//           Text(
//             _errorMsg,
//             textAlign: TextAlign.center,
//             style: GoogleFonts.poppins(
//               fontSize: 13.5,
//               color: cs.surface.withValues(alpha: 0.5),
//               height: 1.6,
//             ),
//           ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2, end: 0),
//           const SizedBox(height: 12),
//           Center(
//             child: Container(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: cs.surface.withValues(alpha: 0.05),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 'Tu cuenta sigue activa',
//                 style: GoogleFonts.poppins(
//                   fontSize: 11.5,
//                   fontWeight: FontWeight.w600,
//                   color: cs.surface.withValues(alpha: 0.45),
//                 ),
//               ),
//             ),
//           ).animate(delay: 320.ms).fadeIn(),
//           const SizedBox(height: 44),
//           SizedBox(
//             height: 54,
//             child: ElevatedButton(
//               onPressed: _run,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: colorError,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//               child: Text(
//                 'Reintentar',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 15,
//                 ),
//               ),
//             ),
//           ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3, end: 0),
//           const SizedBox(height: 8),
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'Cancelar y conservar mi cuenta',
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.w500,
//                 fontSize: 13.5,
//                 color: cs.surface.withValues(alpha: 0.45),
//               ),
//             ),
//           ).animate(delay: 480.ms).fadeIn(),
//         ],
//       ),
//     );
//   }
// }

// class _CirculoIcono extends StatelessWidget {
//   final Color color;
//   final IconData icon;
//   const _CirculoIcono({required this.color, required this.icon});

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         Container(
//           width: 120,
//           height: 120,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: color.withValues(alpha: 0.08),
//           ),
//         ),
//         Container(
//           width: 88,
//           height: 88,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: color.withValues(alpha: 0.15),
//           ),
//         ),
//         Container(
//           width: 64,
//           height: 64,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: color,
//           ),
//           child: Icon(icon, color: Colors.white, size: 36),
//         ),
//       ],
//     );
//   }
// }