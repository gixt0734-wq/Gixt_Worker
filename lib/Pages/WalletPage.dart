import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gixt_worker/Components/Cards/CardsTransaction.dart';
import 'package:gixt_worker/Components/Loaders/Indicador.dart';
import 'package:gixt_worker/Components/Sketor/CardsTransactionSkeleton.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/inputs/Input_Description.dart';
import 'package:gixt_worker/Config/Notifiers/jobs_notifiers.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/components/sketor/cardsCategoria.dart';
import 'package:gixt_worker/services/Wallet/wallet_service.dart';
import 'package:gixt_worker/services/user/Bank_service.dart';
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
  final _accountHolderController = TextEditingController();
  final _clabeController = TextEditingController();
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
    _accountHolderController.dispose();
    _clabeController.dispose();
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

 void _Update() async {
   
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Indicador(),
    );

    final result = await BankService.Create(
      account_holder: _accountHolderController.text ,
      clabe:_clabeController.text, 
    );



    if (result['success'] == true) {
       
     await  _onRefresh();
      Toast(
        context,
        title: "Cuenta bancaria actualizada",
        message: "Tu información bancaria se ha guardado correctamente",
        type: alert_type.exito,
      );
      Navigator.pop(context);
    } else {
      Toast(
        context,
        title: "Error",
        message: result['message'],
        type: alert_type.error,
      );
      Navigator.pop(context);
    }
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
                    _buildBalanceBank(),
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

 Widget _buildBalanceBank() {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = Theme.of(context).colorScheme.surface;

    final holderRaw = wallet.workerWallet.isNotEmpty
        ? '${wallet.workerWallet[0].account_holder}'.trim()
        : '';
    final holder = (holderRaw.isEmpty || holderRaw == 'null')
        ? 'Sin titular'
        : holderRaw;

    final last4Raw = wallet.workerWallet.isNotEmpty
        ? '${wallet.workerWallet[0].clabe_last4}'.trim()
        : '';
    final last4 = (last4Raw.isEmpty || last4Raw == 'null') ? '----' : last4Raw;

    final isActivePayment = wallet.workerWallet.isNotEmpty
        ? wallet.workerWallet[0].is_active_payment
        : true;

    return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : _showBankAccountFormSheet,
              child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: (!isLoading && !isActivePayment)
                ? _buildBankAccountMissing()
                : Row(
              children: [
                // Icono banco
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colorsecundario.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: colorsecundario,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Etiqueta + titular
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuenta bancaria',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 3),
                      isLoading
                          ? Container(
                              width: 120,
                              height: 16,
                              decoration: BoxDecoration(
                                color: onSurface.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            )
                          : Text(
                              holder,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.9,
                                fontSize: 15,
                                color: onSurface,
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // CLABE enmascarada
                isLoading
                    ? Container(
                        width: 74,
                        height: 32,
                        decoration: BoxDecoration(
                          color: onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),

                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '••••••',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: colorsecundario.withValues(alpha: 0.55),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              last4,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: colorsecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: onSurface.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }

 Widget _buildBankAccountMissing() {
    final onSurface = Theme.of(context).colorScheme.surface;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colorsecundario.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.account_balance_rounded,
            color: colorsecundario,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cuenta bancaria',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Agrega tu cuenta para recibir tus pagos',
                maxLines: 2,
                style: GoogleFonts.poppins(
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _showBankAccountFormSheet,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorsecundario,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Agregar',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

 void _showBankAccountFormSheet() {
    final formKey = GlobalKey<FormState>();

    final holderRaw = wallet.workerWallet.isNotEmpty
        ? '${wallet.workerWallet[0].account_holder}'.trim()
        : '';
    _accountHolderController.text = (holderRaw.isEmpty || holderRaw == 'null')
        ? ''
        : holderRaw;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: KeyboardDismisser(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel('Datos de tu cuenta bancaria'),
                        const SizedBox(height: 20),
                        CustomDescriptionFormField(
                          controller: _accountHolderController,
                          label: 'Titular de la cuenta',
                          hint: 'Ej: Juan Pérez López',
                          minLines: 1,
                          maxLines: 1,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor agrega el nombre del titular';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),
                        CustomDescriptionFormField(
                          controller: _clabeController,
                          label: 'CLABE interbancaria',
                          hint: 'Ej: 012345678901234567',
                          minLines: 1,
                          maxLines: 1,
                          max: 18,
                          validator: (value) {
                            final clabe = value?.trim() ?? '';
                            if (clabe.isEmpty) {
                              return 'Por favor agrega tu CLABE';
                            }
                            if (!RegExp(r'^\d{18}$').hasMatch(clabe)) {
                              return 'La CLABE debe tener 18 dígitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState?.validate() ?? false) {
                                _Update();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorsecundario,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Guardar información',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  
  Widget _fieldLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ],
    );
  }


}

