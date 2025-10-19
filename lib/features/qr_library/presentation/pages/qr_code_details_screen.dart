import 'dart:math' show log;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../qr_generator/domain/entities/qr_code_entity.dart';
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
                          'QR Code Details',
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
                      'QR Content',
                      widget.qrEntity.displayData,
                      Icons.text_fields_rounded,
                      canCopy: true,
                      index: 0,
                    ),

                    const SizedBox(height: 16),

                    // Created date section
                    _buildInfoSection(
                      'Created',
                      _formatDateTime(widget.qrEntity.createdAt),
                      Icons.calendar_today_rounded,
                      index: 1,
                    ),

                    const SizedBox(height: 16),

                    // Last updated section
                    _buildInfoSection(
                      'Last Updated',
                      _formatDateTime(widget.qrEntity.updatedAt),
                      Icons.update_rounded,
                      index: 2,
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Primary actions row
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryGlassButton(
                          text: 'Share',
                          icon: Icons.share_rounded,
                          onPressed: _handleShare,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PrimaryGlassButton(
                          text: 'Copy Data',
                          icon: Icons.copy_rounded,
                          onPressed: _handleCopyData,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Secondary actions row
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryGlassButton(
                          text: 'Edit',
                          icon: Icons.edit_rounded,
                          onPressed: _handleEdit,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassButton(
                          text: _isDeleting ? 'Deleting...' : 'Delete',
                          icon: _isDeleting ? null : Icons.delete_rounded,
                          onPressed: _isDeleting ? null : _handleDelete,
                          gradientColors: const [
                            Color(0xFFEF4444),
                            Color(0xFFDC2626),
                          ],
                          isLoading: _isDeleting,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate()
              .fadeIn(duration: 300.ms, delay: 300.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.15, duration: 300.ms, delay: 300.ms, curve: Curves.easeOutQuart),
          ],
        ),
      ),
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
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality will be implemented soon'),
        backgroundColor: Color(0xFF2E2E2E),
      ),
    );
  }

  void _handleCopyData() {
    _copyToClipboard(widget.qrEntity.data);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        backgroundColor: const Color(0xFF00FF88),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleEdit() {
    // TODO: Navigate to QR generator with editing mode
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality will be implemented soon'),
        backgroundColor: Color(0xFF2E2E2E),
      ),
    );
  }

  void _handleDelete() {
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
                const Text(
                  'Delete QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "${widget.qrEntity.name}"? This action cannot be undone.',
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
                        text: 'Cancel',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GlassButton(
                        text: 'Delete',
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
    setState(() {
      _isDeleting = true;
    });

    try {
      await ref.read(qrLibraryControllerProvider.notifier).deleteQRCode(widget.qrEntity.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('QR code deleted successfully'),
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
            content: Text('Failed to delete QR code: $e'),
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
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
      case 'url': return const Color(0xFF1A73E8);
      case 'wifi': return const Color(0xFF8B5CF6);
      case 'email': return const Color(0xFFF59E0B);
      case 'phone': return const Color(0xFF10B981);
      case 'sms': return const Color(0xFFEF4444);
      case 'vcard':
      case 'personal_info':
        return const Color(0xFF00FF88);
      case 'location': return const Color(0xFF10B981);
      case 'text': 
      default: return const Color(0xFF6366F1);
    }
  }
}