import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/components/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:google_fonts/google_fonts.dart';

class CardsAgenda extends StatelessWidget {
  const CardsAgenda({
    super.key,
    required this.image_url,
    required this.name,
    required this.job_id,
    required this.client_image,
    required this.client,
    required this.date,
    required this.time,
    required this.price,
    required this.description,
    required this.address,
    required this.status,
  });

  final String name;
  final String image_url;
  final String job_id;
  final String? client_image;
  final String client;
  final String description;
  final String address;
  final double price;
  final String date;
  final String status;
  final String time;

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return Colors.orange;
      case 'going':
        return Colors.orange;
      case 'arrived':
        return Colors.orange;
      case 'pending':
        return Colors.purple;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'finalized':
        return Colors.red;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'En Proceso';
      case 'accepted':
        return 'Aceptado';
      case 'going':
        return 'Llendo';
      case 'arrived':
        return 'En Domicilio';
      case 'pending':
        return 'Pendiente';
      case 'finalized':
        return 'Por Finalizar';
      case 'completed':
        return 'Completado';
      case 'canceled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: colorsecundario.withOpacity(0.52),
      border: Border.all(color: colorsecundario, width: 1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: colorWhite),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: colorWhite,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Theme.of(context).colorScheme.primary,
        child: InkWell(
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => ViewJobPage(id_trabajo: job_id),
            //   ),
            // );
          },
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    child: SizedBox(
                      height: double.maxFinite,
                      width: 110,
                      child: CachedNetworkImage(
                        imageUrl: image_url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: Container(color: Colors.white24)
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .shimmer(duration: 1200.ms)
                              .fade(begin: 0.4, end: 1),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                 
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Circleimage(w: 25, h: 25, image_url: client_image),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              client,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const Spacer(),

                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor(),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.surface,
                          letterSpacing: -0.2,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Descripción
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Footer: Dirección y Precio
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${date}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.access_time_outlined,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ' ${time}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
