import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../qr_generator/domain/services/qr_decoration_builder.dart';
import '../../domain/services/qr_animation_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Immutable state for the QR digital animation screen.
class QrDigitalState {
  /// Whether a GIF export is currently in progress.
  final bool isExporting;

  /// Non-null after a failed export; null otherwise.
  final String? exportError;

  /// The exported GIF bytes, available after a successful [QrDigitalController.exportGif].
  final Uint8List? gifBytes;

  const QrDigitalState({
    this.isExporting = false,
    this.exportError,
    this.gifBytes,
  });

  QrDigitalState copyWith({
    bool? isExporting,
    String? exportError,
    Uint8List? gifBytes,
    bool clearError = false,
  }) {
    return QrDigitalState(
      isExporting: isExporting ?? this.isExporting,
      exportError: clearError ? null : (exportError ?? this.exportError),
      gifBytes: gifBytes ?? this.gifBytes,
    );
  }
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// StateNotifier that drives the QR animation / GIF export flow.
///
/// Profile guard: [exportGif] throws [StateError] if the QR code's profile
/// is not digitalOnly (profile index == 1). The UI also disables the export
/// button for non-digitalOnly profiles (double-layer enforcement, T-06-06).
class QrDigitalController extends StateNotifier<QrDigitalState> {
  QrDigitalController(this._qrCode) : super(const QrDigitalState());

  final QRCodeEntity _qrCode;

  /// Renders 12 animation frames and encodes them as an animated GIF in a
  /// compute() isolate, then shares the result via the system share sheet.
  ///
  /// Throws [StateError] if [_qrCode.customization.profile] is not 1
  /// (digitalOnly). Callers should check the profile before calling; the UI
  /// also prevents the call via a disabled button guard.
  ///
  /// Sets [QrDigitalState.isExporting] to true for the duration, and always
  /// resets it to false in `finally`.
  Future<void> exportGif() async {
    // T-06-06: Profile guard — reject non-digitalOnly QR codes.
    if (_qrCode.customization.profile != 1) {
      throw StateError(
        'Animated GIF is only available for digital-only QRs',
      );
    }

    state = state.copyWith(isExporting: true, clearError: true);

    try {
      final decoration =
          QrDecorationBuilder.buildDecoration(_qrCode.customization);
      final qrImage =
          QrDecorationBuilder.buildQrImage(_qrCode.data, _qrCode.customization);

      final frames = await QrAnimationService.captureFrames(
        qrImage,
        decoration,
        frameCount: 12,
        size: 400,
      );

      final gifBytes = await QrAnimationService.buildGif(frames);

      // Share via the system share sheet.
      final xFile = XFile.fromData(
        gifBytes,
        name: 'qraft_qr.gif',
        mimeType: 'image/gif',
      );
      await Share.shareXFiles([xFile]);

      state = state.copyWith(isExporting: false, gifBytes: gifBytes);
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        exportError: e.toString(),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Auto-dispose family provider — scoped to a [QRCodeEntity].
///
/// Disposed automatically when the [QrAnimatePage] is removed from the tree.
final qrDigitalControllerProvider = StateNotifierProvider.autoDispose
    .family<QrDigitalController, QrDigitalState, QRCodeEntity>(
  (ref, qrCode) => QrDigitalController(qrCode),
);
