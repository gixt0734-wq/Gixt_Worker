// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:gixt/Componets/colors.dart';
// import 'package:gixt/pages/categoria.dart'; // Asegúrate que 'colorprimario' esté definido aquí

// class OptionsCategorias extends StatelessWidget {
//   final String nombre;
//   final int id;
//   final int? selectedId;
//   final ValueChanged<int> onSelected;

//   const OptionsCategorias({
//     super.key,
//     required this.nombre,
//     required this.id,
//     required this.selectedId,
//     required this.onSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isSelected = id == selectedId;

//     return InkWell(
//       onTap: () => onSelected(id),
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isSelected ? colorprimario : colorfondo,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           children: [
//             Container(
//               height: 60,
//               width: 60,
//               decoration: BoxDecoration(
//                 color: colorWhite,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.home_repair_service,
//                 color: colorprimario,
//               ),
//             ),

//             const SizedBox(width: 12),

//             Expanded(
//               child: Text(
//                 nombre,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: colorWhite,
//                 ),
//               ),
//             ),

//             Radio<int>(
//               value: id,
//               groupValue: selectedId,
//               activeColor: colorWhite,
//               onChanged: (value) {
//                 if (value != null) onSelected(value);
//               },
//             ),
//           ],
//         ),
//       ),
//     )
//         .animate()
//         .fade(duration: 300.ms)
//         .slideX(begin: -0.2);
//   }
// }
