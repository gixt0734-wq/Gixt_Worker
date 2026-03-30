import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Circleimage extends StatelessWidget {
  const Circleimage({
    super.key,
    required this.image_url,
    required this.w,
    required this.h,
  });

  final double h;
  final double w;
  final String? image_url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // border: Border.all(color: colorsecundario, width: 2),
      ),
      child: ClipOval(
        child: image_url != null
            ? CachedNetworkImage(
                imageUrl: image_url!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white,
      child: const Icon(Icons.person, size: 30, color: Colors.grey),
    );
  }
}
