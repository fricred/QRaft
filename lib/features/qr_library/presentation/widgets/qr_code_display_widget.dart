import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../qr_generator/domain/entities/qr_code_entity.dart';

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
        color: Color(qrEntity.customization.backgroundColor),
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

  Widget _buildQRCode() {
    try {
      return QrImageView(
        data: qrEntity.data,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Color(qrEntity.customization.backgroundColor),
        padding: const EdgeInsets.all(8),
        errorCorrectionLevel: _getErrorCorrectionLevel(qrEntity.customization.errorCorrectionLevel),
        embeddedImage: qrEntity.customization.hasLogo && qrEntity.customization.logoPath != null
            ? AssetImage(qrEntity.customization.logoPath!)
            : null,
        embeddedImageStyle: qrEntity.customization.hasLogo 
            ? QrEmbeddedImageStyle(
                size: Size(qrEntity.customization.logoSize, qrEntity.customization.logoSize),
              )
            : null,
        eyeStyle: QrEyeStyle(
          eyeShape: qrEntity.customization.eyeShape == 0 
              ? QrEyeShape.square 
              : QrEyeShape.circle,
          color: Color(qrEntity.customization.eyeColor),
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: qrEntity.customization.dataShape == 0 
              ? QrDataModuleShape.square 
              : QrDataModuleShape.circle,
          color: Color(qrEntity.customization.foregroundColor),
        ),
        errorStateBuilder: (context, error) {
          if (showFallbackIcon) {
            return _buildFallbackIcon();
          }
          return Container(
            width: size,
            height: size,
            color: const Color(0xFF1A1A1A),
            child: const Icon(
              Icons.error_rounded,
              color: Colors.red,
              size: 32,
            ),
          );
        },
      );
    } catch (e) {
      if (showFallbackIcon) {
        return _buildFallbackIcon();
      }
      return Container(
        width: size,
        height: size,
        color: const Color(0xFF1A1A1A),
        child: const Icon(
          Icons.error_rounded,
          color: Colors.red,
          size: 32,
        ),
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

  int _getErrorCorrectionLevel(int level) {
    switch (level) {
      case 0: return QrErrorCorrectLevel.L;
      case 1: return QrErrorCorrectLevel.M;
      case 2: return QrErrorCorrectLevel.Q;
      case 3: return QrErrorCorrectLevel.H;
      default: return QrErrorCorrectLevel.M;
    }
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
      case 'location': return Icons.location_on_rounded;
      case 'text': 
      default: return Icons.text_fields_rounded;
    }
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