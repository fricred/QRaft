import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/widgets/glass_button.dart';

/// Captures the [RepaintBoundary] pointed to by [repaintKey], encodes the
/// rendered content as a 3x-resolution PNG, writes it to a temporary file,
/// and opens the OS share sheet via [Share.shareXFiles].
class QrShareButton extends StatefulWidget {
  final GlobalKey repaintKey;
  final String qrName;

  const QrShareButton({
    super.key,
    required this.repaintKey,
    required this.qrName,
  });

  @override
  State<QrShareButton> createState() => _QrShareButtonState();
}

class _QrShareButtonState extends State<QrShareButton> {
  bool _isSharing = false;

  Future<void> _shareQR() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      final context = widget.repaintKey.currentContext;
      if (context == null) {
        _showError('QR preview not ready. Please complete the form first.');
        return;
      }

      final boundary =
          context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showError('Unable to capture QR image.');
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showError('Failed to encode QR image.');
        return;
      }

      final sanitizedName = widget.qrName
          .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName =
          'qraft_${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.png';
      final tmpFile = File('${Directory.systemTemp.path}/$fileName');
      await tmpFile.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(tmpFile.path)],
        text: 'QR: ${widget.qrName}',
      );
    } catch (e) {
      _showError('Failed to share QR: $e');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'qr_share_button',
      button: true,
      label: 'Share QR',
      child: SecondaryGlassButton(
        text: 'Share QR',
        icon: Icons.share_rounded,
        isLoading: _isSharing,
        onPressed: _shareQR,
        width: double.infinity,
      ),
    );
  }
}
