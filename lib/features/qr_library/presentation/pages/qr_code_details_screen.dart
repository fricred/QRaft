import 'dart:math' show log;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../qr_generator/presentation/pages/url_qr_screen.dart';
import '../../../qr_generator/presentation/pages/text_qr_screen.dart';
import '../widgets/qr_code_display_widget.dart';
import '../providers/qr_library_providers.dart';

class QRCodeDetailsScreen extends ConsumerStatefulWidget {
  final QRCodeEntity qrEntity;

  const QRCodeDetailsScreen({
    super.key,
    required this.qrEntity,
  });

  @override
  ConsumerState<QRCodeDetailsScreen> createState() => _QRCodeDetailsScreenState();
}

class _QRCodeDetailsScreenState extends ConsumerState<QRCodeDetailsScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF2E2E2E),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.qrCodeDetails,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.qrEntity.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate()
              .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
              .slideY(begin: -0.15, duration: 300.ms, curve: Curves.easeOutQuart),
            
            // QR Code display and details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Large QR Code display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          QRCodeDisplayWidget(
                            qrEntity: widget.qrEntity,
                            size: 240,
                            showFallbackIcon: true,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.qrEntity.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getQRTypeColor(widget.qrEntity.type.identifier)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getQRTypeColor(widget.qrEntity.type.identifier)
                                    .withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.qrEntity.type.name.toUpperCase(),
                              style: TextStyle(
                                color: _getQRTypeColor(widget.qrEntity.type.identifier),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate()
                      .fadeIn(duration: 300.ms, delay: 100.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.15, duration: 300.ms, delay: 100.ms, curve: Curves.easeOutQuart)
                      .scale(begin: const Offset(0.95, 0.95), duration: 300.ms, delay: 100.ms),
                    
                    const SizedBox(height: 24),

                    // QR Content section - Exponential delay pattern
                    _buildInfoSection(
                      l10n.qrContent,
                      widget.qrEntity.displayData,
                      Icons.text_fields_rounded,
                      canCopy: true,
                      index: 0,
                    ),

                    const SizedBox(height: 16),

                    // Created date section
                    _buildInfoSection(
                      l10n.createdLabel,
                      _formatDateTime(widget.qrEntity.createdAt, l10n),
                      Icons.calendar_today_rounded,
                      index: 1,
                    ),

                    const SizedBox(height: 16),

                    // Last updated section
                    _buildInfoSection(
                      l10n.lastUpdatedLabel,
                      _formatDateTime(widget.qrEntity.updatedAt, l10n),
                      Icons.update_rounded,
                      index: 2,
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Action buttons - horizontal icon row
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    label: l10n.share,
                    onPressed: _handleShare,
                    delayMs: 250,
                  ),
                  _buildActionButton(
                    icon: Icons.copy_rounded,
                    label: l10n.copyData,
                    onPressed: _handleCopyData,
                    delayMs: 275,
                  ),
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    label: l10n.edit,
                    onPressed: _handleEdit,
                    delayMs: 300,
                  ),
                  _buildActionButton(
                    icon: Icons.delete_rounded,
                    label: l10n.delete,
                    onPressed: _isDeleting ? null : _handleDelete,
                    isDestructive: true,
                    isLoading: _isDeleting,
                    delayMs: 325,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isDestructive = false,
    bool isLoading = false,
    int delayMs = 0,
  }) {
    final iconColor = isDestructive
        ? const Color(0xFFEF4444)
        : Colors.white;
    final labelColor = isDestructive
        ? Colors.red[300]
        : Colors.grey[400];
    final borderColor = isDestructive
        ? Colors.red.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.12);

    // Extract repeated value for consistency
    const buttonRadius = BorderRadius.all(Radius.circular(16));

    // Determine if button is disabled (not loading, but no action)
    final isDisabled = onPressed == null && !isLoading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: label,
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: buttonRadius,
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: buttonRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E).withValues(alpha: 0.7),
                      borderRadius: buttonRadius,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onPressed,
                        borderRadius: buttonRadius,
                        child: Center(
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                                  ),
                                )
                              : Icon(icon, color: iconColor, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ).animate()
            .fadeIn(duration: 300.ms, delay: Duration(milliseconds: delayMs))
            .scale(
              begin: const Offset(0.9, 0.9),
              duration: 300.ms,
              delay: Duration(milliseconds: delayMs),
            ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ).animate()
            .fadeIn(duration: 200.ms, delay: Duration(milliseconds: delayMs + 100)),
      ],
    );
  }

  Widget _buildInfoSection(
    String title,
    String content,
    IconData icon,
    {bool canCopy = false, required int index}
  ) {
    // Exponential delay pattern with variation
    final delay = (100 + (40.0 * log(index + 2))).toInt();
    // Vary the timing slightly for polish: 280ms, 295ms, 310ms...
    final duration = 280 + (index * 15);
    // Alternate slide directions for visual interest
    final slideDirection = index.isEven ? -0.15 : 0.15;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF00FF88),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (canCopy) ...[
                const Spacer(),
                IconButton(
                  onPressed: () => _copyToClipboard(content),
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Colors.grey,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: duration.ms, delay: delay.ms, curve: Curves.easeOutCubic)
      .slideX(begin: slideDirection, duration: duration.ms, delay: delay.ms, curve: Curves.easeOutQuart)
      .scale(begin: const Offset(0.98, 0.98), duration: duration.ms, delay: delay.ms);
  }

  void _handleShare() {
    final l10n = AppLocalizations.of(context)!;
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.shareFunctionalityComingSoon),
        backgroundColor: const Color(0xFF2E2E2E),
      ),
    );
  }

  void _handleCopyData() {
    _copyToClipboard(widget.qrEntity.data);
  }

  void _copyToClipboard(String text) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copiedToClipboard),
        backgroundColor: const Color(0xFF00FF88),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleEdit() {
    final l10n = AppLocalizations.of(context)!;
    // Navigate to the appropriate QR screen based on type
    Widget screen;

    switch (widget.qrEntity.type.identifier) {
      case 'url':
        screen = URLQRScreen(editingQRCode: widget.qrEntity);
        break;
      case 'text':
        screen = TextQRScreen(editingQRCode: widget.qrEntity);
        break;
      case 'vcard':
        // Import PersonalInfoQRScreen when available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.editVCardComingSoon),
            backgroundColor: Colors.grey[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      case 'wifi':
        // Import WiFiQRScreen when available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.editWifiComingSoon),
            backgroundColor: Colors.grey[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      case 'email':
        // Import EmailQRScreen when available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.editEmailComingSoon),
            backgroundColor: Colors.grey[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      case 'location':
        // Import LocationQRScreen when available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.editLocationComingSoon),
            backgroundColor: Colors.grey[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.editTypeNotSupported(widget.qrEntity.type.identifier)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    ).then((updatedQR) {
      // Pop back to library when returning from edit
      if (mounted && updatedQR != null) {
        Navigator.of(context).pop(updatedQR);
      }
    });
  }

  void _handleDelete() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.deleteQRCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.deleteQRConfirmation(widget.qrEntity.name),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryGlassButton(
                        text: l10n.cancel,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GlassButton(
                        text: l10n.delete,
                        icon: Icons.delete_rounded,
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await _confirmDelete();
                        },
                        gradientColors: const [
                          Color(0xFFEF4444),
                          Color(0xFFDC2626),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isDeleting = true;
    });

    try {
      await ref.read(qrLibraryControllerProvider.notifier).deleteQRCode(widget.qrEntity.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.qrDeletedSuccess),
            backgroundColor: const Color(0xFF00FF88),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToDeleteQR(e.toString())),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return l10n.todayAt(_formatTime(dateTime));
    } else if (difference.inDays == 1) {
      return l10n.yesterdayAt(_formatTime(dateTime));
    } else if (difference.inDays < 7) {
      return l10n.daysAgoFormat(difference.inDays);
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
  }

  Color _getQRTypeColor(String qrType) {
    switch (qrType.toLowerCase()) {
      case 'url': return const Color(0xFF3B82F6);      // Bright Blue
      case 'wifi': return const Color(0xFF8B5CF6);     // Purple
      case 'email': return const Color(0xFFF59E0B);    // Amber
      case 'phone': return const Color(0xFF22D3EE);    // Cyan
      case 'sms': return const Color(0xFFEC4899);      // Pink
      case 'vcard':
      case 'personal_info':
        return const Color(0xFF00FF88);                // Neon Green
      case 'location':
      case 'geo':
        return const Color(0xFFF97316);                // Orange
      case 'text':
      default: return const Color(0xFF94A3B8);         // Slate
    }
  }
}