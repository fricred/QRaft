import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:qraft/features/qr_digital/domain/entities/qr_ai_style_result.dart';
import 'package:qraft/features/qr_digital/domain/services/qr_ai_style_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal 1×1 white PNG (68 bytes) for testing.
/// Enough to satisfy the image bytes requirement without rendering.
Uint8List _minimalPng() {
  return Uint8List.fromList([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, // PNG signature
    0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52, // IHDR chunk length + type
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // width=1, height=1
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // bit depth, color type, etc.
    0xde, 0x00, 0x00, 0x00, 0x0c, 0x49, 0x44, 0x41, // IDAT chunk
    0x54, 0x08, 0xd7, 0x63, 0xf8, 0xcf, 0xc0, 0x00, // compressed data
    0x00, 0x00, 0x02, 0x00, 0x01, 0xe2, 0x21, 0xbc, // CRC
    0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, // IEND chunk
    0x44, 0xae, 0x42, 0x60, 0x82, // IEND CRC
  ]);
}

/// Mock FunctionResponse factory
FunctionResponse _functionResponse({
  required int status,
  dynamic data,
}) {
  return FunctionResponse(status: status, data: data ?? {});
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctions;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockFunctions = MockFunctionsClient();

    when(() => mockClient.functions).thenReturn(mockFunctions);
  });

  group('QrAiStyleResult', () {
    test('scanOk is true when imageBytes is non-empty and scanOk=true', () {
      final result = QrAiStyleResult(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        scanOk: true,
      );
      expect(result.scanOk, isTrue);
      expect(result.imageBytes, hasLength(3));
    });

    test('scanOk is false when imageBytes is empty (zero-length)', () {
      const result = QrAiStyleResult(
        imageBytes: Uint8List(0),
        scanOk: false,
      );
      expect(result.scanOk, isFalse);
      expect(result.imageBytes, isEmpty);
    });
  });

  group('QrAiStyleService.stylize()', () {
    test(
      'throws QrAiStyleException(monthly_limit_reached) when Edge Function returns 429',
      () async {
        when(
          () => mockFunctions.invoke(
            'ai-stylize',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => _functionResponse(
            status: 429,
            data: {'error': 'monthly_limit_reached'},
          ),
        );

        final service = QrAiStyleService(supabaseClient: mockClient);

        expect(
          () => service.stylize(
            qrStorageUrl: 'https://example.supabase.co/storage/qr.png',
            prompt: 'cyberpunk',
            userId: 'user-123',
            profile: 1, // digitalOnly
          ),
          throwsA(
            isA<QrAiStyleException>()
                .having((e) => e.code, 'code', 'monthly_limit_reached'),
          ),
        );
      },
    );

    test(
      'throws QrAiStyleException(replicate_failed) when Edge Function returns 500',
      () async {
        when(
          () => mockFunctions.invoke(
            'ai-stylize',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => _functionResponse(
            status: 500,
            data: {'error': 'replicate_failed'},
          ),
        );

        final service = QrAiStyleService(supabaseClient: mockClient);

        expect(
          () => service.stylize(
            qrStorageUrl: 'https://example.supabase.co/storage/qr.png',
            prompt: 'watercolor',
            userId: 'user-123',
            profile: 1,
          ),
          throwsA(
            isA<QrAiStyleException>()
                .having((e) => e.code, 'code', 'replicate_failed'),
          ),
        );
      },
    );

    test(
      'returns QrAiStyleResult(scanOk: true) when analyzeImage returns non-empty barcodes',
      () async {
        final pngBytes = _minimalPng();

        // First call: creates prediction
        when(
          () => mockFunctions.invoke(
            'ai-stylize',
            body: {'qr_url': 'https://example.supabase.co/storage/qr.png', 'prompt': 'cyberpunk'},
          ),
        ).thenAnswer(
          (_) async => _functionResponse(
            status: 200,
            data: {'id': 'pred-abc123', 'status': 'starting'},
          ),
        );

        // Second call: polls prediction — succeeded with output URL
        when(
          () => mockFunctions.invoke(
            'ai-stylize',
            body: {'prediction_id': 'pred-abc123'},
          ),
        ).thenAnswer(
          (_) async => _functionResponse(
            status: 200,
            data: {
              'id': 'pred-abc123',
              'status': 'succeeded',
              'output': ['https://replicate.delivery/output/ai_qr.png'],
            },
          ),
        );

        final service = QrAiStyleService(supabaseClient: mockClient);

        // Inject override for both scannability gate and HTTP download
        final result = await service.stylize(
          qrStorageUrl: 'https://example.supabase.co/storage/qr.png',
          prompt: 'cyberpunk',
          userId: 'user-123',
          profile: 1,
          // analyzeImage override returns a capture with one barcode
          analyzeImageOverride: (_) async => BarcodeCapture(
            barcodes: [const Barcode(rawValue: 'https://example.com')],
          ),
          // HTTP download override returns minimal PNG bytes
          httpGetOverride: (_) async => pngBytes,
        );

        expect(result.scanOk, isTrue);
        expect(result.imageBytes, equals(pngBytes));
      },
    );

    test(
      'returns QrAiStyleResult(scanOk: false) when analyzeImage returns empty barcodes',
      () async {
        final pngBytes = _minimalPng();

        when(
          () => mockFunctions.invoke(
            'ai-stylize',
            body: {'qr_url': 'https://example.supabase.co/storage/qr.png', 'prompt': 'abstract'},
          ),
        ).thenAnswer(
          (_) async => _functionResponse(
            status: 200,
            data: {'id': 'pred-xyz789', 'status': 'starting'},
          ),
        );

        when(
          () => mockFunctions.invoke(
            'ai-stylize',
            body: {'prediction_id': 'pred-xyz789'},
          ),
        ).thenAnswer(
          (_) async => _functionResponse(
            status: 200,
            data: {
              'id': 'pred-xyz789',
              'status': 'succeeded',
              'output': ['https://replicate.delivery/output/ai_qr_2.png'],
            },
          ),
        );

        final service = QrAiStyleService(supabaseClient: mockClient);

        final result = await service.stylize(
          qrStorageUrl: 'https://example.supabase.co/storage/qr.png',
          prompt: 'abstract',
          userId: 'user-123',
          profile: 1,
          analyzeImageOverride: (_) async => BarcodeCapture(barcodes: const []),
          httpGetOverride: (_) async => pngBytes,
        );

        expect(result.scanOk, isFalse);
      },
    );

    test(
      'throws QrAiStyleException(wrong_profile) when profile != 1 (digitalOnly)',
      () async {
        final service = QrAiStyleService(supabaseClient: mockClient);

        // profile 0 = printSafe
        expect(
          () => service.stylize(
            qrStorageUrl: 'https://example.supabase.co/storage/qr.png',
            prompt: 'cyberpunk',
            userId: 'user-123',
            profile: 0,
          ),
          throwsA(
            isA<QrAiStyleException>()
                .having((e) => e.code, 'code', 'wrong_profile'),
          ),
        );

        // profile 2 = tattooSafe
        expect(
          () => service.stylize(
            qrStorageUrl: 'https://example.supabase.co/storage/qr.png',
            prompt: 'geometric',
            userId: 'user-123',
            profile: 2,
          ),
          throwsA(
            isA<QrAiStyleException>()
                .having((e) => e.code, 'code', 'wrong_profile'),
          ),
        );
      },
    );
  });
}
