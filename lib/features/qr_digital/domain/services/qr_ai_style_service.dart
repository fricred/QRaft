import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../entities/qr_ai_style_result.dart';

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

/// Thrown by [QrAiStyleService.stylize] on non-recoverable errors.
///
/// [code] values:
/// - `'wrong_profile'`        — QR is not digitalOnly (profile != 1)
/// - `'monthly_limit_reached'` — Edge Function returned HTTP 429
/// - `'replicate_failed'`      — Edge Function returned HTTP 500 or Replicate
///                               prediction ended with status "failed"
/// - `'invalid_image_source'`  — Replicate output URL is not on an allow-listed domain
/// - `'network_error'`         — Unexpected network exception
class QrAiStyleException implements Exception {
  /// Error classification code.
  final String code;

  const QrAiStyleException(this.code);

  @override
  String toString() => 'QrAiStyleException($code)';
}

// ---------------------------------------------------------------------------
// Allow-listed Replicate CDN domains (T-06-09)
// ---------------------------------------------------------------------------

const _allowedImageHosts = [
  'replicate.delivery',
  'pbxt.replicate.delivery',
];

bool _isAllowedImageUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return _allowedImageHosts.any(
      (host) => uri.host == host || uri.host.endsWith('.$host'),
    );
  } catch (_) {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Service that drives the AI QR stylization flow.
///
/// The Flutter client NEVER calls Replicate directly — all requests go through
/// the Supabase Edge Function `ai-stylize` which holds the API key server-side
/// and enforces the 5 calls/month rate limit.
///
/// Flow:
/// 1. Profile guard: digitalOnly QR codes only (T-06-11).
/// 2. Prompt truncation at 200 chars (T-06-08; server also validates).
/// 3. POST to `ai-stylize` Edge Function → prediction ID.
/// 4. Poll `ai-stylize` with `{prediction_id}` every 3 s until succeeded/failed.
/// 5. Download image bytes from Replicate CDN (domain whitelist, T-06-09).
/// 6. Write to temp file → [MobileScannerController.analyzeImage] scannability
///    gate → delete temp file.
/// 7. Return [QrAiStyleResult] with [scanOk] flag.
class QrAiStyleService {
  /// Inject [SupabaseClient] for testability.
  final SupabaseClient supabaseClient;

  const QrAiStyleService({required this.supabaseClient});

  /// Stylizes a QR code image using the Replicate ControlNet model via the
  /// Supabase Edge Function proxy.
  ///
  /// Parameters:
  /// - [qrStorageUrl]  — Public Supabase Storage URL of the base QR PNG.
  /// - [prompt]        — User-supplied style description; truncated to 200 chars.
  /// - [userId]        — Authenticated user ID for the usage counter.
  /// - [profile]       — [QRCustomization.profile] value; must be `1` (digitalOnly).
  ///
  /// Optional injection parameters (for testing only):
  /// - [analyzeImageOverride] — Replaces the real [MobileScannerController.analyzeImage]
  ///   call; receives the temp file path.
  /// - [httpGetOverride]      — Replaces the real `http.get` download call; receives
  ///   the Replicate output URL.
  ///
  /// Throws [QrAiStyleException] on:
  /// - [profile] != 1 → `'wrong_profile'`
  /// - HTTP 429 from Edge Function → `'monthly_limit_reached'`
  /// - HTTP 5xx or Replicate `failed` status → `'replicate_failed'`
  /// - Non-whitelisted image URL → `'invalid_image_source'`
  /// - Network exception → `'network_error'`
  Future<QrAiStyleResult> stylize({
    required String qrStorageUrl,
    required String prompt,
    required String userId,
    required int profile,
    Future<BarcodeCapture?> Function(String imagePath)? analyzeImageOverride,
    Future<Uint8List> Function(String url)? httpGetOverride,
  }) async {
    // T-06-11: Profile guard — reject non-digitalOnly QR codes.
    if (profile != 1) {
      throw const QrAiStyleException('wrong_profile');
    }

    // T-06-08: Truncate prompt to 200 chars (server also validates).
    final safePrompt =
        prompt.length > 200 ? prompt.substring(0, 200) : prompt;

    try {
      // ------------------------------------------------------------------
      // Step 1: Create prediction via Edge Function.
      // ------------------------------------------------------------------
      final createResponse = await supabaseClient.functions.invoke(
        'ai-stylize',
        body: {'qr_url': qrStorageUrl, 'prompt': safePrompt},
      );

      if (createResponse.status == 429) {
        throw const QrAiStyleException('monthly_limit_reached');
      }
      if (createResponse.status >= 500) {
        throw const QrAiStyleException('replicate_failed');
      }
      if (createResponse.status < 200 || createResponse.status >= 300) {
        throw const QrAiStyleException('replicate_failed');
      }

      final createData = createResponse.data as Map<String, dynamic>;
      final predictionId = createData['id'] as String?;

      if (predictionId == null || predictionId.isEmpty) {
        throw const QrAiStyleException('replicate_failed');
      }

      // ------------------------------------------------------------------
      // Step 2: Poll prediction until succeeded or failed (timeout 90 s).
      // ------------------------------------------------------------------
      const pollInterval = Duration(seconds: 3);
      const timeout = Duration(seconds: 90);
      final deadline = DateTime.now().add(timeout);

      String? outputUrl;

      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(pollInterval);

        final pollResponse = await supabaseClient.functions.invoke(
          'ai-stylize',
          body: {'prediction_id': predictionId},
        );

        if (pollResponse.status == 429) {
          throw const QrAiStyleException('monthly_limit_reached');
        }
        if (pollResponse.status >= 500) {
          throw const QrAiStyleException('replicate_failed');
        }

        final pollData = pollResponse.data as Map<String, dynamic>;
        final status = pollData['status'] as String? ?? '';

        if (status == 'succeeded') {
          // Output is a list of URLs; take the first.
          final output = pollData['output'];
          if (output is List && output.isNotEmpty) {
            outputUrl = output.first as String?;
          }
          break;
        } else if (status == 'failed' || status == 'canceled') {
          throw const QrAiStyleException('replicate_failed');
        }
        // status == 'starting' | 'processing' → continue polling
      }

      if (outputUrl == null || outputUrl.isEmpty) {
        throw const QrAiStyleException('replicate_failed');
      }

      // ------------------------------------------------------------------
      // Step 3: Domain whitelist check (T-06-09).
      // ------------------------------------------------------------------
      if (!_isAllowedImageUrl(outputUrl)) {
        throw const QrAiStyleException('invalid_image_source');
      }

      // ------------------------------------------------------------------
      // Step 4: Download image bytes.
      // ------------------------------------------------------------------
      final Uint8List imageBytes;
      if (httpGetOverride != null) {
        imageBytes = await httpGetOverride(outputUrl);
      } else {
        final response = await http.get(Uri.parse(outputUrl));
        if (response.statusCode != 200) {
          throw const QrAiStyleException('replicate_failed');
        }
        imageBytes = response.bodyBytes;
      }

      // ------------------------------------------------------------------
      // Step 5: Scannability gate via mobile_scanner.
      // ------------------------------------------------------------------
      final bool scanOk;

      if (analyzeImageOverride != null) {
        // Test injection path.
        final capture = await analyzeImageOverride(outputUrl);
        scanOk = capture != null && capture.barcodes.isNotEmpty;
      } else {
        // Production path: write bytes to temp file, scan, clean up.
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/ai_scan_check.png');
        await file.writeAsBytes(imageBytes);

        BarcodeCapture? capture;
        MobileScannerController? controller;
        try {
          controller = MobileScannerController();
          capture = await controller.analyzeImage(file.path);
        } finally {
          await controller?.dispose();
          if (await file.exists()) await file.delete();
        }

        scanOk = capture != null && capture.barcodes.isNotEmpty;
      }

      return QrAiStyleResult(imageBytes: imageBytes, scanOk: scanOk);
    } on QrAiStyleException {
      rethrow;
    } catch (e) {
      throw QrAiStyleException('network_error');
    }
  }
}
