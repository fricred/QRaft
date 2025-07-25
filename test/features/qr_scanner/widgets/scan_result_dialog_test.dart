import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qraft/features/qr_scanner/models/scan_result.dart';
import 'package:qraft/features/qr_scanner/widgets/scan_result_dialog.dart';
import 'package:qraft/l10n/app_localizations.dart';

void main() {
  group('ScanResultDialog URL Tests', () {
    testWidgets('should display URL scan result correctly', (WidgetTester tester) async {
      // Arrange
      final urlScanResult = ScanResult.fromRawValue('https://github.com/test');
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
          ],
          home: Scaffold(
            body: ScanResultDialog(scanResult: urlScanResult),
          ),
        ),
      );
      
      // Assert
      expect(find.text('QR Code Scanned!'), findsOneWidget);
      expect(find.text('Website URL'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      
      // Check if the display value is properly formatted
      expect(find.text('github.com/test'), findsOneWidget);
      
      print('✅ URL scan result dialog displays correctly');
    });

    testWidgets('should display mock gallery URL correctly', (WidgetTester tester) async {
      // Arrange - simulate gallery mock result
      final mockUrl = 'https://example.com/gallery-test-qr-${DateTime.now().millisecondsSinceEpoch}';
      final galleryScanResult = ScanResult.fromRawValue(mockUrl);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanResultDialog(scanResult: galleryScanResult),
          ),
        ),
      );
      
      // Assert
      expect(find.text('QR Code Scanned!'), findsOneWidget);
      expect(find.text('Website URL'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      
      print('✅ Mock gallery URL scan result displays correctly');
      print('   Mock URL: $mockUrl');
    });

    testWidgets('should handle various URL formats', (WidgetTester tester) async {
      final testUrls = [
        'https://google.com',
        'http://example.com',
        'www.github.com',
        'flutter.dev',
      ];
      
      for (final testUrl in testUrls) {
        // Arrange
        final scanResult = ScanResult.fromRawValue(testUrl);
        
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScanResultDialog(scanResult: scanResult),
            ),
          ),
        );
        
        // Assert
        expect(find.text('Website URL'), findsOneWidget);
        expect(find.text('Open'), findsOneWidget);
        
        print('✅ URL format handled: $testUrl');
        
        // Clear the widget tree for next iteration
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });
}