import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/observability_service.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../legal/presentation/pages/terms_screen.dart';
import '../widgets/retracto_disclaimer_widget.dart';

/// Server-authoritative order status enum used by [PaymentResultScreen].
///
/// Maps the `order_status` Postgres enum values from the orders table
/// (Plan 09-01).  [polling] is a UI-only state not stored in the DB.
enum _OrderStatus {
  polling,
  paid,
  failed,

  /// Still `payment_pending` after max retries — covers async PSE/Nequi flows.
  pendingPSE,
}

/// Displays the result of a Wompi payment flow after the WebView redirect.
///
/// Security note (T-09-11): this screen receives [orderId] and
/// [transactionRef] from [WompiWebViewScreen], but it NEVER trusts the URL
/// parameters from the redirect for determining order status.  It queries
/// `orders.status` from Supabase directly (server-authoritative).
class PaymentResultScreen extends ConsumerStatefulWidget {
  const PaymentResultScreen({
    super.key,
    required this.orderId,
    required this.transactionRef,
  });

  final String orderId;

  /// Wompi transaction reference — kept for logging/debugging only.
  final String transactionRef;

  @override
  ConsumerState<PaymentResultScreen> createState() =>
      _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen>
    with TickerProviderStateMixin {
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(seconds: 2);

  _OrderStatus _status = _OrderStatus.polling;
  String? _orderNumber;
  int _retryCount = 0;
  bool _isPolling = false;

  late final AnimationController _checkmarkController;
  late final Animation<double> _checkmarkScale;

  @override
  void initState() {
    super.initState();

    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _checkmarkScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _checkmarkController,
        curve: Curves.elasticOut,
      ),
    );

    _pollOrderStatus();
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    super.dispose();
  }

  Future<void> _pollOrderStatus() async {
    if (_isPolling) return;

    if (!mounted) return;
    setState(() {
      _isPolling = true;
      _retryCount = 0;
      _status = _OrderStatus.polling;
    });

    await _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select('status, paid_at, total_cop, order_number')
          .eq('id', widget.orderId)
          .single();

      final String dbStatus = (response['status'] as String?) ?? '';
      final String? orderNumber = response['order_number'] as String?;

      if (!mounted) return;

      if (dbStatus == 'paid') {
        // Log payment completion analytics event (Phase 12 — OPT-03).
        final totalCop = (response['total_cop'] as num?)?.toInt() ?? 0;
        ObservabilityService.logEvent('payment_complete', parameters: {
          'order_id': widget.orderId,
          'amount_cop': totalCop,
          'payment_method': 'wompi',
        });

        setState(() {
          _status = _OrderStatus.paid;
          _orderNumber = orderNumber;
          _isPolling = false;
        });
        _checkmarkController.forward();
        return;
      }

      if (dbStatus == 'payment_failed') {
        // Record non-fatal for payment failures (Phase 12 — OPT-03).
        ObservabilityService.recordNonFatal(
          Exception('Payment failed: $dbStatus'),
          null,
          context: {
            'order_id': widget.orderId,
            'wompi_status': dbStatus,
          },
        );
        setState(() {
          _status = _OrderStatus.failed;
          _isPolling = false;
        });
        return;
      }

      // payment_pending: retry up to _maxRetries (covers card/Nequi latency).
      // After max retries show PSE "verify later" UI.
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future<void>.delayed(_retryDelay);
        if (mounted) await _fetchStatus();
      } else {
        setState(() {
          _status = _OrderStatus.pendingPSE;
          _isPolling = false;
        });
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verificando tu pago: ${e.message}'),
          backgroundColor: Colors.red.shade700,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: const Color(0xFF00FF88),
            onPressed: _pollOrderStatus,
          ),
        ),
      );
      setState(() {
        _status = _OrderStatus.failed;
        _isPolling = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red.shade700,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: const Color(0xFF00FF88),
            onPressed: _pollOrderStatus,
          ),
        ),
      );
      setState(() {
        _status = _OrderStatus.failed;
        _isPolling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Resultado del pago',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        // Only show back arrow when showing the failure state so the user
        // can navigate back manually.
        automaticallyImplyLeading: _status == _OrderStatus.failed,
      ),
      body: Semantics(
        identifier: 'payment_result_screen',
        child: switch (_status) {
          _OrderStatus.polling => _buildPollingState(),
          _OrderStatus.paid => _buildSuccessState(),
          _OrderStatus.failed => _buildFailedState(),
          _OrderStatus.pendingPSE => _buildPendingPSEState(),
        },
      ),
    );
  }

  // ─── Polling / loading state ─────────────────────────────────────────────

  Widget _buildPollingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF00FF88)),
          SizedBox(height: 24),
          Text(
            'Verificando tu pago...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Success state ───────────────────────────────────────────────────────

  Widget _buildSuccessState() {
    final displayOrderNumber =
        _orderNumber != null ? ' #$_orderNumber' : '';

    return Semantics(
      identifier: 'payment_success_state',
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animated neon checkmark (scale 0 → 1, Curves.elasticOut)
              ScaleTransition(
                scale: _checkmarkScale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                    border: Border.all(
                      color: const Color(0xFF00FF88),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF00FF88),
                    size: 56,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                '¡Pago exitoso!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Tu orden$displayOrderNumber está siendo preparada.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 32),

              // ─── Ley 1480 retracto disclaimer (LGL-02) ───────────────────
              const RetractoDisclaimerWidget(),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TermsScreen(),
                  ),
                ),
                child: const Text(
                  'Ver términos y condiciones',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFFFFB300),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Semantics(
                identifier: 'view_order_button',
                child: PrimaryGlassButton(
                  text: 'Ver mi orden',
                  width: double.infinity,
                  isLoading: false,
                  onPressed: () => _navigateToOrder(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToOrder(BuildContext context) {
    // Phase 10 will implement the full OrderDetailScreen.
    // For now we push a placeholder scaffold so the button is wired.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OrderDetailPlaceholder(orderId: widget.orderId),
      ),
    );
  }

  // ─── Failed state ────────────────────────────────────────────────────────

  Widget _buildFailedState() {
    return Semantics(
      identifier: 'payment_failed_state',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.redAccent, width: 3),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                  size: 56,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Pago no completado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Por favor intenta de nuevo o usa otro método de pago.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 40),

              GlassButton(
                text: 'Volver al carrito',
                width: double.infinity,
                isLoading: false,
                gradientColors: [
                  Colors.red.shade700,
                  Colors.red.shade500,
                ],
                onPressed: () =>
                    Navigator.of(context).popUntil(_isCartRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PSE pending state ───────────────────────────────────────────────────

  Widget _buildPendingPSEState() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.amber),

            const SizedBox(height: 28),

            const Text(
              'Verificando con el banco...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Las transacciones PSE pueden tardar unos minutos en '
              'confirmarse. Puedes cerrar esta pantalla y revisar el '
              'estado de tu orden más tarde.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),

            const SizedBox(height: 40),

            PrimaryGlassButton(
              text: 'Verificar ahora',
              width: double.infinity,
              isLoading: _isPolling,
              onPressed: _isPolling ? null : _pollOrderStatus,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Returns true when we reach the cart route (or the root if not found),
  /// so [Navigator.popUntil] stops at the cart screen.
  bool _isCartRoute(Route<dynamic> route) {
    return route.isFirst ||
        (route.settings.name?.contains('cart') ?? false);
  }
}

// ─── Order detail placeholder (Phase 10 will replace) ────────────────────────

/// Temporary placeholder for the order detail screen.
/// Phase 10 will implement the full OrderDetailScreen.
class _OrderDetailPlaceholder extends StatelessWidget {
  const _OrderDetailPlaceholder({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Mi Orden',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF00FF88),
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Orden en preparación',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                orderId,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
