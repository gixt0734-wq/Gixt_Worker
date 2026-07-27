import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Components/Cards/CardsImage.dart';
import 'package:gixt_worker/Components/Sketor/cardsImg.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/components/circleimage.dart';
import 'package:gixt_worker/services/servicios/favorite_service.dart';
import 'package:gixt_worker/services/servicios/serviciosbyid_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class ServicioPage extends StatefulWidget {
  const ServicioPage({super.key, required this.service_id});
  final String service_id;
  @override
  State<ServicioPage> createState() => _ServicioPageState();
}

class _ServicioPageState extends State<ServicioPage> {
  bool isLoading = false;
  bool hasMore = true;
  final ServiciosById_service serviciosById = ServiciosById_service();
  final ScrollController _scrollController = ScrollController();
  bool fav = false;

  @override
  void initState() {
    super.initState();
    _initial();
  }

  Future<void> _initial() async {
    bool ok = await serviciosById.fetchServicioData(widget.service_id);
    if (!ok) {
      if (!mounted) return;
      Future.microtask(() async {
        await Toast(
          context,
          title: "Error",
          message: "No se pudo obtener la información",
          type: alert_type.error,
        );
        Navigator.pop(context);
      });
    }
    setState(() {
      fav = serviciosById.servicios[0].favorite;
    });
  }

  Future<void> _onRefresh() async {
    setState(() => hasMore = true);
    bool ok = await serviciosById.fetchServicioData(widget.service_id);
    if (!ok) {
      if (!mounted) return;
      Future.microtask(() async {
        await Toast(
          context,
          title: "Error",
          message: "No se pudo obtener la información",
          type: alert_type.error,
        );
        Navigator.pop(context);
      });
    }
    setState(() {});
  }

  void _fav() async {
    setState(() => fav = !fav);
    await FavoritoService.Crear(service_id: widget.service_id);
  }

  @override
  Widget build(BuildContext context) {
    if (serviciosById.servicios.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Indicador(),
      );
    }
    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          color: colorsecundario,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    _buildTitle()
                        .animate()
                        .fade(duration: 450.ms, delay: 60.ms)
                        .slideX(begin: -0.2),
                    const SizedBox(height: 24),
                    _buildServicio()
                        .animate()
                        .fade(duration: 450.ms, delay: 60.ms)
                        .slideX(begin: -0.2),
                    const SizedBox(height: 24),
                    _buildTrabajador()
                        .animate()
                        .fade(duration: 450.ms, delay: 60.ms)
                        .slideX(begin: -0.2),
                    const SizedBox(height: 24),
                    _buildImgServicios()
                        .animate()
                        .fade(duration: 450.ms, delay: 60.ms)
                        .slideX(begin: -0.2),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _bottomBar(context),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
      expandedHeight: 320,
      pinned: false,
      floating: false, //  sin efecto raro
      snap: false, //  sin delay
      elevation: 0,
      toolbarHeight: 90,
      iconTheme: IconThemeData(color: colorWhite),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const SizedBox(), //  quitamos title para evitar desplazamientos
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: serviciosById.servicios[0].image,
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

            Container(color: Colors.black.withOpacity(isDark ? 0.35 : 0.15)),

            Positioned(
              bottom: 5,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorsecundario.withOpacity(0.3),
                      border: Border.all(color: colorsecundario, width: 1),
                      borderRadius: BorderRadius.circular(8), // opcional
                    ),
                    child: Text(
                      serviciosById.servicios[0].category,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colorWhite, // mejor contraste con fondo blanco
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// NOMBRE
                  Text(
                    serviciosById.servicios[0].service_name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: colorWhite, // mejor contraste con fondo blanco
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 0),

                  /// BOTONES PEGADOS A LA DERECHA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _fav,
                        icon: Icon(
                          Icons.favorite,
                          size: 32,
                          color: !fav ? colorWhite : colorError,
                        ),
                      ),

                      const SizedBox(width: 10), // separación

                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.share, size: 32, color: colorWhite),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 15, color: colorsecundario),
        const SizedBox(width: 4),
        Expanded(child: 
        Text(
          serviciosById.servicios[0].worker_city,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
          ),
        )),
        const Spacer(),

        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < serviciosById.servicios[0].rating.round()
                  ? Icons.star
                  : Icons.star_border,
              color: Colors.amber,
              size: 18,
            );
          }),
        ),
        const SizedBox(width: 4),
        Text(
          '${serviciosById.servicios[0].rating}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildServicio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección descripción
        Text(
          'Descripción',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          serviciosById.servicios[0].description,
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.75,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          icon: Icons.info_outline,
          text:
              'El precio mostrado corresponde a la mano de obra y de ir al domicilio; el costo final puede variar según los materiales necesarios.',
        ),
        const SizedBox(height: 20),
        Text(
          'Costos',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.2,
          ),
        ),

        Column(
          children: [
            _buildPriceRow(
              'Tiempo estimado',
              '${serviciosById.servicios[0].duration}'
                  ' horas',
            ),
            _buildPriceRow(
              'Tarifa de mano de obra',
              '\$${serviciosById.servicios[0].price}',
            ),
            _buildPriceRow(
              'Visita y diagnostico',
              '\$${serviciosById.servicios[0].km_cost}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrabajador() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trabajador',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Circleimage(
                w: 56,
                h: 56,
                image_url: serviciosById.servicios[0].worker_img,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            serviciosById.servicios[0].worker_name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.verified, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                        const SizedBox(width: 3),

                        Text(
                          '${serviciosById.servicios[0].worker_rating}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      serviciosById.servicios[0].des_trabajador,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.6,
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImgServicios() {
    final isLoading1 = serviciosById.servicios[0].images.isEmpty;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Más Fotos',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: surfaceColor,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: surfaceColor.withOpacity(0.4),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: GridView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: isLoading1
                ? 3
                : serviciosById.servicios[0].images.length,
            itemBuilder: (context, index) {
              if (isLoading1) return const CardsImgSkeleton();
              try {
                return CardsImage(
                      url_img: serviciosById.servicios[0].images[index],
                    )
                    .animate()
                    .fade(duration: 350.ms)
                    .scale(begin: const Offset(0.97, 0.97));
              } catch (e) {
                return const SizedBox();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => ReservaPage(
            //       service_id: serviciosById.servicios[0].service_id,
            //       name: serviciosById.servicios[0].service_name,
            //       description: serviciosById.servicios[0].description,
            //     ),
            //   ),
            // );
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: colorsecundario,
            foregroundColor: colorWhite,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.delete, size: 20),
          label: Text(
            'Eliminar',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: 
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.65),
                ),
              ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorsecundario.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorsecundario.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorsecundario),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.5,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
