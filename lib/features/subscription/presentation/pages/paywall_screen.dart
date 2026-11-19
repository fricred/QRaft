import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/widgets/glass_button.dart';
import '../../../../core/utils/friendly_error.dart';
import '../../../../shared/widgets/qraft_logo.dart';
import '../providers/purchase_providers.dart';
import '../providers/subscription_providers.dart' show debugPremiumOverrideProvider;
import '../../domain/entities/purchase_product.dart';
import '../../data/datasources/revenuecat_datasource.dart';
import '../widgets/test_store_notice.dart';

/// Resolves the current RevenueCat offering for the paywall.
/// Loads once RevenueCat is initialized (reactively, no polling) so the paywall
/// never offers a purchase without a real package behind it.
// autoDispose: a null result from a slow init must not stick for the whole session.
final _currentOfferingProvider = FutureProvider.autoDispose<Package?>((ref) async {
  if (RevenueCatDataSource.purchasesUnavailable) return null;
  // Rebuilds as soon as RevenueCat finishes initializing; never calls into an
  // unconfigured Purchases singleton (native crash) and never polls.
  // Stay in the loading state (never a dead/null package) until init completes;
  // the watch rebuilds this provider the moment it does.
  if (ref.watch(isRevenueCatInitFailedProvider)) return null; // prices unavailable
  if (!ref.watch(isRevenueCatInitializedProvider)) {
    // Wait for init (this provider rebuilds when it completes), but never forever.
    return Future<Package?>.delayed(const Duration(seconds: 10), () => null);
  }
  try {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) return null;
    // Prefer monthly; fall back to the first available package.
    return current.monthly ?? current.availablePackages.firstOrNull;
  } catch (e) {
    debugPrint('RevenueCat getOfferings failed: $e');
    return null;
  }
});

/// Full-screen premium paywall.
///
/// Shows the three QRaft Premium entitlements, price loaded from RevenueCat,
/// and a subscribe CTA that triggers the native purchase flow.
///
/// Semantic keys:
///   Key('paywall_screen_root'), Key('paywall_subscribe_btn'),
///   Key('paywall_dismiss_btn')
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringAsync = ref.watch(_currentOfferingProvider);

    return Scaffold(
      key: const Key('paywall_screen_root'),
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const Key('paywall_dismiss_btn'),
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Logo ──────────────────────────────────────────────────────
              const QRaftLogo(size: 72, theme: LogoTheme.carden),

              const SizedBox(height: 20),

              // ── Title ─────────────────────────────────────────────────────
              const Text(
                'QRaft Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              const Text(
                'Diseña sin límites. Genera sin restricciones.',
                style: TextStyle(color: Colors.white54, fontSize: 15),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              // ── Entitlements list ─────────────────────────────────────────
              _EntitlementRow(
                icon: Icons.all_inclusive_rounded,
                title: 'QRs ilimitados',
                subtitle: 'sin límite de creación',
              ),
              const SizedBox(height: 16),
              _EntitlementRow(
                icon: Icons.auto_awesome_rounded,
                title: 'Estilos con IA ilimitados',
                subtitle: 'sin cuota mensual',
              ),
              const SizedBox(height: 16),
              _EntitlementRow(
                icon: Icons.upload_file_rounded,
                title: 'Importación masiva CSV',
                subtitle: 'genera N QRs de golpe',
              ),
              const SizedBox(height: 16),
              _EntitlementRow(
                icon: Icons.block_rounded,
                title: 'Sin anuncios',
                subtitle: 'experiencia limpia',
              ),

              const SizedBox(height: 36),

              // ── Price section (loaded from RevenueCat) ────────────────────
              offeringAsync.when(
                loading: () => Shimmer.fromColors(
                  baseColor: const Color(0xFF2E2E2E),
                  highlightColor: const Color(0xFF3E3E3E),
                  child: Container(
                    height: 28,
                    width: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                error: (_, __) => const Text(
                  'Precio no disponible',
                  style: TextStyle(color: Colors.white54, fontSize: 15),
                ),
                data: (package) => Text(
                  package != null
                      ? '${package.storeProduct.priceString} / mes'
                      : 'Precio no disponible',
                  style: const TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Store mode notice (QRAFT-2) ─────────────────────────────────
              // A RevenueCat Test Store key simulates purchases and charges nothing.
              // Say so before offering the purchase; in release such a build cannot sell.
              if (RevenueCatDataSource.isTestStoreKey) ...[
                const TestStoreNotice(key: Key('paywall_test_store_notice')),
                const SizedBox(height: 16),
              ],

              // ── Subscribe CTA ─────────────────────────────────────────────
              offeringAsync.when(
                loading: () => PrimaryGlassButton(
                  key: const Key('paywall_subscribe_btn'),
                  text: 'Suscribirse',
                  width: double.infinity,
                  isLoading: true,
                  onPressed: null,
                ),
                error: (_, __) => PrimaryGlassButton(
                  key: const Key('paywall_subscribe_btn'),
                  text: 'Suscribirse',
                  width: double.infinity,
                  isLoading: false,
                  onPressed: null,
                ),
                // No package (init failed / unavailable): never an enabled dead button.
                data: (package) => package == null
                    ? PrimaryGlassButton(
                        key: const Key('paywall_subscribe_btn'),
                        text: deviceIsSpanish() ? 'Precio no disponible' : 'Price unavailable',
                        width: double.infinity,
                        isLoading: false,
                        onPressed: null,
                      )
                    : _SubscribeButton(package: package),
              ),

              const SizedBox(height: 16),

              // ── Dismiss ───────────────────────────────────────────────────
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Quizás después',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single entitlement row with green checkmark, title, and subtitle.
class _EntitlementRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EntitlementRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF00FF88).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF00FF88), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: Color(0xFF00FF88), size: 22),
      ],
    );
  }
}

/// Subscribe button that triggers the RevenueCat purchase flow.
class _SubscribeButton extends ConsumerStatefulWidget {
  final Package? package;

  const _SubscribeButton({required this.package});

  @override
  ConsumerState<_SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends ConsumerState<_SubscribeButton> {
  bool _isPurchasing = false;

  Future<void> _handleSubscribe() async {
    final package = widget.package;

    // Debug mode: package is null (mock product) → simulate purchase + unlock.
    if (kDebugMode && package == null) {
      setState(() => _isPurchasing = true);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      ref.read(debugPremiumOverrideProvider.notifier).state = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ QRaft Pro activado (modo prueba)'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
        Navigator.of(context).pop();
      }
      if (mounted) setState(() => _isPurchasing = false);
      return;
    }

    if (package == null) return;

    setState(() => _isPurchasing = true);

    try {
      // Route through PurchaseController so forceSync() + state updates fire correctly.
      final product = PurchaseProduct.fromPackage(package);
      final success = await ref.read(purchaseControllerProvider.notifier).purchase(product);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suscripcion activada. Disfruta QRaft Premium.'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted && !success) {
        final err = ref.read(purchaseControllerProvider).error?.message ?? 'Error al suscribirse';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deviceIsSpanish()
                  ? 'No pudimos completar la suscripción. Inténtalo de nuevo.'
                  : "We couldn't complete the subscription. Please try again.",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryGlassButton(
      key: const Key('paywall_subscribe_btn'),
      text: 'Suscribirse',
      width: double.infinity,
      isLoading: _isPurchasing,
      onPressed: widget.package != null ? _handleSubscribe : null,
    );
  }
}
