import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileActionsSection extends ConsumerWidget {
  const ProfileActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
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
                  label: 'My QR Codes',
                  color: const Color(0xFF1A73E8),
                  onTap: () => _navigateToQRLibrary(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history_rounded,
                  label: 'Scan History',
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
                  label: 'My Orders',
                  color: const Color(0xFFFF6B6B),
                  onTap: () => _navigateToOrders(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share Profile',
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
            title: 'Export Data',
            subtitle: 'Download your QR codes and data',
            onTap: () => _exportData(context),
          ),

          const SizedBox(height: 8),

          _buildActionListItem(
            icon: Icons.backup_rounded,
            title: 'Backup & Sync',
            subtitle: 'Backup your data to cloud',
            onTap: () => _backupData(context),
          ),

          const SizedBox(height: 8),

          _buildActionListItem(
            icon: Icons.security_rounded,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            onTap: () => _navigateToPrivacySettings(context),
          ),
        ],
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
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

  void _exportData(BuildContext context) {
    // TODO: Implement data export
    debugPrint('Export Data');
    _showComingSoonDialog(context, 'Export Data');
  }

  void _backupData(BuildContext context) {
    // TODO: Implement data backup
    debugPrint('Backup Data');
    _showComingSoonDialog(context, 'Backup & Sync');
  }

  void _navigateToPrivacySettings(BuildContext context) {
    // TODO: Navigate to Privacy Settings
    debugPrint('Navigate to Privacy Settings');
    _showComingSoonDialog(context, 'Privacy & Security');
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '$feature will be available in a future update.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: const Color(0xFF00FF88)),
            ),
          ),
        ],
      ),
    );
  }
}