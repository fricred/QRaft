import 'dart:math' show log;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'domain/entities/qr_type.dart';
import 'presentation/pages/location_qr_screen.dart';
import 'presentation/pages/url_qr_screen.dart';
import 'presentation/pages/text_qr_screen.dart';
import 'presentation/pages/personal_info_qr_screen.dart';
import 'presentation/pages/email_qr_screen.dart';
import 'presentation/pages/wifi_qr_screen.dart';
import '../subscription/presentation/providers/feature_gate_providers.dart';
import '../subscription/presentation/widgets/pro_badge.dart';
import '../subscription/presentation/widgets/upgrade_bottom_sheet.dart';
import '../subscription/presentation/widgets/qr_limit_indicator.dart';

class QRGeneratorScreen extends ConsumerStatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  ConsumerState<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends ConsumerState<QRGeneratorScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                l10n.generateQRTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ).animate()
                .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                .slideY(begin: -0.15, duration: 300.ms, curve: Curves.easeOutQuart),
              
              const SizedBox(height: 8),
              
              Text(
                l10n.generateQRSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ).animate()
                .fadeIn(duration: 300.ms, delay: 50.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 16),

              // QR Limit Indicator for Free users
              const QRLimitIndicator(compact: true)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 100.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 24),
              
              // QR Type Selection Grid
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                    final aspectRatio = constraints.maxWidth > 600 ? 1.0 : 0.85;
                    
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: aspectRatio,
                      physics: const BouncingScrollPhysics(),
                      children: QRType.values.map((qrType) {
                        final index = QRType.values.indexOf(qrType);
                        final delay = (100 + (40.0 * log(index + 2))).toInt();
                        return _buildQRTypeCard(
                          qrType: qrType,
                          delay: delay,
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Template Library Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2E2E2E).withValues(alpha: 0.7),
                            const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.templateLibrary,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  l10n.templateLibraryDescription,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate()
                .fadeIn(duration: 300.ms, delay: 400.ms, curve: Curves.easeOutCubic)
                .slideY(begin: 0.15, duration: 300.ms, delay: 400.ms, curve: Curves.easeOutQuart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRTypeCard({
    required QRType qrType,
    required int delay,
  }) {
    final glowColor = Color(qrType.gradientColors.first);
    final access = ref.watch(qrTypeAccessProvider(qrType));
    final isLocked = !access.isAllowed;

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
                color: isLocked
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
                      onTap: () {
                        if (isLocked) {
                          UpgradeBottomSheet.show(context);
                          return;
                        }

                        Widget targetScreen;
                        switch (qrType) {
                          case QRType.url:
                            targetScreen = const URLQRScreen();
                            break;
                          case QRType.text:
                            targetScreen = const TextQRScreen();
                            break;
                          case QRType.personalInfo:
                            targetScreen = const PersonalInfoQRScreen();
                            break;
                          case QRType.email:
                            targetScreen = const EmailQRScreen();
                            break;
                          case QRType.wifi:
                            targetScreen = const WiFiQRScreen();
                            break;
                          case QRType.location:
                            targetScreen = LocationQRScreen();
                            break;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => targetScreen,
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
                                  colors: qrType.gradientColors.map((c) => Color(c)).toList(),
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
    ).animate()
      .fadeIn(duration: 300.ms, delay: delay.ms, curve: Curves.easeOutCubic)
      .slideY(begin: 0.15, duration: 300.ms, delay: delay.ms, curve: Curves.easeOutQuart)
      .scale(begin: const Offset(0.95, 0.95), duration: 300.ms, delay: delay.ms);
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
      default:
        return Icons.qr_code_rounded;
    }
  }

}