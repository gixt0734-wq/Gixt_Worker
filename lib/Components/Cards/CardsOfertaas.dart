import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class cardsofertas extends StatelessWidget {
  const cardsofertas({super.key, required this.link_imagen});
  final String link_imagen;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: link_imagen,
        fit: BoxFit.cover,
        // placeholder: (context, url) => Center(child: Indicador()),
        errorWidget: (context, url, error) => const Icon(Icons.broken_image),
      ),
    );
  }
}
