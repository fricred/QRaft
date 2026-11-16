import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qraft/l10n/app_localizations.dart';

import '../../domain/entities/purchase_product.dart';
import '../providers/purchase_providers.dart';
import 'product_card.dart';
import 'purchase_button.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';
import 'test_store_notice.dart';
import '../../data/datasources/revenuecat_datasource.dart';

/// Bottom sheet showing Pro features and upgrade options
class UpgradeBottomSheet extends ConsumerStatefulWidget {
  const UpgradeBottomSheet({super.key, this.freeLimit});

  /// When set, the sheet was opened because the free plan's QR limit was reached
  /// (QRAFT-10) and says so before listing the plans.
  final int? freeLimit;

  static Future<void> show(BuildContext context, {int? freeLimit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradeBottomSheet(freeLimit: freeLimit),
    );
  }

  @override
  ConsumerState<UpgradeBottomSheet> createState() => _UpgradeBottomSheetState();
}

class _UpgradeBottomSheetState extends ConsumerState<UpgradeBottomSheet> {
  PurchaseProduct? _selectedProduct;
  bool _busy = false;
  bool _showSuccess = false;

  /// Purchases/restores only run once RevenueCat is ready for the current user (never
  /// under a previous identity). Retries a failed initialization once. Debug builds
  /// without RevenueCat keep the simulated mock-purchase path.
  Future<bool> _ensurePaymentsReady() async {
    final userId = ref.read(supabaseAuthProvider).currentUser?.id;
    final container = ProviderScope.containerOf(context, listen: false);
    if (await ensureRevenueCatReady(container, userId)) return true;
    if (kDebugMode) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(Localizations.localeOf(context).languageCode == 'es'
          ? 'Los pagos no están disponibles en este momento. Revisa tu conexión e inténtalo de nuevo.'
          : 'Payments are not available right now. Check your connection and try again.'),
    ));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(purchaseProductsProvider);
    final purchaseState = ref.watch(purchaseControllerProvider);
    final annualSavings = ref.watch(annualSavingsProvider);

    // Listen for purchase success
    ref.listen<PurchaseControllerState>(purchaseControllerProvider, (
      prev,
      next,
    ) {
      // React to transitions only: the purchase controller is shared and never reset, so
      // a success/error from an earlier purchase or restore must not fire again.
      if (prev?.purchaseState != PurchaseState.success &&
          next.purchaseState == PurchaseState.success) {
        setState(() => _showSuccess = true);
      } else if (prev?.purchaseState != PurchaseState.error &&
          next.purchaseState == PurchaseState.error &&
          next.error?.shouldShowToUser == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.message),
            backgroundColor: Colors.red[700],
          ),
        );
      }
      // Handle restore success
      if (prev?.restoreState != PurchaseState.error &&
          next.restoreState == PurchaseState.error &&
          next.error?.shouldShowToUser != false) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'es'
              ? 'No pudimos restaurar tus compras. Inténtalo de nuevo.'
              : "We couldn't restore your purchases. Please try again."),
          backgroundColor: Colors.red[700],
        ));
      }
      if (prev?.restoreState != PurchaseState.success &&
          next.restoreState == PurchaseState.success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Localizations.localeOf(context).languageCode == 'es' ? '¡Compras restauradas!' : 'Purchases restored successfully!'),
            backgroundColor: const Color(0xFF00FF88),
          ),
        );
      }
    });

    if (_showSuccess) {
      return PurchaseSuccessOverlay(
        onDismiss: () => Navigator.of(context).pop(),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Header with rocket icon
            _buildHeader(l10n),

            if (widget.freeLimit != null) ...[
              const SizedBox(height: 16),
              Semantics(
                identifier: 'upgrade_limit_reason',
                child: Container(
                key: const Key('upgrade_limit_reason'),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF12324A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1A73E8)),
                ),
                child: Text(
                  Localizations.localeOf(context).languageCode == 'es'
                      ? 'Llegaste al límite de ${widget.freeLimit} códigos QR del plan gratuito. Pásate a Pro para crear más, o elimina uno de tu biblioteca.'
                      : "You've reached the free plan's limit of ${widget.freeLimit} QR codes. Go Pro to create more, or delete one from your library.",
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                ),
              ),
              ),
            ],

            const SizedBox(height: 24),

            // Features list
            ..._buildFeatures(l10n),

            const SizedBox(height: 24),

            // QRAFT-2: a release build with a Test Store key cannot sell. Show only the
            // notice: no plans, no purchase, no restore against an unconfigured SDK.
            if (RevenueCatDataSource.purchasesUnavailable)
              const TestStoreNotice(key: Key('upgrade_test_store_notice'))
            else ...[
              // Products list
              productsAsync.when(
                loading:
                    () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00FF88),
                          ),
                        ),
                      ),
                    ),
                error: (error, _) => _buildErrorState(l10n, error),
                data: (products) {
                  if (products.isEmpty) {
                    return _buildNoProductsState(l10n);
                  }

                  // Auto-select annual if available
                  _selectedProduct ??= products.firstWhere(
                    (p) => p.type == ProductType.annual,
                    orElse: () => products.first,
                  );

                  return Column(
                    children: [
                      ...products.asMap().entries.map((entry) {
                        final index = entry.key;
                        final product = entry.value;
                        final isAnnual = product.type == ProductType.annual;

                        return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ProductCard(
                                product: product,
                                isSelected: _selectedProduct?.id == product.id,
                                isRecommended: isAnnual,
                                savingsPercent: isAnnual ? annualSavings : null,
                                onTap: () {
                                  setState(() => _selectedProduct = product);
                                },
                              ),
                            )
                            .animate()
                            .fadeIn(delay: (index * 100).ms, duration: 300.ms)
                            .slideX(begin: 0.1, duration: 300.ms);
                      }),
                      const SizedBox(height: 16),
                      // Debug/profile with a Test Store key: say purchases are simulated.
                      if (RevenueCatDataSource.isTestStoreKey) ...[
                        const TestStoreNotice(
                          key: Key('upgrade_test_store_notice'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Purchase button
                      PurchaseButton(
                        product: _selectedProduct,
                        isLoading: purchaseState.isPurchasing,
                        onPressed:
                            _selectedProduct != null
                                ? () => _handlePurchase(_selectedProduct!)
                                : null,
                      ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Restore purchases
              RestorePurchasesButton(
                isLoading: purchaseState.isRestoring,
                onPressed: _handleRestore,
              ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
            ],

            // Maybe later
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.maybeLater,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 300.ms),

            // Legal text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                Localizations.localeOf(context).languageCode == 'es'
                    ? 'El pago se cargará a tu cuenta. La suscripción se renueva automáticamente salvo que la canceles al menos 24 horas antes del final del periodo actual.'
                    : 'Payment will be charged to your account. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.2),
                    const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                size: 40,
                color: Color(0xFFFFD700),
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
        const SizedBox(height: 16),
        Text(
          l10n.upgradeToProTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        const SizedBox(height: 8),
        Text(
          l10n.unlockAllPremiumFeatures,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
      ],
    );
  }

  List<Widget> _buildFeatures(AppLocalizations l10n) {
    final features = [
      (Icons.all_inclusive, l10n.unlimitedQRCodes, l10n.createAsManyAsYouNeed),
      (Icons.qr_code_2, l10n.allQRTypes, l10n.allQRTypesDesc),
      (Icons.palette, l10n.fullCustomization, l10n.fullCustomizationDesc),
      (Icons.history, l10n.unlimitedHistory, l10n.accessAllScanHistory),
    ];

    return features.asMap().entries.map((entry) {
      final index = entry.key;
      final feature = entry.value;

      return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FeatureRow(
              icon: feature.$1,
              title: feature.$2,
              subtitle: feature.$3,
            ),
          )
          .animate()
          .fadeIn(delay: (200 + index * 100).ms, duration: 300.ms)
          .slideX(begin: -0.1, duration: 300.ms);
    }).toList();
  }

  Widget _buildErrorState(AppLocalizations l10n, Object error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text(
            'Unable to load products',
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.invalidate(purchaseProductsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProductsState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.construction_rounded,
            size: 40,
            color: const Color(0xFF00FF88).withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.comingSoonBanner,
            style: const TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.proSubscriptionsComingSoon,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(PurchaseProduct product) async {
    if (_busy) return; // one purchase/restore at a time (no double taps while waiting)
    _busy = true;
    try {
      if (!await _ensurePaymentsReady()) return;
      await ref.read(purchaseControllerProvider.notifier).purchase(product);
    } finally {
      _busy = false;
    }
  }

  Future<void> _handleRestore() async {
    if (_busy) return; // one purchase/restore at a time (no double taps while waiting)
    _busy = true;
    try {
      if (!await _ensurePaymentsReady()) return;
      await ref.read(purchaseControllerProvider.notifier).restorePurchases();
    } finally {
      _busy = false;
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFFFFD700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, size: 20, color: Color(0xFF22C55E)),
        ],
      ),
    );
  }
}
