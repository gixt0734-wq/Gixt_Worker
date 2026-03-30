// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';

// class CustomerCart extends StatelessWidget {
//   const CustomerCart({
//     required this.id_empresa,
//     required this.link,
//     required this.empresa,
//   });

//   final String link;
//   final String empresa;
//   final String id_empresa;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
//       child: Card(
//         elevation: 0,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
//         color: const Color.fromARGB(255, 255, 255, 255),
//         margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 0),
//         child: InkWell(
//           // onTap: () {
//           //   Navigator.push(
//           //     context,
//           //     MaterialPageRoute(
//           //       builder: (context) => CompanyPage(id_empresa: id_empresa),
//           //     ),
//           //   );
//           // },
//           child: Padding(
//             padding: const EdgeInsets.all(10),
//             child: Row(
//               mainAxisSize: MainAxisSize.max,
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(100),
//                   child: SizedBox(
//                     width: 60,
//                     height: 60,
//                     child: Image.network(
//                       link,
//                       fit: BoxFit.cover,
//                       loadingBuilder:
//                           (
//                             BuildContext context,
//                             Widget child,
//                             ImageChunkEvent? loadingProgress,
//                           ) {
//                             if (loadingProgress == null) return child;
//                             return Center(
//                               child: CircularProgressIndicator(
//                                 value:
//                                     loadingProgress.expectedTotalBytes != null
//                                     ? loadingProgress.cumulativeBytesLoaded /
//                                           loadingProgress.expectedTotalBytes!
//                                     : null,
//                               ),
//                             );
//                           },
//                       errorBuilder: (context, object, stackTrace) {
//                         return const Icon(Icons.error); // O una imagen de error
//                       },
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 20),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               empresa,
//                               style: Theme.of(context).textTheme.titleMedium
//                                   ?.copyWith(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
