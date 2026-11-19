import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../qr_generator/domain/services/qr_decoration_builder.dart';

class QRCodeDisplayWidget extends StatelessWidget {
  final QRCodeEntity qrEntity;
  final double size;
  final bool showFallbackIcon;

  const QRCodeDisplayWidget({
    super.key,
    required this.qrEntity,
    this.size = 80,
    this.showFallbackIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getQRTypeColor(qrEntity.type.identifier).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: _buildQRCode(),
      ),
    );
  }

  /// Same renderer as the editor, templates and widget (QrDecorationBuilder): gradient,
  /// module/eye presets and logo, on the white background every QRaft code uses.
  Widget _buildQRCode() {
    try {
      final c = qrEntity.customization;
      return Padding(
        padding: EdgeInsets.all(size * 0.04),
        child: PrettyQrView(
          qrImage: QrDecorationBuilder.buildQrImage(qrEntity.data, c),
          decoration: QrDecorationBuilder.buildDecoration(c),
        ),
      );
    } catch (_) {
      if (showFallbackIcon) return _buildFallbackIcon();
      return Container(
        width: size,
        height: size,
        color: const Color(0xFF1A1A1A),
        child: const Icon(Icons.error_rounded, color: Colors.red, size: 32),
      );
    }
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF1A1A1A),
      child: Icon(
        _getQRTypeIcon(qrEntity.type.identifier),
        color: _getQRTypeColor(qrEntity.type.identifier),
        size: 32,
      ),
    );
  }

  IconData _getQRTypeIcon(String qrType) {
    switch (qrType.toLowerCase()) {
      case 'url': return Icons.link_rounded;
      case 'wifi': return Icons.wifi_rounded;
      case 'email': return Icons.email_rounded;
      case 'phone': return Icons.phone_rounded;
      case 'sms': return Icons.sms_rounded;
      case 'vcard':
      case 'personal_info':
        return Icons.person_rounded;
      case 'location':
      case 'geo':
        return Icons.location_on_rounded;
      case 'text':
      default: return Icons.text_fields_rounded;
    }
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