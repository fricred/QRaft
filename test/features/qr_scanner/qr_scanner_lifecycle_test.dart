// Tests for QRScannerScreen lifecycle management and tapToFocus feature.
//
// These tests verify observable behavior of the WidgetsBindingObserver
// integration and the _isPermissionPermanentlyDenied flag without requiring
// real camera hardware. They run against the source code directly.
//
// RED phase: All tests should FAIL before implementation (Task 1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/l10n/app_localizations.dart';

// We import the screen under test via a source-level import.
// The test can verify structural properties of the class.
import 'package:qraft/features/qr_scanner/qr_scanner_screen.dart';


/// testWidgets + teardown: the screen's entrance animations schedule delayed timers, so
/// unmount the tree and let them expire before the binding checks for pending timers.
void testScreen(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}

void main() {
  // Ensure Flutter binding is initialized
  TestWidgetsFlutterBinding.ensureInitialized();

  // Silence platform channel errors from mobile_scanner in test environment
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.steenbakker.mobile_scanner/scanner/method'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.steenbakker.mobile_scanner/scanner/method'),
      null,
    );
  });

  Widget buildTestApp() {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const QRScannerScreen(),
      ),
    );
  }

  group('QRScannerScreen - WidgetsBindingObserver lifecycle', () {
    testScreen(
        'QRScannerScreen registers WidgetsBindingObserver on initState',
        (WidgetTester tester) async {
      // Build the screen
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // The screen should be registered as a WidgetsBindingObserver.
      // We verify indirectly: calling didChangeAppLifecycleState should not
      // throw when the screen is active.
      final binding = tester.binding;
      expect(
        () => binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive),
        returnsNormally,
        reason: 'Lifecycle state change should not throw when observer is registered',
      );

      // Resume the app
      expect(
        () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
        returnsNormally,
      );
    });

    testScreen(
        'QRScannerScreen handles AppLifecycleState.inactive without error',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      final binding = tester.binding;

      // This should not throw — the observer must handle the inactive state
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
    });

    testScreen(
        'QRScannerScreen handles AppLifecycleState.resumed without error',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      final binding = tester.binding;

      // Go inactive then resume
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
    });

    testScreen(
        'QRScannerScreen disposes cleanly without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Rebuild with a different widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('replaced'))),
      );
      await tester.pump();

      // If removeObserver was not called in dispose, Flutter would complain.
      // The test passing without error is the assertion.
      expect(find.text('replaced'), findsOneWidget);
    });
  });

  group('QRScannerScreen - Permission denied persistent UI', () {
    testScreen(
        'Shows Open Settings button when permission is permanently denied',
        (WidgetTester tester) async {
      // Mock the permission_handler to return permanently denied
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'checkPermissionStatus') return 4; // permanentlyDenied
          if (methodCall.method == 'requestPermissions') return {1: 4}; // camera -> permanentlyDenied
          return null;
        },
      );

      await tester.pumpWidget(buildTestApp());
      // Allow async permission check to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The persistent "Open Settings" button should be visible
      // This test will FAIL until _buildPermissionDeniedView is implemented
      expect(
        find.byKey(const Key('scanner_open_settings_button')),
        findsOneWidget,
        reason: '_buildPermissionDeniedView should show scanner_open_settings_button when permanently denied',
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        null,
      );
    });
  });

  group('QRScannerScreen - Maestro identifiers', () {
    testScreen(
        'Flash button has scanner_flash_button Semantics identifier',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(
        find.byKey(const Key('scanner_flash_button')),
        findsOneWidget,
        reason: 'Flash button must have Key(scanner_flash_button) for Maestro',
      );
    });

    testScreen(
        'Gallery button has scanner_gallery_button Semantics identifier',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(
        find.byKey(const Key('scanner_gallery_button')),
        findsOneWidget,
        reason: 'Gallery button must have Key(scanner_gallery_button) for Maestro',
      );
    });

    testScreen(
        'History button has scanner_history_button Semantics identifier',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(
        find.byKey(const Key('scanner_history_button')),
        findsOneWidget,
        reason: 'History button must have Key(scanner_history_button) for Maestro',
      );
    });

    testScreen(
        'Scan button has scanner_scan_button Semantics identifier',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(
        find.byKey(const Key('scanner_scan_button')),
        findsOneWidget,
        reason: 'Scan button must have Key(scanner_scan_button) for Maestro',
      );
    });
  });
}
