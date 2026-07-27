import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';

class CardsImage extends StatelessWidget {
  const CardsImage({super.key, required this.url_img});

  final String url_img;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: SizedBox(
        width: 150, // 🔥 ANCHO FIJO OBLIGATORIO
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: colorWhite,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          child: InkWell(
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => RestaurantePage(id_restaurante: id_servicio),
              //   ),
              // );
            },
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: SizedBox(
                  height: double.maxFinite,
                  width: 150,
                  child: CachedNetworkImage(
                    imageUrl: url_img,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: Container(color: Colors.white24)
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 1200.ms)
                          .fade(begin: 0.4, end: 1),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
