import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../qr_generator/domain/services/qr_decoration_builder.dart';
import '../../domain/services/qr_widget_service.dart';

/// Page that shows a QR preview and lets the user pin it to the home screen.
///
/// Provides platform-specific instructions (iOS vs Android) and a neon
/// "Pin to Home Screen" button that calls [QrWidgetService.pinQrToWidget].
///
/// On success shows a [SnackBar] with instructions to add the widget.
/// On error shows a [SnackBar] with the error message.
class QrWidgetPinPage extends ConsumerStatefulWidget {
  /// The entity whose QR will be pinned to the home-screen widget.
  final QRCodeEntity entity;

  const QrWidgetPinPage({super.key, required this.entity});

  @override
  ConsumerState<QrWidgetPinPage> createState() => _QrWidgetPinPageState();
}

class _QrWidgetPinPageState extends ConsumerState<QrWidgetPinPage> {
  bool _isPinning = false;

  // ---------------------------------------------------------------------------
  // Pin action
  // ---------------------------------------------------------------------------

  Future<void> _pinToWidget() async {
    if (_isPinning) return;
    setState(() => _isPinning = true);

    try {
      await QrWidgetService.pinQrToWidget(widget.entity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Widget updated! Add the QRaft widget to see your QR.',
            ),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pin QR: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPinning = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pin to Home Screen',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _QrPreviewCard(entity: widget.entity),
            const SizedBox(height: 20),
            _InstructionCard(isIOS: Platform.isIOS),
            const SizedBox(height: 28),
            _PinButton(isPinning: _isPinning, onTap: _pinToWidget),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Widget updates each time you tap Pin.\nTapping the widget opens QRaft.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// QR preview card
// ---------------------------------------------------------------------------

class _QrPreviewCard extends StatelessWidget {
  final QRCodeEntity entity;

  const _QrPreviewCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final decoration = QrDecorationBuilder.buildDecoration(entity.customization);
    final qrImage = QrDecorationBuilder.buildQrImage(
      entity.data,
      entity.customization,
    );

    final label = entity.data.length > 40
        ? '${entity.data.substring(0, 40)}…'
        : entity.data;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: PrettyQrView(qrImage: qrImage, decoration: decoration),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Platform instruction card
// ---------------------------------------------------------------------------

class _InstructionCard extends StatelessWidget {
  final bool isIOS;

  const _InstructionCard({required this.isIOS});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isIOS ? Icons.phone_iphone : Icons.phone_android,
                    color: const Color(0xFF00FF88),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isIOS ? 'iOS Instructions' : 'Android Instructions',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isIOS) ...[
                _InstructionStep(
                  number: '1',
                  text: 'Tap "Pin to Home Screen" below.',
                ),
                _InstructionStep(
                  number: '2',
                  text: 'Press the home button to go to your home screen.',
                ),
                _InstructionStep(
                  number: '3',
                  text:
                      'Long-press → tap "+" → search "QRaft" → add the widget.',
                ),
              ] else ...[
                _InstructionStep(
                  number: '1',
                  text: 'Tap "Pin to Home Screen" below.',
                ),
                _InstructionStep(
                  number: '2',
                  text: 'Long-press your home screen.',
                ),
                _InstructionStep(
                  number: '3',
                  text: 'Tap "Widgets" → find "QRaft" → drag onto your home screen.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00FF88).withValues(alpha: 0.6),
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pin button
// ---------------------------------------------------------------------------

class _PinButton extends StatelessWidget {
  final bool isPinning;
  final VoidCallback onTap;

  const _PinButton({required this.isPinning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'widget_pin_button',
      button: true,
      label: 'Pin to Home Screen',
      child: GestureDetector(
        onTap: isPinning ? null : onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00FF88), Color(0xFF00CC6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF88).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isPinning
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1A1A1A),
                      ),
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home_outlined,
                        color: Color(0xFF1A1A1A),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Pin to Home Screen',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
