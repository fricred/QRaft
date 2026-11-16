import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../qr_generator/domain/entities/qr_type.dart';
import '../data/dynamic_qr_repository.dart';
import 'dq_ui.dart';
import 'manager_screen.dart';
import 'purchase_flow.dart';

enum _Step { summary, working, success, pending, failed }

/// Buys one dynamic QR for a design + content (new code), or pays an existing
/// `pending_payment` code ([pendingRedirectId]). Pops `true` once a code exists.
class DynamicQrCheckoutScreen extends ConsumerStatefulWidget {
  const DynamicQrCheckoutScreen({
    super.key,
    required this.name,
    required this.type,
    required this.payload,
    required this.display,
    required this.customization,
    this.pendingRedirectId,
    this.pendingSlug,
  });

  final String name;
  final QRType type;
  final String payload;
  final String display;
  final QRCustomization customization;
  final String? pendingRedirectId;
  final String? pendingSlug;

  @override
  ConsumerState<DynamicQrCheckoutScreen> createState() => _DynamicQrCheckoutScreenState();
}

class _DynamicQrCheckoutScreenState extends ConsumerState<DynamicQrCheckoutScreen> {
  _Step _step = _Step.summary;
  String? _error;
  late String? _redirectId = widget.pendingRedirectId;
  late String? _slug = widget.pendingSlug;

  bool get _created => _redirectId != null;

  Future<void> _pay() async {
    setState(() {
      _step = _Step.working;
      _error = null;
    });
    final repo = ref.read(dynamicQrRepositoryProvider);
    try {
      if (_redirectId == null) {
        final r = await repo.reserve(
          name: widget.name,
          customization: widget.customization.toJson(),
          type: widget.type,
          payload: widget.payload,
          display: widget.display,
        );
        _redirectId = r.redirectId;
        _slug = r.slug;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.failed;
        _error = dynamicQrErrorText(context, e);
      });
      return;
    }
    if (!mounted) return;
    final outcome = await payForDynamicQr(context, ref, _redirectId!);
    if (!mounted) return;
    ref.invalidate(myDynamicQrsProvider);
    setState(() {
      switch (outcome) {
        case DqPayOutcome.active:
          HapticFeedback.mediumImpact();
          _step = _Step.success;
        case DqPayOutcome.pending:
          _step = _Step.pending;
        case DqPayOutcome.cancelled:
          _step = _Step.summary;
        case DqPayOutcome.unavailable:
          _step = _Step.failed;
          _error = dqT(context, 'Los pagos no están disponibles en este momento. Revisa tu conexión e inténtalo de nuevo.',
              'Payments are not available right now. Check your connection and try again.');
        case DqPayOutcome.failed:
          _step = _Step.failed;
          _error = dqT(context, 'No se hizo ningún cobro. Revisa tu método de pago en Google Play e inténtalo de nuevo.',
              'You were not charged. Check your payment method in Google Play and try again.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final price = ref.watch(dynamicQrPackageProvider).value?.storeProduct.priceString ?? 'US\$9.99';
    return PopScope(
      canPop: _step != _Step.working,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: kDqBg,
        appBar: AppBar(
          backgroundColor: kDqBg,
          foregroundColor: Colors.white,
          leading: _step == _Step.working
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: dqT(context, 'Cerrar', 'Close'),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(_created),
                ),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (_step) {
              _Step.summary || _Step.working => _summary(price),
              _Step.success => _success(),
              _Step.pending => _pending(),
              _Step.failed => _failed(),
            },
          ),
        ),
      ),
    );
  }

  Widget _primary(String label, VoidCallback? onPressed, {Key? key, bool busy = false}) => SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton(
          key: key,
          style: FilledButton.styleFrom(
            backgroundColor: kDqNeon,
            foregroundColor: kDqOnNeon,
            disabledBackgroundColor: kDqNeon.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          onPressed: onPressed,
          child: busy ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: kDqOnNeon)) : Text(label),
        ),
      );

  Widget _secondary(String label, VoidCallback onPressed, {Key? key}) => SizedBox(
        height: 52,
        width: double.infinity,
        child: OutlinedButton(
          key: key,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: kDqLine),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: onPressed,
          child: Text(label),
        ),
      );

  Widget _summary(String price) {
    final busy = _step == _Step.working;
    final previewData = _slug != null ? 'https://scanqraft.app/$_slug' : 'https://scanqraft.app/xxxxxxxx';
    return ListView(
      key: const ValueKey('summary'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(dqT(context, 'Confirma tu QR dinámico', 'Confirm your dynamic QR'),
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kDqSurface, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            DynamicQrImage(data: previewData, customization: widget.customization, size: 72),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${dqT(context, 'Mostrará', 'Will show')}: ${describeContent(context, widget.type, widget.payload)}',
                    style: const TextStyle(color: kDqMuted, fontSize: 14)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        _row(dqT(context, 'QR dinámico (1 código)', 'Dynamic QR (1 code)'), price),
        _row(dqT(context, 'Tipo de pago', 'Payment'), dqT(context, 'Único · sin mensualidad', 'One-time · no subscription')),
        const Divider(color: Color(0xFF3A424E), height: 24),
        _row(dqT(context, 'Total', 'Total'), price, bold: true),
        const SizedBox(height: 12),
        Text(
          dqT(context,
              'Google Play muestra el precio final en tu moneda antes de confirmar. El código queda guardado en tu cuenta: lo recuperas en otro teléfono con “Restaurar compras”.',
              'Google Play shows the final price in your currency before you confirm. The code is saved to your account: get it back on another phone with “Restore purchases”.'),
          style: const TextStyle(color: kDqMuted, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        _primary(dqT(context, 'Pagar con Google Play', 'Pay with Google Play'), busy ? null : _pay,
            key: const Key('dynamic_checkout_pay_button'), busy: busy),
        const SizedBox(height: 8),
        if (!busy && !_created)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kDqMuted, minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(dqT(context, 'Mejor guardarlo como estático (gratis)', 'Save it as static instead (free)')),
          ),
      ],
    );
  }

  Widget _row(String a, String b, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(a, style: TextStyle(color: bold ? Colors.white : kDqMuted, fontSize: bold ? 18 : 15, fontWeight: bold ? FontWeight.w700 : FontWeight.w400))),
          Text(b, style: TextStyle(color: Colors.white, fontSize: bold ? 18 : 15, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        ]),
      );

  Widget _centered({required Key key, required IconData icon, required Color color, required String title, required String body, required List<Widget> actions, Widget? extra}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(body, textAlign: TextAlign.center, style: const TextStyle(color: kDqMuted, fontSize: 15, height: 1.5)),
        if (extra != null) ...[const SizedBox(height: 20), extra],
        const SizedBox(height: 28),
        ...actions.expand((a) => [a, const SizedBox(height: 10)]),
      ],
    );
  }

  void _openManager() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DynamicQrManagerScreen()));
  }

  Widget _success() {
    final url = 'scanqraft.app/$_slug';
    return _centered(
      key: const ValueKey('success'),
      icon: Icons.check_rounded,
      color: kDqNeon,
      title: dqT(context, 'Tu QR dinámico está listo', 'Your dynamic QR is ready'),
      body: dqT(context, 'Antes de imprimir en cantidad, escanéalo con otro teléfono para probarlo.',
          'Before printing many, scan it with another phone to test it.'),
      extra: Column(children: [
        DynamicQrImage(data: 'https://$url', customization: widget.customization, size: 184),
        const SizedBox(height: 14),
        Semantics(
          button: true,
          label: dqT(context, 'Copiar link $url', 'Copy link $url'),
          child: InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: 'https://$url'));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dqT(context, 'Link copiado', 'Link copied'))));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: kDqSurface, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(url, style: const TextStyle(color: Colors.white, fontSize: 15)),
                const SizedBox(width: 8),
                const Icon(Icons.copy_rounded, size: 18, color: kDqNeon),
              ]),
            ),
          ),
        ),
      ]),
      actions: [
        _primary(dqT(context, 'Ir a Mis QR dinámicos', 'Go to My dynamic QRs'), _openManager, key: const Key('dynamic_checkout_manager_button')),
        _secondary(dqT(context, 'Listo', 'Done'), () => Navigator.of(context).pop(true)),
      ],
    );
  }

  Widget _pending() => _centered(
        key: const ValueKey('pending'),
        icon: Icons.schedule_rounded,
        color: kDqAmber,
        title: dqT(context, 'Pago en proceso', 'Payment in progress'),
        body: dqT(context,
            'Google Play aún no confirma tu pago (pasa con efectivo o saldo). Tu código ya está reservado y se activa solo cuando llegue la confirmación. No lo imprimas todavía: mientras tanto, quien lo escanee verá que aún no está activo.',
            "Google Play hasn't confirmed your payment yet (common with cash or carrier billing). Your code is reserved and turns on by itself once it's confirmed. Don't print it yet: until then, people who scan it see it isn't active."),
        actions: [
          _primary(dqT(context, 'Ir a Mis QR dinámicos', 'Go to My dynamic QRs'), _openManager),
          _secondary(dqT(context, 'Listo', 'Done'), () => Navigator.of(context).pop(true)),
        ],
      );

  Widget _failed() => _centered(
        key: const ValueKey('failed'),
        icon: Icons.error_outline_rounded,
        color: kDqError,
        title: dqT(context, 'No se completó el pago', "The payment didn't go through"),
        body: _error ?? '',
        actions: [
          _primary(dqT(context, 'Intentar de nuevo', 'Try again'), _pay, key: const Key('dynamic_checkout_retry_button')),
          _secondary(
            _created ? dqT(context, 'Pagar después', 'Pay later') : dqT(context, 'Guardarlo como estático (gratis)', 'Save it as static (free)'),
            () => Navigator.of(context).pop(_created),
          ),
        ],
      );
}

/// Opens the checkout for a code that is still `pending_payment`.
Future<void> payPendingDynamicQr(BuildContext context, DynamicQr code) {
  final qr = code.qr;
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => DynamicQrCheckoutScreen(
      name: code.name,
      type: code.contentType ?? QRType.url,
      payload: code.payload,
      display: qr?.displayData ?? '',
      customization: qr?.customization ?? const QRCustomization(),
      pendingRedirectId: code.redirectId,
      pendingSlug: code.slug,
    ),
  ));
}
