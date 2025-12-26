import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';

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
                  onTap: () => _navigateToQRLibrary(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history_rounded,
                  label: l10n.scanHistory,
                  color: const Color(0xFF00FF88),
                  onTap: () => _navigateToScanHistory(context),
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
                  onTap: () => _navigateToOrders(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_rounded,
                  label: l10n.shareProfile,
                  color: const Color(0xFF9C27B0),
                  onTap: () => _shareProfile(context),
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
            onTap: () => _exportData(context, l10n),
          ),

          const SizedBox(height: 8),

          _buildActionListItem(
            icon: Icons.backup_rounded,
            title: l10n.backupSync,
            subtitle: l10n.backupSyncDescription,
            onTap: () => _backupData(context, l10n),
          ),

          const SizedBox(height: 8),

          _buildActionListItem(
            icon: Icons.security_rounded,
            title: l10n.privacySecurity,
            subtitle: l10n.privacySecurityDescription,
            onTap: () => _navigateToPrivacySettings(context, l10n),
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

  void _navigateToQRLibrary(BuildContext context) {
    // TODO: Navigate to QR Library screen
    debugPrint('Navigate to QR Library');
  }

  void _navigateToScanHistory(BuildContext context) {
    // TODO: Navigate to Scan History screen
    debugPrint('Navigate to Scan History');
  }

  void _navigateToOrders(BuildContext context) {
    // TODO: Navigate to Orders screen
    debugPrint('Navigate to Orders');
  }

  void _shareProfile(BuildContext context) {
    // TODO: Implement profile sharing
    debugPrint('Share Profile');
  }

  void _exportData(BuildContext context, AppLocalizations l10n) {
    // TODO: Implement data export
    debugPrint('Export Data');
    _showComingSoonDialog(context, l10n, l10n.exportData);
  }

  void _backupData(BuildContext context, AppLocalizations l10n) {
    // TODO: Implement data backup
    debugPrint('Backup Data');
    _showComingSoonDialog(context, l10n, l10n.backupSync);
  }

  void _navigateToPrivacySettings(BuildContext context, AppLocalizations l10n) {
    // TODO: Navigate to Privacy Settings
    debugPrint('Navigate to Privacy Settings');
    _showComingSoonDialog(context, l10n, l10n.privacySecurity);
  }

  void _showComingSoonDialog(BuildContext context, AppLocalizations l10n, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.comingSoon,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.featureComingSoon(feature),
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.ok,
              style: const TextStyle(color: Color(0xFF00FF88)),
            ),
          ),
        ],
      ),
    );
  }
}