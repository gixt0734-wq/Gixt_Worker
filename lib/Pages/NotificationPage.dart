import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gixt_worker/Components/Cards/CardsNotification.dart';
import 'package:gixt_worker/Components/TypingIndicator.dart';
import 'package:gixt_worker/services/Notification/ChatCacheService.dart';
import 'package:gixt_worker/services/Notification/Notification.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _enabled = true;
  bool _hasText = false;
  bool _isLoading = true;
  bool _isTyping = false;
  String? img;
  final List<NotificationModel> _notificationModel = [];
  final NotificationCacheService _cache = NotificationCacheService();
  @override
  void initState() {
    super.initState();
    _loadFromCache();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      img = prefs.getString('img');
    });
  }

  

  Future<void> _loadFromCache() async {
    final cached = await _cache.loadNotification();
    setState(() {
      _notificationModel.addAll(cached);
      _isLoading = false;
    });
    _scrollToBottom();
  }

Future<void> _onRefresh() async {
  final cached = await _cache.loadNotification();
  if (mounted) {
    setState(() {
      _notificationModel.clear();
      _notificationModel.addAll(cached);
    });
  }
}
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(99999)}';

  

  Future<void> _clearChat() async {
    final confirm =
        await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Borrar notificaciones',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Perderás todas las notificaciones',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.5,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.45),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.55),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.red.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          'Borrar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (confirm == true) {
      await _cache.clear();
      setState(() => _notificationModel.clear());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
          onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // if (_messages.isEmpty) ...[
                  //   Column(
                  //     children: [
                  //       Align(
                  //         alignment: Alignment.topCenter,
                  //         child: Padding(
                  //           padding: const EdgeInsets.only(top: 50.0),
                  //           child: Hero(
                  //             tag: 'chat',
                  //             child: Image.asset(
                  //               'assets/chamb_ia.png',
                  //               width: 150,
                  //               height: 150,
                  //               fit: BoxFit.contain,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //       Text(
                  //         '¡Hola! Soy Chamb IA',
                  //         style: GoogleFonts.poppins(
                  //           fontSize: 22,
                  //           fontWeight: FontWeight.w700,
                  //           color: Theme.of(context).colorScheme.surface,
                  //           letterSpacing: -0.5,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 8),
                  //       Text(
                  //         'Pregúntame algo y te ayudo a encontrar\nel servicio que necesitas',
                  //         textAlign: TextAlign.center,
                  //         style: GoogleFonts.poppins(
                  //           fontSize: 14,
                  //           height: 1.5,
                  //           color: Theme.of(
                  //             context,
                  //           ).colorScheme.surface.withOpacity(0.55),
                  //           letterSpacing: -0.2,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ],
                ]),
              ),
            ),

          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == _notificationModel.length && _isTyping) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: TypingIndicator(),
                );
              }
              final msg = _notificationModel[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: CardsNotification(
                  title: msg.text ?? '',
                  datime: msg.timestamp,
                  img: img,
                ),
              );
            }, childCount: _notificationModel.length + (_isTyping ? 1 : 0)),
          ),
        ],
      ),
      )
    );
  }

  SliverAppBar _buildSliverAppBar() {
    final surface = Theme.of(context).colorScheme.surface;
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: 60,
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      toolbarHeight: 60,
      iconTheme: IconThemeData(color: surface),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.12),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
      centerTitle: true,
      title: Text(
          'Notificaciones',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
      actions: [
        if (_notificationModel.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _clearChat,
          ),
        const SizedBox(width: 4),
      ],
    );
  }


}
