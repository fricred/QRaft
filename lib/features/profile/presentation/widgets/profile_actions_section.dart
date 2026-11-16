import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';
import '../../../main/main_scaffold.dart' show navigationIndexProvider;
import '../../../qr_scanner/widgets/scan_history_screen.dart';
import '../../../legal/presentation/pages/habeas_data_screen.dart';
import '../../../legal/presentation/pages/privacy_policy_screen.dart';


class ProfileActionsSection extends ConsumerWidget {
  const ProfileActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withValues(alpha: 0.1),
            blurRadius: 12,
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
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickActions,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons grid
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_rounded,
                  label: l10n.myQRCodes,
                  color: const Color(0xFF1A73E8),
                  onTap: () => _openTab(context, ref, 3), // Library
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history_rounded,
                  label: l10n.scanHistory,
                  color: const Color(0xFF00FF88),
                  onTap: () => _push(context, const ScanHistoryScreen()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.shopping_bag_rounded,
                  label: l10n.myOrders,
                  color: const Color(0xFFFF6B6B),
                  onTap: () => _openTab(context, ref, 5), // Orders
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_rounded,
                  label: l10n.shareProfile,
                  color: const Color(0xFF9C27B0),
                  onTap: () => _shareProfile(context, ref),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Additional actions
          _buildActionListItem(
            icon: Icons.download_rounded,
            title: l10n.exportData,
            subtitle: l10n.exportDataDescription,
            onTap: () => _push(context, const HabeasDataScreen()),
          ),


          const SizedBox(height: 8),

          _buildActionListItem(
            icon: Icons.security_rounded,
            title: l10n.privacySecurity,
            subtitle: l10n.privacySecurityDescription,
            onTap: () => _push(context, const PrivacyPolicyScreen()),
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionListItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF00FF88).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF00FF88),
          size: 20,
        ),
      ),
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

  // QRAFT-7: every action opens something real. Backup & Sync was removed: QR codes are
  // already stored in the cloud, so it could only ever show "coming soon".

  /// Switches the bottom-nav tab and returns to the main shell.
  void _openTab(BuildContext context, WidgetRef ref, int index) {
    ref.read(navigationIndexProvider.notifier).state = index;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  /// Shares the user's contact card as text through the system share sheet.
  Future<void> _shareProfile(BuildContext context, WidgetRef ref) async {
    final user = ref.read(supabaseAuthProvider).currentUser;
    if (user == null) return;
    final name = (user.userMetadata?['display_name'] as String?)?.trim();
    final lines = <String>[
      if (name != null && name.isNotEmpty) name,
      if (user.email != null) user.email!,
    ];
    if (lines.isEmpty) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(ShareParams(
      text: lines.join('\n'),
      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    ));
  }
}