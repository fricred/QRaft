import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qraft/features/qr_generator/presentation/pages/wifi_qr_screen.dart';
import 'package:qraft/features/qr_generator/presentation/providers/qr_providers.dart';
import 'package:qraft/features/qr_generator/domain/use_cases/generate_qr_use_case.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_code_entity.dart';
import 'package:qraft/features/auth/data/providers/supabase_auth_provider.dart';
import 'package:qraft/shared/widgets/glass_button.dart';
import 'package:qraft/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../test_utilities/qr_test_utilities.dart';

// Mock Classes
class MockGenerateQRUseCase extends Mock implements GenerateQRUseCase {}
class MockSupabaseAuthProvider extends Mock implements SupabaseAuthProvider {}

void main() {
  group('WiFiQRScreen Tests', () {
    late MockGenerateQRUseCase mockGenerateQRUseCase;
    late MockSupabaseAuthProvider mockAuthProvider;

    setUp(() {
      mockGenerateQRUseCase = MockGenerateQRUseCase();
      mockAuthProvider = MockSupabaseAuthProvider();
      
      // Setup default mock behavior
      when(() => mockAuthProvider.currentUser).thenReturn(
        MockUser(id: 'test-user-id', email: 'test@example.com') as User?,
      );
      when(() => mockGenerateQRUseCase.execute(
        name: any(named: 'name'),
        type: any(named: 'type'),
        data: any(named: 'data'),
        userId: any(named: 'userId'),
        customization: any(named: 'customization'),
      )).thenAnswer((_) async => MockQRCodeEntity() as QRCodeEntity);
      
      // Reset mock services
      MockImagePicker.reset();
    });

    Widget createTestWidget([List<Override>? overrides]) {
      return ProviderScope(
        overrides: [
          generateQRUseCaseProvider.overrideWithValue(mockGenerateQRUseCase),
          supabaseAuthProvider.overrideWith((ref) => mockAuthProvider),
          ...?overrides,
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WiFiQRScreen(),
        ),
      );
    }

    group('Widget Rendering Tests', () {
      testWidgets('renders WiFi QR screen with correct structure', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify main components
        expect(find.byType(WiFiQRScreen), findsOneWidget);
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.byType(TabBarView), findsOneWidget);
        
        // Verify tabs
        expect(find.text('Form'), findsOneWidget);
        expect(find.text('Style'), findsOneWidget);
        
        // Verify bottom action area
        expect(find.byType(PrimaryGlassButton), findsOneWidget);
        expect(find.text('Save QR Code'), findsOneWidget);
      });

      testWidgets('displays app bar with correct title', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('WiFi QR'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_ios_rounded), findsOneWidget);
      });

      testWidgets('shows form tab by default', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Form should be visible by default
        expect(find.text('WiFi Network Details'), findsOneWidget);
        expect(find.text('Enter WiFi network details to create a QR code for easy sharing'), findsOneWidget);
      });
    });

    group('WiFi Form Tests', () {
      testWidgets('displays all required form fields', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for form fields
        expect(find.text('Network Name (SSID) *'), findsOneWidget);
        expect(find.text('Security Type'), findsOneWidget);
        expect(find.text('Password *'), findsOneWidget);
        expect(find.text('Hidden Network'), findsOneWidget);
        
        // Check for security type options
        expect(find.text('WPA/WPA2 (Recommended)'), findsOneWidget);
        expect(find.text('WEP (Legacy)'), findsOneWidget);
        expect(find.text('Open Network (No Password)'), findsOneWidget);
      });

      testWidgets('validates network name correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final networkField = find.widgetWithIcon(TextField, Icons.wifi_rounded);

        // Test empty network name
        await QRTestHelpers.enterTextInField(tester, '', networkField);
        await tester.pumpAndSettle();
        QRTestHelpers.expectValidationError('Network name is required');

        // Test too long network name
        await QRTestHelpers.enterTextInField(
          tester, 
          'This_is_a_very_long_network_name_that_exceeds_the_32_character_limit',
          networkField,
        );
        await tester.pumpAndSettle();
        QRTestHelpers.expectValidationError('Network name must be 32 characters or less');

        // Test valid network names
        for (final validName in QRTestData.validNetworkNames) {
          await QRTestHelpers.enterTextInField(tester, validName, networkField);
          await tester.pumpAndSettle();
          
          QRTestHelpers.expectNoValidationError('Network name is required');
          QRTestHelpers.expectNoValidationError('Network name must be 32 characters or less');
        }
      });

      testWidgets('validates password for secured networks', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill network name first
        await QRTestHelpers.enterTextInField(
          tester, 
          'TestNetwork', 
          find.widgetWithIcon(TextField, Icons.wifi_rounded),
        );

        // For WPA (default), password should be required
        final passwordField = find.widgetWithIcon(TextField, Icons.lock_rounded);
        
        await QRTestHelpers.enterTextInField(tester, '', passwordField);
        await tester.pumpAndSettle();
        QRTestHelpers.expectValidationError('Password is required for secured networks');

        // Test too long password
        await QRTestHelpers.enterTextInField(
          tester, 
          'This_is_an_extremely_long_password_that_exceeds_the_63_character_limit_for_wifi_passwords',
          passwordField,
        );
        await tester.pumpAndSettle();
        QRTestHelpers.expectValidationError('Password must be 63 characters or less');

        // Test valid passwords
        for (final validPassword in QRTestData.validPasswords) {
          await QRTestHelpers.enterTextInField(tester, validPassword, passwordField);
          await tester.pumpAndSettle();
          
          QRTestHelpers.expectNoValidationError('Password is required for secured networks');
          QRTestHelpers.expectNoValidationError('Password must be 63 characters or less');
        }
      });

      testWidgets('hides password field for open network', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Select open network option
        await tester.tap(find.text('Open Network (No Password)'));
        await tester.pumpAndSettle();

        // Password field should be hidden
        expect(find.widgetWithIcon(TextField, Icons.lock_rounded), findsNothing);
        expect(find.text('Password *'), findsNothing);
      });

      testWidgets('shows password field for secured networks', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // WPA should be selected by default, password field visible
        expect(find.widgetWithIcon(TextField, Icons.lock_rounded), findsOneWidget);
        expect(find.text('Password *'), findsOneWidget);

        // Switch to WEP
        await tester.tap(find.text('WEP (Legacy)'));
        await tester.pumpAndSettle();

        // Password field should still be visible
        expect(find.widgetWithIcon(TextField, Icons.lock_rounded), findsOneWidget);
        expect(find.text('Password *'), findsOneWidget);
      });

      testWidgets('toggles password visibility', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter password
        await QRTestHelpers.enterTextInField(
          tester, 
          'testpassword', 
          find.widgetWithIcon(TextField, Icons.lock_rounded),
        );

        // Find visibility toggle button
        final visibilityButton = find.byIcon(Icons.visibility);
        expect(visibilityButton, findsOneWidget);

        // Tap to show password
        await tester.tap(visibilityButton);
        await tester.pumpAndSettle();

        // Should show hide button now
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsNothing);

        // Tap to hide password again
        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pumpAndSettle();

        // Should show visibility button again
        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off), findsNothing);
      });

      testWidgets('toggles hidden network setting', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final hiddenToggle = find.byType(Switch);
        expect(hiddenToggle, findsOneWidget);

        // Should be off by default
        expect(tester.widget<Switch>(hiddenToggle).value, false);

        // Toggle on
        await tester.tap(hiddenToggle);
        await tester.pumpAndSettle();

        // Should be on now
        expect(tester.widget<Switch>(hiddenToggle).value, true);

        // Toggle off
        await tester.tap(hiddenToggle);
        await tester.pumpAndSettle();

        // Should be off again
        expect(tester.widget<Switch>(hiddenToggle).value, false);
      });

      testWidgets('enables save button only when form is valid', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final saveButton = find.byType(PrimaryGlassButton);
        
        // Initially disabled
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNull);

        // Fill network name only
        await QRTestHelpers.enterTextInField(
          tester, 
          'TestNetwork', 
          find.widgetWithIcon(TextField, Icons.wifi_rounded),
        );
        await tester.pumpAndSettle();

        // Still disabled (no password for secured network)
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNull);

        // Fill password
        await QRTestHelpers.enterTextInField(
          tester, 
          'password123', 
          find.widgetWithIcon(TextField, Icons.lock_rounded),
        );
        await tester.pumpAndSettle();

        // Should be enabled now
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNotNull);
      });
    });

    group('Security Type Selection Tests', () {
      testWidgets('selects different security types correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // WPA should be selected by default (has check mark)
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

        // Select WEP
        await tester.tap(find.text('WEP (Legacy)'));
        await tester.pumpAndSettle();

        // WEP should be selected now
        final wepOption = find.ancestor(
          of: find.text('WEP (Legacy)'),
          matching: find.byType(Container),
        ).first;
        
        // Should show as selected (different styling)
        expect(find.descendant(
          of: wepOption,
          matching: find.byIcon(Icons.check_circle_rounded),
        ), findsOneWidget);

        // Select Open Network
        await tester.tap(find.text('Open Network (No Password)'));
        await tester.pumpAndSettle();

        // Open network should be selected
        final openOption = find.ancestor(
          of: find.text('Open Network (No Password)'),
          matching: find.byType(Container),
        ).first;
        
        expect(find.descendant(
          of: openOption,
          matching: find.byIcon(Icons.check_circle_rounded),
        ), findsOneWidget);
      });

      testWidgets('updates password requirement based on security type', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill network name
        await QRTestHelpers.enterTextInField(
          tester, 
          'TestNetwork', 
          find.widgetWithIcon(TextField, Icons.wifi_rounded),
        );

        // For secured networks, form should be invalid without password
        final saveButton = find.byType(PrimaryGlassButton);
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNull);

        // Switch to open network
        await tester.tap(find.text('Open Network (No Password)'));
        await tester.pumpAndSettle();

        // Should be valid now (no password required)
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNotNull);

        // Switch back to secured network
        await tester.tap(find.text('WPA/WPA2 (Recommended)'));
        await tester.pumpAndSettle();

        // Should be invalid again (password required)
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNull);
      });
    });

    group('QR Customization Tests', () {
      testWidgets('shows QR preview when form is valid', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill valid form data
        await QRTestHelpers.enterTextInField(
          tester, 
          'TestNetwork', 
          find.widgetWithIcon(TextField, Icons.wifi_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          'password123', 
          find.widgetWithIcon(TextField, Icons.lock_rounded),
        );

        // Switch to style tab
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();

        // Should show QR preview
        expect(find.text('Complete form\nto see preview'), findsNothing);
        expect(find.text('View Full Size'), findsOneWidget);
      });

      testWidgets('shows placeholder when form is invalid', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to style tab without filling form
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();

        // Should show placeholder
        expect(find.text('Complete form\nto see preview'), findsOneWidget);
        expect(find.text('View Full Size'), findsNothing);
      });

      testWidgets('can access color customization', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to style tab
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();

        // Should show customization tabs
        expect(find.text('Colors'), findsWidgets);
        expect(find.text('Size'), findsWidgets);
        expect(find.text('Logo'), findsWidgets);
      });
    });

    group('Save QR Code Tests', () {
      testWidgets('saves WiFi QR code successfully', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        const networkName = 'TestNetwork';
        const password = 'password123';

        // Fill valid form
        await QRTestHelpers.enterTextInField(
          tester, 
          networkName, 
          find.widgetWithIcon(TextField, Icons.wifi_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          password, 
          find.widgetWithIcon(TextField, Icons.lock_rounded),
        );

        await tester.pumpAndSettle();

        // Tap save button
        await QRTestHelpers.tapButtonAndWait(tester, find.byType(PrimaryGlassButton));

        // Verify use case was called
        verify(() => mockGenerateQRUseCase.execute(
          name: 'WiFi: $networkName',
          type: any(named: 'type'),
          data: any(named: 'data'),
          userId: 'test-user-id',
          customization: any(named: 'customization'),
        )).called(1);

        // Should show success message
        QRTestHelpers.expectSnackBar('WiFi QR code "$networkName" saved successfully!');
      });

      testWidgets('handles save errors gracefully', (tester) async {
        when(() => mockGenerateQRUseCase.execute(
          name: any(named: 'name'),
          type: any(named: 'type'),
          data: any(named: 'data'),
          userId: any(named: 'userId'),
          customization: any(named: 'customization'),
        )).thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill valid form
        await QRTestHelpers.enterTextInField(
          tester, 
          'TestNetwork', 
          find.widgetWithIcon(TextField, Icons.wifi_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          'password123', 
          find.widgetWithIcon(TextField, Icons.lock_rounded),
        );

        await tester.pumpAndSettle();

        // Tap save button
        await QRTestHelpers.tapButtonAndWait(tester, find.byType(PrimaryGlassButton));

        // Should show error message
        QRTestHelpers.expectSnackBar('Failed to save QR code: Exception: Network error');
      });

      testWidgets('shows loading state during save', (tester) async {
        // Make the use case take some time
        when(() => mockGenerateQRUseCase.execute(
          name: any(named: 'name'),
          type: any(named: 'type'),
          data: any(named: 'data'),
          userId: any(named: 'userId'),
          customization: any(named: 'customization'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return MockQRCodeEntity() as QRCodeEntity;
        });

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill valid form
        await QRTestHelpers.enterTextInField(
          tester, 
          'TestNetwork', 
          find.widgetWithIcon(TextField, Icons.wifi_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          'password123', 
          find.widgetWithIcon(TextField, Icons.lock_rounded),
        );

        await tester.pumpAndSettle();

        // Tap save button
        await tester.tap(find.byType(PrimaryGlassButton));
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for completion
        await tester.pumpAndSettle();

        // Loading should be gone
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('WiFi QR Data Format Tests', () {
      testWidgets('generates correct WiFi QR data format', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        const networkName = 'TestNetwork';
        const password = 'password123';

        // Fill form with WPA security
        await QRTestHelpers.enterTextInField(
          tester, 
          networkName, 
          find.widgetWithIcon(TextField, Icons.wifi_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          password, 
          find.widgetWithIcon(TextField, Icons.lock_rounded),
        );

        // Enable hidden network
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        // Get the form state to verify QR data format
        final container = ProviderScope.containerOf(
          tester.element(find.byType(WiFiQRScreen)),
        );
        final wifiState = container.read(wifiFormProvider);
        final qrData = wifiState.wifiData.qrData;

        // Should match WiFi QR format
        expect(qrData, QRMatchers.isWiFiQRFormat());
        expect(qrData, contains('T:WPA'));
        expect(qrData, contains('S:$networkName'));
        expect(qrData, contains('P:$password'));
        expect(qrData, contains('H:true'));
      });

      testWidgets('generates correct QR data for open network', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        const networkName = 'OpenNetwork';

        // Fill form and select open network
        await QRTestHelpers.enterTextInField(
          tester, 
          networkName, 
          find.widgetWithIcon(TextField, Icons.wifi_rounded),
        );
        
        await tester.tap(find.text('Open Network (No Password)'));
        await tester.pumpAndSettle();

        // Get the form state
        final container = ProviderScope.containerOf(
          tester.element(find.byType(WiFiQRScreen)),
        );
        final wifiState = container.read(wifiFormProvider);
        final qrData = wifiState.wifiData.qrData;

        // Should be correct format for open network
        expect(qrData, QRMatchers.isWiFiQRFormat());
        expect(qrData, contains('T:nopass'));
        expect(qrData, contains('S:$networkName'));
        expect(qrData, contains('P:'));  // Empty password
        expect(qrData, contains('H:false'));
      });
    });

    group('State Management Tests', () {
      testWidgets('resets form state on initialization', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Form should start clean
        final container = ProviderScope.containerOf(
          tester.element(find.byType(WiFiQRScreen)),
        );
        final wifiState = container.read(wifiFormProvider);
        
        expect(wifiState.networkName, isEmpty);
        expect(wifiState.password, isEmpty);
        expect(wifiState.security, 'WPA');
        expect(wifiState.hidden, false);
        expect(wifiState.isValid, false);
      });

      testWidgets('maintains state during tab navigation', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill some data
        await QRTestHelpers.enterTextInField(
          tester, 
          'TestNetwork', 
          find.widgetWithIcon(TextField, Icons.wifi_rounded),
        );

        // Switch tabs
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Form'));
        await tester.pumpAndSettle();

        // Data should be preserved
        expect(find.text('TestNetwork'), findsOneWidget);
      });
    });

    group('Navigation Tests', () {
      testWidgets('navigates back using app bar', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(WiFiQRScreen), findsNothing);
      });

      testWidgets('navigates back after successful save', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill and save form
        await QRTestHelpers.enterTextInField(
          tester, 
          'TestNetwork', 
          find.widgetWithIcon(TextField, Icons.wifi_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          'password123', 
          find.widgetWithIcon(TextField, Icons.lock_rounded),
        );

        await tester.pumpAndSettle();
        await QRTestHelpers.tapButtonAndWait(tester, find.byType(PrimaryGlassButton));

        expect(find.byType(WiFiQRScreen), findsNothing);
      });
    });
  });
}

// Mock classes for testing
class MockUser {
  final String id;
  final String email;
  MockUser({required this.id, required this.email});
}

class MockQRCodeEntity {
  final String id = 'test-qr-id';
  final String name = 'Test QR';
}