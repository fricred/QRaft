import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header.dart';
import '../widgets/inline_editable_profile_info.dart' show ProfileInfoSection;
import '../widgets/profile_stats_section.dart';
import '../widgets/profile_actions_section.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../subscription/presentation/widgets/qr_limit_indicator.dart';
import '../../../subscription/presentation/widgets/upgrade_bottom_sheet.dart';
import '../../../subscription/presentation/widgets/pro_badge.dart';
import '../../../../core/providers/locale_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.watch(profileControllerProvider);
    final isLoading = ref.watch(profileLoadingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.profile,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showSettingsMenu(context, ref, l10n);
            },
            icon: Icon(
              Icons.settings_rounded,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(profileControllerProvider.notifier).refreshProfile();
        },
        color: const Color(0xFF00FF88),
        backgroundColor: const Color(0xFF2E2E2E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Error message
              if (profileState.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[400]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          profileState.errorMessage!,
                          style: TextStyle(color: Colors.red[400]),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(profileControllerProvider.notifier).clearError();
                        },
                        icon: Icon(Icons.close, color: Colors.red[400]),
                        iconSize: 16,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),

              // Loading indicator
              if (isLoading)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(
                    backgroundColor: const Color(0xFF2E2E2E),
                    valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00FF88)),
                  ),
                ),

              // Profile header
              ProfileHeader(profile: profileState.profile)
                  .animate()
                  .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: -0.15, end: 0, duration: 300.ms, curve: Curves.easeOutQuart),

              const SizedBox(height: 24),

              // Profile stats
              ProfileStatsSection(profile: profileState.profile)
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOutQuart)
                  .scale(begin: const Offset(0.95, 0.95), duration: 300.ms),

              const SizedBox(height: 24),

              // Subscription section
              _buildSubscriptionSection(context, ref, l10n)
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOutQuart)
                  .scale(begin: const Offset(0.95, 0.95), duration: 300.ms),

              const SizedBox(height: 24),

              // Profile info with edit button (opens modal for editing)
              ProfileInfoSection(
                profile: profileState.profile,
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOutQuart)
                  .scale(begin: const Offset(0.95, 0.95), duration: 300.ms),

              const SizedBox(height: 24),

              // Profile actions
              ProfileActionsSection()
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOutQuart)
                  .scale(begin: const Offset(0.95, 0.95), duration: 300.ms),

              const SizedBox(height: 32),

              // Sign out button
              GlassButton(
                text: l10n.signOut,
                onPressed: () async {
                  await _showSignOutDialog(context, ref, l10n);
                },
                width: double.infinity,
                gradientColors: [Colors.red[400]!, Colors.red[600]!],
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOutQuart),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsMenu(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.settings,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              icon: Icons.language_rounded,
              title: l10n.language,
              subtitle: _getLanguageDisplayName(ref),
              onTap: () {
                Navigator.pop(context);
                showLanguageSelector(context);
              },
            ),
            _buildSettingsItem(
              icon: Icons.notifications_rounded,
              title: l10n.notifications,
              subtitle: l10n.pushNotifications,
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement notification settings
              },
            ),
            _buildSettingsItem(
              icon: Icons.privacy_tip_rounded,
              title: l10n.privacy,
              subtitle: l10n.dataPrivacySettings,
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement privacy settings
              },
            ),
            _buildSettingsItem(
              icon: Icons.help_rounded,
              title: l10n.helpSupport,
              subtitle: l10n.helpSupportDescription,
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement help screen
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getLanguageDisplayName(WidgetRef ref) {
    final localeNotifier = ref.read(localeProvider.notifier);
    return localeNotifier.getCurrentLanguageName();
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00FF88)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.grey[600],
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Future<void> _showSignOutDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.exit_to_app_rounded,
              color: Colors.red[400],
            ),
            const SizedBox(width: 8),
            Text(
              l10n.signOut,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          l10n.signOutConfirm,
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final authProvider = ref.watch(supabaseAuthProvider);
              return TextButton(
                onPressed: authProvider.isLoading ? null : () async {
                  try {
                    // Close sign out dialog first
                    Navigator.pop(context);
                    
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF2E2E2E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        content: Row(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00FF88)),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              l10n.signingOut,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                    
                    // Perform sign out
                    await authProvider.signOut();
                    
                    // Close loading dialog - AuthWrapper will handle navigation automatically
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    // Close loading dialog if it's still open
                    if (context.mounted) {
                      Navigator.pop(context);
                      
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.signOutFailed),
                          backgroundColor: Colors.red[700],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                },
                child: authProvider.isLoading 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red[400]!),
                      ),
                    )
                  : Text(
                      l10n.signOut,
                      style: TextStyle(color: Colors.red[400]),
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final hasPro = ref.watch(hasProAccessProvider);
    final planName = hasPro ? 'Pro' : 'Free';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: hasPro
                ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
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
                color: hasPro
                    ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: hasPro
                            ? const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF4B5563), Color(0xFF374151)],
                              ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        hasPro ? Icons.star_rounded : Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.subscription,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (hasPro) const ProBadge(mini: true),
                            ],
                          ),
                          Text(
                            '$planName ${l10n.plan}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (!hasPro) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF3A3A3A)),
                  const SizedBox(height: 16),

                  // QR Limit for free users
                  const QRLimitIndicator(compact: false),

                  const SizedBox(height: 16),

                  // Upgrade button
                  GestureDetector(
                    onTap: () => UpgradeBottomSheet.show(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.rocket_launch_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.upgradeToPro,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: const Color(0xFF00FF88),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.unlimitedQRCodes,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: const Color(0xFF00FF88),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.allFeatures,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}