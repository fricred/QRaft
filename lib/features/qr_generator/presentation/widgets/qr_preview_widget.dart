import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../domain/entities/qr_type.dart';

class QRPreviewWidget extends StatelessWidget {
  final QRType qrType;
  final String? qrData;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final double size;

  const QRPreviewWidget({
    super.key,
    required this.qrType,
    this.qrData,
    this.foregroundColor,
    this.backgroundColor,
    this.size = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    // Sample data for preview if no actual data provided
    final previewData = qrData ?? _getSampleData(qrType);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: previewData,
              version: QrVersions.auto,
              size: size,
              backgroundColor: backgroundColor ?? Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: foregroundColor ?? Colors.black,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: foregroundColor ?? Colors.black,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // QR Type indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: qrType.gradientColors.map((c) => Color(c)).toList(),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconData(qrType.iconName),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  qrType.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Preview text
          Text(
            _getPreviewText(qrType, previewData),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getSampleData(QRType qrType) {
    switch (qrType) {
      case QRType.personalInfo:
        return 'BEGIN:VCARD\nVERSION:3.0\nFN:John Doe\nORG:Company\nEMAIL:john@example.com\nEND:VCARD';
      case QRType.url:
        return 'https://example.com';
      case QRType.wifi:
        return 'WIFI:T:WPA;S:MyNetwork;P:password123;H:false;;';
      case QRType.text:
        return 'This is a sample text message for QR code preview.';
      case QRType.email:
        return 'mailto:example@email.com?subject=Hello&body=Sample message';
      case QRType.location:
        return 'geo:37.7749,-122.4194?q=37.7749,-122.4194(Sample Location)';
    }
  }

  String _getPreviewText(QRType qrType, String data) {
    switch (qrType) {
      case QRType.personalInfo:
        return 'Contact information in vCard format';
      case QRType.url:
        return data.replaceAll('https://', '').replaceAll('http://', '');
      case QRType.wifi:
        return 'WiFi network credentials';
      case QRType.text:
        return data.length > 50 ? '${data.substring(0, 50)}...' : data;
      case QRType.email:
        return 'Email with pre-filled content';
      case QRType.location:
        return 'GPS coordinates and location';
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person_rounded':
        return Icons.person_rounded;
      case 'link_rounded':
        return Icons.link_rounded;
      case 'wifi_rounded':
        return Icons.wifi_rounded;
      case 'text_fields_rounded':
        return Icons.text_fields_rounded;
      case 'email_rounded':
        return Icons.email_rounded;
      case 'location_on_rounded':
        return Icons.location_on_rounded;
      default:
        return Icons.qr_code_rounded;
    }
  }
}