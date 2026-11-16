import 'dart:typed_data';

import 'package:flutter_riverpod/legacy.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../qr_generator/domain/services/qr_decoration_builder.dart';
import '../../domain/entities/qr_ai_style_result.dart';
import '../../domain/services/qr_ai_style_service.dart';
import '../../domain/services/qr_animation_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Immutable state for the QR digital screens (animation + AI style).
class QrDigitalState {
  /// Whether a GIF export is currently in progress.
  final bool isExporting;

  /// Non-null after a failed export; null otherwise.
  final String? exportError;

  /// The exported GIF bytes, available after a successful [QrDigitalController.exportGif].
  final Uint8List? gifBytes;

  // ---------------------------------------------------------------------------
  // AI style fields (plan 06-03)
  // ---------------------------------------------------------------------------

  /// Whether an AI stylization request is in progress.
  final bool isStylizing;

  /// The AI stylization result; non-null after a successful [QrDigitalController.generateAiStyle].
  final QrAiStyleResult? aiStyleResult;

  /// Non-null after a failed AI stylization; null otherwise.
  /// Carries a [QrAiStyleException.code] string or raw error text.
  final String? aiStyleError;

  const QrDigitalState({
    this.isExporting = false,
    this.exportError,
    this.gifBytes,
    this.isStylizing = false,
    this.aiStyleResult,
    this.aiStyleError,
  });

  QrDigitalState copyWith({
    bool? isExporting,
    String? exportError,
    Uint8List? gifBytes,
    bool? isStylizing,
    QrAiStyleResult? aiStyleResult,
    String? aiStyleError,
    bool clearError = false,
    bool clearAiStyleError = false,
    bool clearAiStyleResult = false,
  }) {
    return QrDigitalState(
      isExporting: isExporting ?? this.isExporting,
      exportError: clearError ? null : (exportError ?? this.exportError),
      gifBytes: gifBytes ?? this.gifBytes,
      isStylizing: isStylizing ?? this.isStylizing,
      aiStyleResult: clearAiStyleResult
          ? null
          : (aiStyleResult ?? this.aiStyleResult),
      aiStyleError: clearAiStyleError
          ? null
          : (aiStyleError ?? this.aiStyleError),
    );
  }
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// StateNotifier that drives both the QR animation/GIF export flow
/// and the AI style flow.
///
/// Profile guard: [exportGif] and [generateAiStyle] both enforce that the QR
/// code's profile is digitalOnly (profile index == 1). The UI also disables
/// controls for non-digitalOnly profiles (double-layer enforcement, T-06-06
/// and T-06-11).
class QrDigitalController extends StateNotifier<QrDigitalState> {
  QrDigitalController(this._qrCode) : super(const QrDigitalState());

  final QRCodeEntity _qrCode;

  // ---------------------------------------------------------------------------
  // GIF export
  // ---------------------------------------------------------------------------

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
      await SharePlus.instance.share(ShareParams(files: [xFile]));

      state = state.copyWith(isExporting: false, gifBytes: gifBytes);
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        exportError: e.toString(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // AI style generation (plan 06-03)
  // ---------------------------------------------------------------------------

  /// Calls the Supabase Edge Function proxy to generate an AI-stylized QR code,
  /// then runs the scannability gate via [MobileScannerController.analyzeImage].
  ///
  /// [prompt] — user-supplied style description (truncated to 200 chars in service).
  /// [client] — injected [SupabaseClient] (from [supabaseClientProvider]).
  /// [qrStorageUrl] — Public Supabase Storage URL of the base QR PNG to stylize.
  ///
  /// On success: sets [QrDigitalState.aiStyleResult].
  /// On error: sets [QrDigitalState.aiStyleError] to the [QrAiStyleException.code]
  /// or the raw error string.
  /// Always resets [QrDigitalState.isStylizing] to false in `finally`.
  Future<void> generateAiStyle(
    String prompt,
    SupabaseClient client,
    String qrStorageUrl,
  ) async {
    state = state.copyWith(
      isStylizing: true,
      clearAiStyleError: true,
      clearAiStyleResult: true,
    );

    try {
      final service = QrAiStyleService(supabaseClient: client);
      final result = await service.stylize(
        qrStorageUrl: qrStorageUrl,
        prompt: prompt,
        userId: client.auth.currentUser?.id ?? '',
        profile: _qrCode.customization.profile,
      );
      state = state.copyWith(isStylizing: false, aiStyleResult: result);
    } on QrAiStyleException catch (e) {
      state = state.copyWith(isStylizing: false, aiStyleError: e.code);
    } catch (e) {
      state = state.copyWith(isStylizing: false, aiStyleError: e.toString());
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Auto-dispose family provider — scoped to a [QRCodeEntity].
///
/// Disposed automatically when the page is removed from the tree.
final qrDigitalControllerProvider = StateNotifierProvider.autoDispose
    .family<QrDigitalController, QrDigitalState, QRCodeEntity>(
  (ref, qrCode) => QrDigitalController(qrCode),
);
