import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header.dart';
import '../widgets/inline_editable_profile_info.dart';
import '../widgets/profile_stats_section.dart';
import '../widgets/profile_actions_section.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';
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
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.1, end: 0, duration: 600.ms),

              const SizedBox(height: 24),

              // Profile stats
              ProfileStatsSection(profile: profileState.profile)
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.1, end: 0, duration: 600.ms),

              const SizedBox(height: 24),

              // Profile info with inline editing
              InlineEditableProfileInfo(
                profile: profileState.profile,
                onFieldSave: (field, value) async {
                  switch (field) {
                    case 'display_name':
                      await ref.read(profileControllerProvider.notifier).updateProfile(displayName: value);
                      break;
                    case 'phone_number':
                      await ref.read(profileControllerProvider.notifier).updateProfile(phoneNumber: value);
                      break;
                    case 'bio':
                      await ref.read(profileControllerProvider.notifier).updateProfile(bio: value);
                      break;
                    case 'location':
                      await ref.read(profileControllerProvider.notifier).updateProfile(location: value);
                      break;
                    case 'website':
                      await ref.read(profileControllerProvider.notifier).updateProfile(website: value);
                      break;
                    case 'company':
                      await ref.read(profileControllerProvider.notifier).updateProfile(company: value);
                      break;
                    case 'job_title':
                      await ref.read(profileControllerProvider.notifier).updateProfile(jobTitle: value);
                      break;
                  }
                },
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.1, end: 0, duration: 600.ms),

              const SizedBox(height: 24),

              // Profile actions
              ProfileActionsSection()
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.1, end: 0, duration: 600.ms),

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
                  .animate(delay: 800.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.1, end: 0, duration: 600.ms),

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
}