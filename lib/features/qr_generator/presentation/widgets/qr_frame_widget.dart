import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

/// A CTA (Call-to-Action) frame widget that wraps a [PrettyQrView] inside a
/// bordered container with a text label below the QR code.
///
/// ## Quiet Zone Contract
/// [decoration] MUST be built with [PrettyQrQuietZone.standard] (4 modules)
/// — always pass a decoration produced by [QrDecorationBuilder.buildDecoration],
/// which enforces this. [QrFrameWidget] does NOT accept or modify the
/// [quietZone] field — it never calls `decoration.copyWith(quietZone: ...)`.
/// The 8 px container padding is OUTSIDE the QR bounds and does not substitute
/// for ISO 18004 §7.3.1 quiet zone.
///
/// ## Layout (Pattern 7 from 05-RESEARCH.md)
/// ```
/// ┌─────────────────────────────────┐
/// │  ┌ ─ ─ border ─ ─ ─ ─ ─ ─ ─ ┐ │  ← 8px container padding
/// │  │  ┌───────────────────────┐ │ │
/// │  │  │                       │ │ │
/// │  │  │     PrettyQrView      │ │ │  ← qrSize × qrSize
/// │  │  │  (quiet zone inside)  │ │ │
/// │  │  └───────────────────────┘ │ │
/// │  │           CTA Text          │ │
/// │  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ │
/// └─────────────────────────────────┘
/// ```
///
/// Maestro key: `qr_frame_widget` (set via [Semantics.identifier]).
class QrFrameWidget extends StatelessWidget {
  /// The QR image to render. Should be built via
  /// [QrDecorationBuilder.buildQrImage].
  final QrImage qrImage;

  /// The decoration to apply to [PrettyQrView].
  ///
  /// MUST have [quietZone] == [PrettyQrQuietZone.standard]. Never pass a
  /// decoration with [PrettyQrQuietZone.zero] here — that would violate ISO
  /// 18004 §7.3.1 and risk unreadable codes (T-05-04-04).
  final PrettyQrDecoration decoration;

  /// The CTA text displayed below the QR code, outside the quiet zone.
  ///
  /// Rendered as a plain [Text] widget — no HTML/web context, no injection
  /// surface (T-05-04-03 accepted).
  final String ctaText;

  /// The size (width == height) of the [PrettyQrView] in logical pixels.
  final double qrSize;

  const QrFrameWidget({
    super.key,
    required this.qrImage,
    required this.decoration,
    required this.ctaText,
    this.qrSize = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'qr_frame_widget',
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        // 8px padding is OUTSIDE the QR quiet zone — adds visual margin
        // between the frame border and the QR code area.
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: qrSize,
              height: qrSize,
              child: PrettyQrView(
                qrImage: qrImage,
                // decoration is passed through unchanged — quietZone is
                // never overridden here (T-05-04-04 mitigated).
                decoration: decoration,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ctaText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
