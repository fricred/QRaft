import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../../../../core/utils/friendly_error.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import '../../../legal/presentation/pages/habeas_data_screen.dart';
import '../../../legal/presentation/pages/pqrs_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../legal/presentation/pages/privacy_policy_screen.dart';
import '../../../legal/presentation/pages/terms_screen.dart';
import '../../../legal/presentation/pages/garantia_screen.dart';
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
import '../../../subscription/domain/entities/subscription_plan.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../operator/presentation/providers/operator_providers.dart';
import '../../../operator/presentation/pages/operator_orders_screen.dart';

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
          Semantics(
            identifier: 'profile_settings_button',
            child: IconButton(
            tooltip: l10n.settings,
            onPressed: () {
              _showSettingsMenu(context, ref, l10n);
            },
            icon: Icon(
              Icons.settings_rounded,
              color: Colors.grey[400],
            ),
          )),
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

              const SizedBox(height: 24),

              // Operator dashboard link (only shown to operator-role users)
              _buildOperatorSection(context, ref)
                  .animate(delay: 325.ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOutQuart)
                  .scale(begin: const Offset(0.95, 0.95), duration: 300.ms),

              const SizedBox(height: 24),

              // Legal y soporte section
              _buildLegalSection(context)
                  .animate(delay: 350.ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOutQuart)
                  .scale(begin: const Offset(0.95, 0.95), duration: 300.ms),

              const SizedBox(height: 32),

              // Sign out button — Maestro selector: profile_sign_out_button
              Semantics(
                identifier: 'profile_sign_out_button',
                button: true,
                label: l10n.signOut,
                child: GlassButton(
                  key: const Key('profile_sign_out_button'),
                  text: l10n.signOut,
                  onPressed: () async {
                    await _showSignOutDialog(context, ref, l10n);
                  },
                  width: double.infinity,
                  gradientColors: [Colors.red[400]!, Colors.red[600]!],
                ),
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
                // QRAFT-7: notification permission lives in the OS settings for the app.
                openAppSettings();
              },
            ),
            _buildSettingsItem(
              icon: Icons.privacy_tip_rounded,
              title: l10n.privacy,
              subtitle: l10n.dataPrivacySettings,
              onTap: () {
                final nav = Navigator.of(context); // capture before closing the sheet
                nav.pop();
                nav.push(MaterialPageRoute<void>(builder: (_) => const HabeasDataScreen()));
              },
            ),
            _buildSettingsItem(
              icon: Icons.help_rounded,
              title: l10n.helpSupport,
              subtitle: l10n.helpSupportDescription,
              onTap: () {
                // QRAFT-7: the only support channel today is the PQRS form.
                final nav = Navigator.of(context); // capture before closing the sheet
                nav.pop();
                nav.push(MaterialPageRoute<void>(builder: (_) => const PqrsScreen()));
              },
            ),
            // QRAFT-19 (P2-05): store requirement, account deletion from inside the app.
            Semantics(
              identifier: 'profile_delete_account_item',
              child: ListTile(
                leading: Icon(Icons.delete_forever_rounded, color: Colors.red[400]),
                title: Text(
                  _es(context) ? 'Eliminar cuenta' : 'Delete account',
                  style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _es(context)
                      ? 'Borra tu cuenta y tus datos de forma permanente'
                      : 'Permanently delete your account and data',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                onTap: () {
                  final nav = Navigator.of(context, rootNavigator: true);
                  Navigator.of(context).pop();
                  _showDeleteAccountDialog(nav.context, ref);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  bool _es(BuildContext context) => Localizations.localeOf(context).languageCode == 'es';

  Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
    final es = _es(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          es ? '¿Eliminar tu cuenta?' : 'Delete your account?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          es
              ? 'Se borrarán tu perfil, tus códigos QR y tu historial de escaneos. No se puede deshacer.\n\n'
                  'Si tienes pedidos, se conservan solo para fines contables, sin tus datos de acceso.\n\n'
                  'Una suscripción activa no se cancela sola: cancélala en la tienda de aplicaciones.'
              : 'Your profile, QR codes and scan history will be deleted. This cannot be undone.\n\n'
                  'If you have orders, they are kept only for accounting, without your login data.\n\n'
                  'An active subscription is not cancelled automatically: cancel it in the app store.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(es ? 'Cancelar' : 'Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          Semantics(
            identifier: 'profile_delete_account_confirm_button',
            button: true,
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                es ? 'Eliminar' : 'Delete',
                style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
        ),
      ),
    );
    final auth = ref.read(supabaseAuthProvider); // read before any await
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      // Profile photos live in the public 'avatars' bucket under <uid>/: remove them first
      // (the RPC can't touch Storage). A failure here stops the deletion so no photo is
      // left public behind a deleted account.
      if (uid != null) {
        final files = await client.storage
            .from('avatars')
            .list(path: uid)
            .timeout(const Duration(seconds: 15));
        if (files.isNotEmpty) {
          final removed = await client.storage
              .from('avatars')
              .remove([for (final f in files) '$uid/${f.name}'])
              .timeout(const Duration(seconds: 15));
          // Storage policies deny silently (empty result): never leave a public photo.
          if (removed.length < files.length) {
            throw StateError('avatar removal incomplete');
          }
        }
      }
      await client.rpc('delete_my_account').timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('Account deletion failed: $e');
      if (navigator.mounted) navigator.pop(); // loading
      messenger.showSnackBar(SnackBar(
        content: Text(
          friendlyErrorMessage(e, spanish: es),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red[700],
      ));
      return;
    }
    // The server already removed the account; this only clears the local session.
    await auth.signOut();
    if (navigator.mounted) navigator.popUntil((route) => route.isFirst);
    messenger.showSnackBar(SnackBar(
      content: Text(
        es ? 'Tu cuenta fue eliminada.' : 'Your account was deleted.',
        style: const TextStyle(color: Colors.white),
      ),
    ));
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
              return Semantics(
                identifier: 'profile_sign_out_confirm_button',
                button: true,
                label: deviceIsSpanish() ? 'Confirmar cierre de sesión' : 'Confirm sign out',
                child: TextButton(
                  key: const Key('profile_sign_out_confirm_button'),
                  onPressed: authProvider.isLoading ? null : () async {
                    // QRAFT-8: capture the root navigator BEFORE closing this dialog. This
                    // dialog's own context is gone after pop(), so using it afterwards left
                    // the "Signing out…" dialog on screen forever.
                    final navigator = Navigator.of(context, rootNavigator: true);
                    navigator.pop(); // close the confirmation dialog

                    showDialog<void>(
                      context: navigator.context,
                      barrierDismissible: false,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF2E2E2E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        content: Row(
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
                            ),
                            const SizedBox(width: 16),
                            Text(l10n.signingOut, style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    );

                    // signOut never throws (errors go to the provider) and is bounded in time.
                    await authProvider.signOut();

                    // Close the loading dialog and any pushed routes so the auth flow (or,
                    // if sign-out failed, the app with its error snackbar) is visible.
                    if (navigator.mounted) {
                      navigator.popUntil((route) => route.isFirst);
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Open the device's subscription management (App Store / Google Play)
  Future<void> _openSubscriptionManagement(BuildContext context) async {
    final url = Platform.isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';

    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open subscription management'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  /// Get the display name for the subscription plan
  String _getPlanDisplayName(SubscriptionPlan plan, AppLocalizations l10n) {
    if (!plan.hasProAccess) return l10n.free;

    switch (plan.periodType) {
      case SubscriptionPeriod.monthly:
        return l10n.proMonthly;
      case SubscriptionPeriod.annual:
        return l10n.proAnnual;
      case SubscriptionPeriod.lifetime:
        return l10n.proLifetime;
      default:
        return l10n.pro;
    }
  }

  /// Get the subscription info text (renewal/expiration date)
  String? _getSubscriptionInfo(SubscriptionPlan plan, AppLocalizations l10n) {
    if (!plan.hasProAccess) return null;

    // Lifetime plans never expire
    if (plan.periodType == SubscriptionPeriod.lifetime) {
      return l10n.neverExpires;
    }

    // Billing issue - show warning
    if (plan.status == SubscriptionStatus.billingIssue) {
      return l10n.billingIssue;
    }

    // Show renewal or expiration date
    if (plan.expiresAt != null) {
      final dateStr = DateFormat.yMMMd(deviceIsSpanish() ? 'es' : 'en').add_Hm().format(plan.expiresAt!.toLocal());
      if (plan.status == SubscriptionStatus.cancelled) {
        return l10n.expiresOn(dateStr);
      }
      return l10n.renewsOn(dateStr);
    }

    return null;
  }

  /// Operator dashboard section — only visible to users with operator_profiles row.
  ///
  /// Checks [isOperatorProvider] and renders nothing for consumer users (T-11-10).
  Widget _buildOperatorSection(BuildContext context, WidgetRef ref) {
    final isOperatorAsync = ref.watch(isOperatorProvider);

    return isOperatorAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (isOperator) {
        if (!isOperator) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1A73E8).withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A73E8), Color(0xFF00FF88)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Operador',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 1),
              ListTile(
                key: const Key('profile_operator_dashboard_tile'),
                leading: const Icon(
                  Icons.dashboard_rounded,
                  color: Color(0xFF1A73E8),
                ),
                title: const Text(
                  'Panel de Operador',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Gestionar pedidos',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.grey[600],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OperatorOrdersScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Legal y soporte',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(color: Color(0xFF3A3A3A), height: 1),
          Semantics(
            identifier: 'profile_privacy_policy_tile',
            child: ListTile(
              key: const Key('profile_privacy_policy_tile'),
              leading: const Icon(
                Icons.privacy_tip_outlined,
                color: Color(0xFF00FF88),
              ),
              title: const Text(
                'Política de privacidad',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const PrivacyPolicyScreen()),
              ),
            ),
          ),
          const Divider(color: Color(0xFF3A3A3A), height: 1, indent: 56),
          Semantics(
            identifier: 'profile_terms_tile',
            child: ListTile(
              key: const Key('profile_terms_tile'),
              leading: const Icon(
                Icons.policy_outlined,
                color: Color(0xFF00FF88),
              ),
              title: const Text(
                'Términos y condiciones',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TermsScreen()),
              ),
            ),
          ),
          const Divider(color: Color(0xFF3A3A3A), height: 1, indent: 56),
          Semantics(
            identifier: 'profile_habeas_data_tile',
            child: ListTile(
              key: const Key('profile_habeas_data_tile'),
              leading: const Icon(
                Icons.manage_accounts_outlined,
                color: Color(0xFF00FF88),
              ),
              title: const Text(
                'Mis datos personales',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const HabeasDataScreen()),
              ),
            ),
          ),
          const Divider(color: Color(0xFF3A3A3A), height: 1, indent: 56),
          Semantics(
            identifier: 'profile_garantia_tile',
            child: ListTile(
              key: const Key('profile_garantia_tile'),
              leading: const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF00FF88),
              ),
              title: const Text(
                'Garantía 3 meses',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const GarantiaScreen()),
              ),
            ),
          ),
          const Divider(color: Color(0xFF3A3A3A), height: 1, indent: 56),
          Semantics(
            identifier: 'profile_pqrs_tile',
            child: ListTile(
              key: const Key('profile_pqrs_tile'),
              leading: const Icon(
                Icons.feedback_outlined,
                color: Color(0xFF00FF88),
              ),
              title: const Text(
                'PQRS',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Peticiones, quejas, reclamos y sugerencias',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PqrsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final subscriptionAsync = ref.watch(subscriptionPlanProvider);

    return subscriptionAsync.when(
      data: (subscription) => _buildSubscriptionCard(context, ref, l10n, subscription),
      loading: () => _buildSubscriptionCard(context, ref, l10n, const SubscriptionPlan()),
      error: (_, __) => _buildSubscriptionCard(context, ref, l10n, const SubscriptionPlan()),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, WidgetRef ref, AppLocalizations l10n, SubscriptionPlan subscription) {
    final hasPro = subscription.hasProAccess;
    final planName = _getPlanDisplayName(subscription, l10n);
    final subscriptionInfo = _getSubscriptionInfo(subscription, l10n);

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
                            planName,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                          if (subscriptionInfo != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (subscription.periodType == SubscriptionPeriod.lifetime)
                                  Icon(
                                    Icons.all_inclusive_rounded,
                                    color: const Color(0xFF00FF88),
                                    size: 12,
                                  )
                                else if (subscription.status == SubscriptionStatus.billingIssue)
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 12,
                                  )
                                else
                                  Icon(
                                    Icons.schedule_rounded,
                                    color: Colors.grey[500],
                                    size: 12,
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  subscriptionInfo,
                                  style: TextStyle(
                                    color: subscription.status == SubscriptionStatus.billingIssue
                                        ? Colors.orange
                                        : subscription.periodType == SubscriptionPeriod.lifetime
                                            ? const Color(0xFF00FF88)
                                            : Colors.grey[500],
                                    fontSize: 11,
                                    fontWeight: subscription.status == SubscriptionStatus.billingIssue
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                  const SizedBox(height: 16),
                  // Manage Subscription button
                  TextButton.icon(
                    onPressed: () => _openSubscriptionManagement(context),
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    label: Text(
                      l10n.manageSubscription,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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