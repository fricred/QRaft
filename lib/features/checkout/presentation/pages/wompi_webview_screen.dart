import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/entities/checkout_session.dart';
import 'payment_result_screen.dart';

/// Full-screen WebView that loads the Wompi Web Checkout URL contained in
/// [session].  When Wompi redirects to `qraft://payment-result` the
/// NavigationDelegate intercepts the navigation, prevents it from loading in
/// the WebView, and pushes [PaymentResultScreen] in its place.
///
/// Security note (T-09-11): the URL parameters appended to the redirect are
/// logged for debugging only. Order status is NEVER inferred from URL params —
/// [PaymentResultScreen] queries Supabase directly.
class WompiWebViewScreen extends ConsumerStatefulWidget {
  const WompiWebViewScreen({super.key, required this.session});

  final CheckoutSession session;

  @override
  ConsumerState<WompiWebViewScreen> createState() => _WompiWebViewScreenState();
}

class _WompiWebViewScreenState extends ConsumerState<WompiWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Intercept Wompi's redirect back to the app.
            if (request.url.startsWith(WompiConfig.checkoutRedirectUrl)) {
              _handlePaymentRedirect(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error al cargar la página de pago: ${error.description}',
                  ),
                  backgroundColor: Colors.red.shade700,
                ),
              );
              Navigator.of(context).pop();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.session.wompiCheckoutUrl));
  }

  /// Called when Wompi redirects to `qraft://payment-result[?id=...]`.
  /// Navigates to [PaymentResultScreen].  URL params are NOT used to determine
  /// status — [PaymentResultScreen] queries Supabase authoritatively.
  void _handlePaymentRedirect(String url) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PaymentResultScreen(
          orderId: widget.session.orderId,
          transactionRef: widget.session.transactionRef,
        ),
      ),
    );
  }

  Future<bool> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text(
          '¿Cancelar el pago?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Si sales ahora, tu pago no se completará. '
          '¿Deseas cancelar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Continuar pagando',
              style: TextStyle(color: Color(0xFF00FF88)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final canGoBack = await _controller.canGoBack();
        if (canGoBack) {
          await _controller.goBack();
        } else {
          final shouldCancel = await _confirmCancel();
          if (shouldCancel && mounted) nav.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text(
            'Pagar con Wompi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              final nav = Navigator.of(context);
              final shouldCancel = await _confirmCancel();
              if (shouldCancel && mounted) nav.pop();
            },
          ),
        ),
        body: Stack(
          children: [
            Semantics(
              identifier: 'wompi_webview',
              child: WebViewWidget(controller: _controller),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00FF88),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
