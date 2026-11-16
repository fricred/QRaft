import 'dart:math' show log;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../subscription/presentation/providers/subscription_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'domain/entities/qr_type.dart';
import 'presentation/pages/qr_templates_screen.dart';
import '../subscription/presentation/providers/feature_gate_providers.dart';
import '../subscription/presentation/widgets/pro_badge.dart';
import '../subscription/presentation/widgets/upgrade_bottom_sheet.dart';
import '../subscription/presentation/widgets/qr_limit_indicator.dart';
import '../dynamic_qr/presentation/limit_choice_sheet.dart';
import '../dynamic_qr/presentation/dynamic_mode_toggle.dart';
import '../dynamic_qr/presentation/purchase_flow.dart';

class QRGeneratorScreen extends ConsumerStatefulWidget {
  const QRGeneratorScreen({super.key, this.initialDynamic = false});

  /// Opens in "Dinámico" mode (e.g. from "+ Nuevo QR dinámico").
  final bool initialDynamic;

  @override
  ConsumerState<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends ConsumerState<QRGeneratorScreen> {
  late bool _dynamic = widget.initialDynamic;

  void _openTemplates(QRType qrType, {required bool dynamic}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QRTemplatesScreen(qrType: qrType, preferDynamic: dynamic),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        // QRAFT-14: one scroll view, so the header scrolls away with the grid instead of
        // eating the height in landscape; columns adapt to the available width.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);
            final aspectRatio = width > 600 ? 1.0 : 0.85;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                              l10n.generateQRTitle,
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            )
                            .animate()
                            .fadeIn(
                              duration: 300.ms,
                              curve: Curves.easeOutCubic,
                            )
                            .slideY(
                              begin: -0.15,
                              duration: 300.ms,
                              curve: Curves.easeOutQuart,
                            ),

                        const SizedBox(height: 8),

                        Text(
                          l10n.generateQRSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[400], fontSize: 16),
                        ).animate().fadeIn(
                          duration: 300.ms,
                          delay: 50.ms,
                          curve: Curves.easeOutCubic,
                        ),

                        const SizedBox(height: 16),

                        // QR Limit Indicator for Free users
                        const QRLimitIndicator(compact: true).animate().fadeIn(
                          duration: 300.ms,
                          delay: 100.ms,
                          curve: Curves.easeOutCubic,
                        ),

                        const SizedBox(height: 16),

                        // Estático (free quota) | Dinámico (paid, featured).
                        DynamicModeToggle(
                          dynamic: _dynamic,
                          onChanged: (v) => setState(() => _dynamic = v),
                          staticCaption: Localizations.localeOf(context).languageCode == 'es'
                              ? (ref.watch(canCreateQRProvider) ? 'Gratis' : 'Requiere Pro')
                              : (ref.watch(canCreateQRProvider) ? 'Free' : 'Requires Pro'),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  sliver: SliverGrid.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: aspectRatio,
                    children:
                        QRType.values.map((qrType) {
                          final index = QRType.values.indexOf(qrType);
                          final delay = (100 + (40.0 * log(index + 2))).toInt();
                          return _buildQRTypeCard(qrType: qrType, delay: delay);
                        }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQRTypeCard({required QRType qrType, required int delay}) {
    final glowColor = Color(qrType.gradientColors.first);
    final access = ref.watch(qrTypeAccessProvider(qrType));
    // Dynamic codes include every type: no PRO lock, the price is shown instead.
    final isLocked = !_dynamic && !access.isAllowed;

    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2E2E2E).withValues(alpha: 0.7),
                      const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isLocked
                            ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Main card content
                    Opacity(
                      opacity: isLocked ? 0.6 : 1.0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            if (_dynamic) {
                              _openTemplates(qrType, dynamic: true);
                              return;
                            }
                            if (isLocked) {
                              UpgradeBottomSheet.show(context);
                              return;
                            }

                            // QRAFT-10: tell the user about the free limit before they fill a
                            // whole QR, not only when they press Save.
                            // Only with the plan and QR count actually loaded: while they load,
                            // limits fall back to "free" and a Pro user would be wrongly blocked
                            // (Save still enforces the limit either way).
                            // canCreateQRProvider never blocks while the plan loads.
                            if (!ref.read(canCreateQRProvider)) {
                              // At the free limit a paid dynamic QR is still possible
                              // (it doesn't count): offer it next to Pro.
                              final choice = await showLimitChoiceSheet(context, freeLimit: ref.read(qrLimitProvider));
                              if (!context.mounted || choice == null) return;
                              if (choice == LimitChoice.pro) {
                                UpgradeBottomSheet.show(context, freeLimit: ref.read(qrLimitProvider));
                                return;
                              }
                              setState(() => _dynamic = true);
                              _openTemplates(qrType, dynamic: true);
                              return;
                            }

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        QRTemplatesScreen(qrType: qrType),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors:
                                          qrType.gradientColors
                                              .map((c) => Color(c))
                                              .toList(),
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: glowColor.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _getIconData(qrType.iconName),
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Flexible(
                                  child: Text(
                                    qrType.getDisplayName(context),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Text(
                                    qrType.getDescription(context),
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                      height: 1.2,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_dynamic)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF00FF88), borderRadius: BorderRadius.circular(999)),
                          child: Text(
                            ref.watch(dynamicQrPackageProvider).value?.storeProduct.priceString ?? 'US\$9.99',
                            style: const TextStyle(color: Color(0xFF04140D), fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    // PRO badge for locked features
                    if (isLocked)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: ProBadge(mini: true),
                      ),
                    // Lock icon overlay for locked features
                    if (isLocked)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: delay.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.15,
          duration: 300.ms,
          delay: delay.ms,
          curve: Curves.easeOutQuart,
        )
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: 300.ms,
          delay: delay.ms,
        );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person_rounded':
        return Icons.person_rounded;
      case 'link_rounded':
        return Icons.link_rounded;
      case 'wifi_rounded':
        return Icons.wifi_rounded;
      case 'text_fields_rounded':
        return Icons.text_fields_rounded;
      case 'email_rounded':
        return Icons.email_rounded;
      case 'location_on_rounded':
        return Icons.location_on_rounded;
      case 'event_rounded':
        return Icons.event_rounded;
      default:
        return Icons.qr_code_rounded;
    }
  }
}
