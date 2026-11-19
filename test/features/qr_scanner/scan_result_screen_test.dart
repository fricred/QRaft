import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qraft/features/qr_scanner/models/scan_result.dart';
import 'package:qraft/features/qr_scanner/scan_result_screen.dart';
import 'package:qraft/l10n/app_localizations.dart';

/// Pumps the screen inside a localized MaterialApp.
///
/// The locale is pinned to English so assertions can match the `app_en.arb`
/// strings regardless of the host machine's locale.
Future<void> _pumpScreen(WidgetTester tester, ScanResult scanResult) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      home: ScanResultScreen(scanResult: scanResult),
    ),
  );
  // Settle the entry animations without waiting on the repeating ones.
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  group('ScanResultScreen — URL results', () {
    testWidgets('renders the success header, type pill and primary action',
        (tester) async {
      final scanResult = ScanResult.fromRawValue('https://github.com/test');

      await _pumpScreen(tester, scanResult);

      expect(find.text('Code scanned!'), findsOneWidget);
      expect(find.text('Website'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      expect(find.text('github.com/test'), findsOneWidget);
    });

    testWidgets('is a full page, not a dialog', (tester) async {
      await _pumpScreen(
        tester,
        ScanResult.fromRawValue('https://github.com/test'),
      );

      expect(find.byKey(const Key('scan_result_screen_root')), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('exposes the Maestro identifiers the flows rely on',
        (tester) async {
      await _pumpScreen(
        tester,
        ScanResult.fromRawValue('https://github.com/test'),
      );

      expect(find.byKey(const Key('scan_result_back_button')), findsOneWidget);
      expect(find.byKey(const Key('scan_result_share_button')), findsOneWidget);
      expect(find.byKey(const Key('scan_result_copy_button')), findsOneWidget);
      expect(
        find.byKey(const Key('scan_result_primary_action')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('scan_result_scan_again')), findsOneWidget);
    });

    testWidgets('handles assorted URL formats', (tester) async {
      const urls = [
        'https://github.com/test',
        'http://example.com',
        'www.google.com',
        'github.com/user/repo',
      ];

      for (final url in urls) {
        await _pumpScreen(tester, ScanResult.fromRawValue(url));

        expect(find.text('Website'), findsOneWidget, reason: 'for $url');
        expect(find.text('Open'), findsOneWidget, reason: 'for $url');
      }
    });
  });

  group('ScanResultScreen — other types', () {
    testWidgets('a plain text result offers Share as the primary action',
        (tester) async {
      await _pumpScreen(
        tester,
        ScanResult.fromRawValue('just some scanned text'),
      );

      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('a phone result offers Call as the primary action',
        (tester) async {
      await _pumpScreen(tester, ScanResult.fromRawValue('tel:+573001234567'));

      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
    });
  });
}
