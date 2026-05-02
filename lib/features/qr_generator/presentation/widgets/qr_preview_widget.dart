import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../domain/entities/qr_code_entity.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/services/qr_decoration_builder.dart';

/// A widget that renders a live QR code preview using [PrettyQrView].
///
/// [QrImage] is created in [initState] / [didUpdateWidget] — never in [build] —
/// to avoid regenerating the QR on every frame repaint.
///
/// TODO(05-03): Add 500 ms debounce in didUpdateWidget to avoid thrashing
/// QrImage on rapid user input (typing in text fields, slider drags).
class QRPreviewWidget extends ConsumerStatefulWidget {
  final QRType qrType;
  final String? qrData;

  /// Full customization state. Replaces the legacy color params for rendering.
  final QRCustomization customization;

  /// Kept for API compatibility — ignored in rendering (Phase 5 wires
  /// color customization through [customization] instead).
  @Deprecated('Use customization field instead')
  final Color? foregroundColor;

  /// Kept for API compatibility — IGNORED, always white per dark-on-light
  /// constraint (T-02-04 mitigation). Use [customization.backgroundColor] if
  /// programmatic control is ever needed.
  @Deprecated('Use customization field instead')
  final Color? backgroundColor;

  final double size;

  /// GlobalKey for [RepaintBoundary] — enables PNG export in Plan 05.
  final GlobalKey? repaintKey;

  const QRPreviewWidget({
    super.key,
    required this.qrType,
    this.qrData,
    this.customization = const QRCustomization(),
    // ignore: deprecated_member_use_from_same_package
    this.foregroundColor,
    // ignore: deprecated_member_use_from_same_package
    this.backgroundColor,
    this.size = 200.0,
    this.repaintKey,
  });

  @override
  ConsumerState<QRPreviewWidget> createState() => _QRPreviewWidgetState();
}

class _QRPreviewWidgetState extends ConsumerState<QRPreviewWidget> {
  QrImage? _qrImage;

  @override
  void initState() {
    super.initState();
    _buildQrImage();
  }

  @override
  void didUpdateWidget(QRPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customization != oldWidget.customization ||
        widget.qrData != oldWidget.qrData) {
      _buildQrImage();
    }
  }

  void _buildQrImage() {
    final data = _previewData;
    setState(() {
      _qrImage =
          QrDecorationBuilder.buildQrImage(data, widget.customization);
    });
  }

  String get _previewData => widget.qrData ?? _getSampleData(widget.qrType);

  @override
  Widget build(BuildContext context) {
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
          // QR Code with optional RepaintBoundary for Plan 05 PNG export
          _buildQrContainer(),

          const SizedBox(height: 16),

          // QR type badge
          _TypeBadge(qrType: widget.qrType),

          const SizedBox(height: 12),

          // Preview text
          Text(
            _getPreviewText(widget.qrType, _previewData),
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQrContainer() {
    final qrContainer = Container(
      width: widget.size,
      height: widget.size,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildQrView(),
    );

    if (widget.repaintKey != null) {
      return RepaintBoundary(key: widget.repaintKey, child: qrContainer);
    }
    return qrContainer;
  }

  Widget _buildQrView() {
    // Null guard while QrImage is being built (should only be one frame)
    if (_qrImage == null) {
      return Container(color: Colors.grey[200]);
    }
    return PrettyQrView(
      qrImage: _qrImage!,
      decoration:
          QrDecorationBuilder.buildDecoration(widget.customization),
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
      case QRType.event:
        return 'BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VEVENT\nSUMMARY:Sample Event\nDTSTART:20260501T100000\nEND:VEVENT\nEND:VCALENDAR';
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
      case QRType.event:
        return 'Calendar event (iCal format)';
    }
  }
}

/// Private badge widget showing QR type with gradient chip + icon
class _TypeBadge extends StatelessWidget {
  final QRType qrType;

  const _TypeBadge({required this.qrType});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            qrType.getDisplayName(context),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
      case 'event_rounded':
        return Icons.event_rounded;
      default:
        return Icons.qr_code_rounded;
    }
  }
}
