import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qraft/l10n/app_localizations.dart';

import '../../domain/entities/purchase_product.dart';
import '../providers/purchase_providers.dart';
import 'product_card.dart';
import 'purchase_button.dart';

/// Bottom sheet showing Pro features and upgrade options
class UpgradeBottomSheet extends ConsumerStatefulWidget {
  const UpgradeBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UpgradeBottomSheet(),
    );
  }

  @override
  ConsumerState<UpgradeBottomSheet> createState() => _UpgradeBottomSheetState();
}

class _UpgradeBottomSheetState extends ConsumerState<UpgradeBottomSheet> {
  PurchaseProduct? _selectedProduct;
  bool _showSuccess = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(purchaseProductsProvider);
    final purchaseState = ref.watch(purchaseControllerProvider);
    final annualSavings = ref.watch(annualSavingsProvider);

    // Listen for purchase success
    ref.listen<PurchaseControllerState>(purchaseControllerProvider, (prev, next) {
      if (next.purchaseState == PurchaseState.success) {
        setState(() => _showSuccess = true);
      } else if (next.purchaseState == PurchaseState.error && next.error?.shouldShowToUser == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.message),
            backgroundColor: Colors.red[700],
          ),
        );
      }
      // Handle restore success
      if (next.restoreState == PurchaseState.success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully!'),
            backgroundColor: Color(0xFF00FF88),
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

            const SizedBox(height: 24),

            // Features list
            ..._buildFeatures(l10n),

            const SizedBox(height: 24),

            // Products list
            productsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
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
                    // Purchase button
                    PurchaseButton(
                      product: _selectedProduct,
                      isLoading: purchaseState.isPurchasing,
                      onPressed: _selectedProduct != null
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
                'Payment will be charged to your account. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.',
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
          Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.red[300],
          ),
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
    await ref.read(purchaseControllerProvider.notifier).purchase(product);
  }

  Future<void> _handleRestore() async {
    await ref.read(purchaseControllerProvider.notifier).restorePurchases();
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
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFFFFD700),
            ),
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
          const Icon(
            Icons.check_circle,
            size: 20,
            color: Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }
}
