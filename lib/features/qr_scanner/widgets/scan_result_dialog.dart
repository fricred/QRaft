import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../../../shared/widgets/glass_button.dart';
import '../models/scan_result.dart';

class ScanResultDialog extends StatelessWidget {
  final ScanResult scanResult;

  const ScanResultDialog({
    super.key,
    required this.scanResult,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon and header
            _buildHeader(),
            
            const SizedBox(height: 16),
            
            // QR type badge
            _buildTypeBadge(),
            
            const SizedBox(height: 16),
            
            // Content display
            _buildContent(),
            
            const SizedBox(height: 24),
            
            // Actions
            _buildActions(context, l10n),
          ],
        ),
      ).animate()
        .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 200.ms),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            _getTypeIcon(),
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'QR Code Scanned!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTypeColor().withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTypeIcon(),
            color: _getTypeColor(),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _getTypeDisplayName(),
            style: TextStyle(
              color: _getTypeColor(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content:',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scanResult.displayValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Show parsed data for structured types
          if (scanResult.parsedData != null && scanResult.parsedData!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildParsedData(),
          ],
        ],
      ),
    );
  }

  Widget _buildParsedData() {
    final parsedData = scanResult.parsedData!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details:',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in parsedData.entries)
          if (entry.value != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_capitalizeFirst(entry.key)}: ',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        // Copy button
        Expanded(
          child: SecondaryGlassButton(
            text: l10n.copy,
            icon: Icons.copy_rounded,
            onPressed: () => _copyToClipboard(context),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Action button (open/share)
        Expanded(
          child: PrimaryGlassButton(
            text: _getActionButtonText(),
            icon: _getActionButtonIcon(),
            onPressed: () => _performAction(context),
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon() {
    switch (scanResult.type) {
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

  Color _getTypeColor() {
    switch (scanResult.type) {
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

  String _getTypeDisplayName() {
    switch (scanResult.type) {
      case QRCodeType.url:
        return 'Website URL';
      case QRCodeType.wifi:
        return 'WiFi Network';
      case QRCodeType.email:
        return 'Email Address';
      case QRCodeType.phone:
        return 'Phone Number';
      case QRCodeType.sms:
        return 'SMS Message';
      case QRCodeType.vcard:
        return 'Contact Card';
      case QRCodeType.location:
        return 'Location';
      default:
        return 'Text';
    }
  }

  String _getActionButtonText() {
    switch (scanResult.type) {
      case QRCodeType.url:
        return 'Open';
      case QRCodeType.wifi:
        return 'Connect';
      case QRCodeType.email:
        return 'Email';
      case QRCodeType.phone:
        return 'Call';
      case QRCodeType.sms:
        return 'Message';
      case QRCodeType.location:
        return 'Open Map';
      default:
        return 'Share';
    }
  }

  IconData _getActionButtonIcon() {
    switch (scanResult.type) {
      case QRCodeType.url:
        return Icons.open_in_new_rounded;
      case QRCodeType.wifi:
        return Icons.wifi_rounded;
      case QRCodeType.email:
        return Icons.email_rounded;
      case QRCodeType.phone:
        return Icons.call_rounded;
      case QRCodeType.sms:
        return Icons.message_rounded;
      case QRCodeType.location:
        return Icons.map_rounded;
      default:
        return Icons.share_rounded;
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: scanResult.rawValue));
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        backgroundColor: const Color(0xFF00FF88),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _performAction(BuildContext context) async {
    try {
      switch (scanResult.type) {
        case QRCodeType.url:
          final rawUrl = scanResult.rawValue;
          final formattedUrl = rawUrl.startsWith('http') 
              ? rawUrl 
              : 'https://$rawUrl';
          
          debugPrint('🌐 URL Action Debug:');
          debugPrint('   Raw URL: $rawUrl');
          debugPrint('   Formatted URL: $formattedUrl');
          
          final uri = Uri.parse(formattedUrl);
          debugPrint('   Parsed URI: $uri');
          debugPrint('   URI scheme: ${uri.scheme}');
          debugPrint('   URI host: ${uri.host}');
          
          final canLaunch = await canLaunchUrl(uri);
          debugPrint('   Can launch: $canLaunch');
          
          if (canLaunch) {
            debugPrint('   Attempting to launch URL...');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            debugPrint('   ✅ URL launched successfully');
          } else {
            debugPrint('   ⚠️ canLaunchUrl returned false, trying anyway...');
            try {
              // Sometimes canLaunchUrl is overly restrictive, so try anyway
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              debugPrint('   ✅ URL launched successfully (despite canLaunchUrl = false)');
            } catch (launchError) {
              debugPrint('   ❌ Failed to launch URL: $launchError');
              throw Exception('Cannot launch URL: $formattedUrl. Error: $launchError');
            }
          }
          break;
          
        case QRCodeType.email:
          final email = scanResult.parsedData?['email'] ?? scanResult.rawValue;
          final uri = Uri.parse('mailto:$email');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
          break;
          
        case QRCodeType.phone:
          final phone = scanResult.parsedData?['number'] ?? scanResult.rawValue;
          final uri = Uri.parse('tel:$phone');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
          break;
          
        case QRCodeType.sms:
          final phone = scanResult.parsedData?['number'] ?? '';
          final body = scanResult.parsedData?['body'] ?? '';
          final uri = Uri.parse('sms:$phone${body.isNotEmpty ? '?body=$body' : ''}');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
          break;
          
        case QRCodeType.location:
          final lat = scanResult.parsedData?['latitude'];
          final lng = scanResult.parsedData?['longitude'];
          if (lat != null && lng != null) {
            final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
          break;
          
        default:
          await Share.share(scanResult.rawValue);
          break;
      }
      
      HapticFeedback.mediumImpact();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error performing action: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('❌ QR Type: ${scanResult.type}');
      debugPrint('❌ Raw Value: ${scanResult.rawValue}');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to perform action: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Copy URL',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: scanResult.rawValue));
              },
            ),
          ),
        );
      }
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).replaceAll('_', ' ');
  }
}