import 'dart:math' show log;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../../../shared/widgets/glass_button.dart';
import '../providers/qr_scanner_provider.dart';
import '../models/scan_result.dart';
import 'scan_result_dialog.dart';
import '../../subscription/presentation/providers/subscription_providers.dart';
import '../../subscription/presentation/widgets/upgrade_bottom_sheet.dart';

class ScanHistoryScreen extends ConsumerWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scanHistory = ref.watch(limitedScanHistoryProvider);
    final hasHiddenItems = ref.watch(hasHiddenScanHistoryProvider);
    final hiddenCount = ref.watch(hiddenScanHistoryCountProvider);
    final isLoading = ref.watch(scannerLoadingProvider);
    final error = ref.watch(scannerErrorProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: Text(
          l10n.scanHistory,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (scanHistory.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
              color: const Color(0xFF2E2E2E),
              onSelected: (value) {
                if (value == 'clear_all') {
                  _showClearAllDialog(context, ref, l10n);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all_rounded, color: Colors.red[400]),
                      const SizedBox(width: 12),
                      Text(
                        l10n.clearAll,
                        style: TextStyle(color: Colors.red[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(qrScannerProvider.notifier).refreshHistory();
        },
        color: const Color(0xFF00FF88),
        backgroundColor: const Color(0xFF2E2E2E),
        child: _buildBody(context, ref, scanHistory, isLoading, error, l10n, hasHiddenItems, hiddenCount),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<ScanResult> scanHistory,
    bool isLoading,
    String? error,
    AppLocalizations l10n,
    bool hasHiddenItems,
    int hiddenCount,
  ) {
    if (isLoading && scanHistory.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading History',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SecondaryGlassButton(
              text: l10n.retry,
              icon: Icons.refresh_rounded,
              onPressed: () {
                ref.read(qrScannerProvider.notifier).refreshHistory();
              },
            ),
          ],
        ),
      );
    }

    if (scanHistory.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    // Add 1 to itemCount if there are hidden items to show upgrade message
    final itemCount = hasHiddenItems ? scanHistory.length + 1 : scanHistory.length;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Show upgrade message as last item
        if (hasHiddenItems && index == scanHistory.length) {
          return _buildUpgradeMessage(context, hiddenCount, l10n);
        }

        final scanResult = scanHistory[index];
        final delay = (50 + (30.0 * log(index + 2))).toInt();
        return _buildHistoryItem(context, ref, scanResult, index)
            .animate(delay: delay.ms)
            .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
            .slideX(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOutQuart);
      },
    );
  }

  Widget _buildUpgradeMessage(BuildContext context, int hiddenCount, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => UpgradeBottomSheet.show(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD700).withValues(alpha: 0.15),
              const Color(0xFFF59E0B).withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Lock icon with gold gradient
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.hiddenScansTitle(hiddenCount),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.upgradeToSeeAll,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFFFFD700).withValues(alpha: 0.7),
              size: 28,
            ),
          ],
        ),
      ),
    ).animate(delay: 400.ms)
      .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
      .slideY(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOutQuart);
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Illustration - Standardized animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 60,
            ),
          ).animate()
            .scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 32),

          // Title - Standardized animation (200ms delay after icon)
          Text(
            l10n.noScansYet,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.15, duration: 400.ms, delay: 200.ms, curve: Curves.easeOutQuart),

          const SizedBox(height: 12),

          // Subtitle - Standardized animation (300ms delay)
          Text(
            l10n.startScanningToSeeHistory,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ).animate()
            .fadeIn(duration: 300.ms, delay: 300.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.1, duration: 300.ms, delay: 300.ms, curve: Curves.easeOutQuart),

          const SizedBox(height: 32),

          // Action Button - Standardized animation (400ms delay)
          PrimaryGlassButton(
            text: l10n.startScanning,
            icon: Icons.qr_code_scanner_rounded,
            onPressed: () => Navigator.pop(context),
          ).animate()
            .fadeIn(duration: 300.ms, delay: 400.ms, curve: Curves.easeOutCubic)
            .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, delay: 400.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    WidgetRef ref,
    ScanResult scanResult,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showScanResultDialog(context, scanResult),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Type icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTypeColor(scanResult.type).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getTypeColor(scanResult.type).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getTypeIcon(scanResult.type),
                    color: _getTypeColor(scanResult.type),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scanResult.displayValue,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(scanResult.type).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTypeDisplayName(scanResult.type),
                              style: TextStyle(
                                color: _getTypeColor(scanResult.type),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(scanResult.scannedAt),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
                  color: const Color(0xFF2E2E2E),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteScanResult(ref, scanResult.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, color: Colors.red[400]),
                          const SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.red[400]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(QRCodeType type) {
    switch (type) {
      case QRCodeType.url:
        return Icons.link_rounded;
      case QRCodeType.wifi:
        return Icons.wifi_rounded;
      case QRCodeType.email:
        return Icons.email_rounded;
      case QRCodeType.phone:
        return Icons.phone_rounded;
      case QRCodeType.sms:
        return Icons.message_rounded;
      case QRCodeType.vcard:
        return Icons.contact_page_rounded;
      case QRCodeType.location:
        return Icons.location_on_rounded;
      default:
        return Icons.text_fields_rounded;
    }
  }

  Color _getTypeColor(QRCodeType type) {
    switch (type) {
      case QRCodeType.url:
        return const Color(0xFF1A73E8);
      case QRCodeType.wifi:
        return const Color(0xFF00FF88);
      case QRCodeType.email:
        return Colors.orange;
      case QRCodeType.phone:
        return Colors.green;
      case QRCodeType.sms:
        return Colors.blue;
      case QRCodeType.vcard:
        return Colors.purple;
      case QRCodeType.location:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTypeDisplayName(QRCodeType type) {
    switch (type) {
      case QRCodeType.url:
        return 'URL';
      case QRCodeType.wifi:
        return 'WiFi';
      case QRCodeType.email:
        return 'Email';
      case QRCodeType.phone:
        return 'Phone';
      case QRCodeType.sms:
        return 'SMS';
      case QRCodeType.vcard:
        return 'Contact';
      case QRCodeType.location:
        return 'Location';
      default:
        return 'Text';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scanDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (scanDate == today) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (scanDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showScanResultDialog(BuildContext context, ScanResult scanResult) {
    showDialog(
      context: context,
      builder: (context) => ScanResultDialog(scanResult: scanResult),
    );
  }

  void _deleteScanResult(WidgetRef ref, String scanId) {
    ref.read(qrScannerProvider.notifier).deleteScanResult(scanId);
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange[400]),
            const SizedBox(width: 8),
            Text(
              l10n.clearAllHistory,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          l10n.clearAllHistoryConfirm,
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
          TextButton(
            onPressed: () {
              ref.read(qrScannerProvider.notifier).clearAllHistory();
              Navigator.pop(context);
            },
            child: Text(
              l10n.clearAll,
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
  }
}