import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Components/Cards/CardsTransaction.dart';
import 'package:gixt_worker/Components/Sketor/CardsTransactionSkeleton.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/components/sketor/cardsCategoria.dart';
import 'package:gixt_worker/services/Wallet/wallet_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final WorkerWallet_service wallet = WorkerWallet_service();
  final ScrollController _scrollController = ScrollController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    jobsStatusNotifier.addListener(_onRefresh);
  }

  @override
  void dispose() {
    jobsStatusNotifier.removeListener(_onRefresh);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);

    final ok = await wallet.fetchFromApi();

    if (!ok && mounted) {
      Future.microtask(() async {
        await Toast(
          context,
          title: "Error",
          message: "No se pudo obtener la información",
          type: alert_type.error,
        );
      });
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    await wallet.fetchFromApi();
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  // Lista plana de transacciones del wallet (si existe).
  List<dynamic> get _transactions => wallet.workerWallet.isNotEmpty
      ? wallet.workerWallet.first.transactions
      : const [];

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHero(),
                    const SizedBox(height: 20),
                    _buildBalanceCard(),
                    const SizedBox(height: 28),
                    _buildData(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    final onSurface = Theme.of(context).colorScheme.surface;
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: 70,
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      iconTheme: IconThemeData(color: onSurface),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: onSurface,
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Wallet',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    final onSurface = Theme.of(context).colorScheme.surface;
    final count = _transactions.length;

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tus ingresos',
              style: GoogleFonts.poppins(
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.9,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLoading
                  ? 'Cargando tus ingresos…'
                  : count == 0
                  ? 'Aquí verás el detalle de cada pago que recibas por tus servicios.'
                  : 'Este es el historial de movimientos de tu cuenta.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color: onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }

  Widget _buildBalanceCard() {
    final onSurface = Theme.of(context).colorScheme.surface;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorsecundario, colorsecundario.withValues(alpha: 0.82)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Brillos decorativos (ahora recortados al borde)
            Positioned(top: -60, right: -40, child: _glow(160, 0.10)),
            Positioned(bottom: -70, left: -30, child: _glow(180, 0.07)),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saldo total',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  isLoading
                      ? Container(
                          width: 140,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        )
                      : Text(
                          '\$${wallet.workerWallet[0].balance}',
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            color: Colors.white,
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    'MXN',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  // const SizedBox(height: 18),
                  // _buildRetirarButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.97, 0.97));
  }

  Widget _buildRetirarButton() {
    final hasBalance =
        !isLoading && wallet.workerWallet.isNotEmpty && wallet.workerWallet[0].balance > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: hasBalance ? _onRetirarPressed : null,
        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
        label: Text(
          'Retirar',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: colorsecundario,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.25),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _onRetirarPressed() async {
    await Toast(
      context,
      title: 'Próximamente',
      message: 'La opción para retirar tu saldo estará disponible pronto.',
      type: alert_type.advertencia,
    );
  }

  Widget _glow(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
  Widget _buildData() {
    if (isLoading) {
      return Column(
        children: List.generate(3, (_) => const Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              child: CardsTransactionSkeleton())),
      );
    }
    if (_transactions.isEmpty) return _buildEmptyState();
    return _buildServicios();
  }

  Widget _buildServicios() {
    final onSurface = Theme.of(context).colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Movimientos',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorsecundario.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_transactions.length}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorsecundario,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _transactions.length,
          itemBuilder: (context, index) {
            final t = _transactions[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
              child:
              
                  CardsTransaction(
                        paymentMethod: t.paymentMethod,
                        transactionType: t.transactionType,
                        amount: t.amount,
                        currentBalance: t.currentBalance,
                        previousBalance: t.previousBalance,
                        reason: t.reason,
                        date: t.createdAt,
                      )
                      .animate()
                      .fade(duration: 400.ms, delay: (index * 60).ms)
                      .slideY(begin: 0.15)
                      .scale(begin: const Offset(0.96, 0.96)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final onSurface = Theme.of(context).colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 38,
              color: onSurface.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes movimientos',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: onSurface.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cuando completes servicios, tus pagos aparecerán aquí con todo el detalle.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: onSurface.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms);
  }
}

/// Card propio para una transacción del wallet.
class _WalletTransactionCard extends StatelessWidget {
  final String paymentMethod;
  final String transactionType;
  final double amount;
  final String date;

  const _WalletTransactionCard({
    required this.paymentMethod,
    required this.transactionType,
    required this.amount,
    required this.date,
  });

  // Determina si es entrada de dinero según el tipo (ajusta las palabras a tus valores reales).
  bool get _isIncome {
    final t = transactionType.toLowerCase();
    const outflow = [
      'retiro',
      'withdraw',
      'comision',
      'comisión',
      'fee',
      'cargo',
    ];
    return !outflow.any((k) => t.contains(k));
  }

  IconData get _icon {
    final t = transactionType.toLowerCase();
    if (t.contains('retiro') || t.contains('withdraw'))
      return Icons.arrow_upward_rounded;
    if (t.contains('comis') || t.contains('fee') || t.contains('cargo')) {
      return Icons.remove_circle_outline_rounded;
    }
    return Icons.arrow_downward_rounded;
  }

  String _labelTipo() {
    final t = transactionType.trim();
    if (t.isEmpty) return 'Movimiento';
    return t[0].toUpperCase() + t.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.surface;
    final accent = _isIncome
        ? const Color(0xFF2E9E5B)
        : const Color(0xFFE0524B);
    final signo = _isIncome ? '+' : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelTipo(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.credit_card_rounded,
                      size: 13,
                      color: onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        paymentMethod,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$signo\$${amount.abs().toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
