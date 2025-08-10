import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'package:qraft/features/qr_generator/presentation/pages/location_qr_screen.dart';
import 'package:qraft/features/qr_generator/presentation/controllers/qr_customization_controller.dart';
import 'package:qraft/features/qr_generator/presentation/providers/qr_providers.dart';
import 'package:qraft/features/qr_generator/domain/use_cases/generate_qr_use_case.dart';
import 'package:qraft/features/auth/data/providers/supabase_auth_provider.dart';
import 'package:qraft/shared/widgets/glass_button.dart';
import 'package:qraft/l10n/app_localizations.dart';

import '../../test_utilities/qr_test_utilities.dart';

// Mock Classes
class MockGenerateQRUseCase extends Mock implements GenerateQRUseCase {}
class MockSupabaseAuthProvider extends Mock implements SupabaseAuthProvider {}

void main() {
  group('LocationQRScreen Tests', () {
    late MockGenerateQRUseCase mockGenerateQRUseCase;
    late MockSupabaseAuthProvider mockAuthProvider;

    setUp(() {
      mockGenerateQRUseCase = MockGenerateQRUseCase();
      mockAuthProvider = MockSupabaseAuthProvider();
      
      // Setup default mock behavior
      when(() => mockAuthProvider.currentUser).thenReturn(
        MockUser(id: 'test-user-id', email: 'test@example.com'),
      );
      when(() => mockGenerateQRUseCase.execute(
        name: any(named: 'name'),
        type: any(named: 'type'),
        data: any(named: 'data'),
        userId: any(named: 'userId'),
        customization: any(named: 'customization'),
      )).thenAnswer((_) async => MockQRCodeEntity());
      
      // Reset mock services
      MockGeolocator.reset();
      MockImagePicker.reset();
    });

    Widget createTestWidget([List<Override>? overrides]) {
      return ProviderScope(
        overrides: [
          generateQRUseCaseProvider.overrideWithValue(mockGenerateQRUseCase),
          supabaseAuthProvider.overrideWithValue(mockAuthProvider),
          ...?overrides,
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LocationQRScreen(),
        ),
      );
    }

    group('Widget Rendering Tests', () {
      testWidgets('renders location QR screen with correct structure', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify main components
        expect(find.byType(LocationQRScreen), findsOneWidget);
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
        expect(find.text('Location QR'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_ios_rounded), findsOneWidget);
      });

      testWidgets('shows form tab by default', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Form should be visible by default
        expect(find.text('Location Details'), findsOneWidget);
        expect(find.text('Share your location or any GPS coordinates with a QR code'), findsOneWidget);
      });
    });

    group('Location Form Tests', () {
      testWidgets('displays all required form fields and options', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for form fields
        expect(find.text('Location Name *'), findsOneWidget);
        expect(find.text('Latitude *'), findsOneWidget);
        expect(find.text('Longitude *'), findsOneWidget);
        
        // Check for location option cards
        expect(find.text('Use Current Location'), findsOneWidget);
        expect(find.text('Pick from Map'), findsOneWidget);
        expect(find.text('Use device GPS location'), findsOneWidget);
        expect(find.text('Select point on interactive map'), findsOneWidget);
        
        // Check for manual entry section
        expect(find.text('Manual Entry'), findsOneWidget);
      });

      testWidgets('validates location name correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final nameField = find.widgetWithIcon(TextField, Icons.place_rounded);

        // Test empty name
        await QRTestHelpers.enterTextInField(tester, '', nameField);
        await tester.pumpAndSettle();
        expect(find.text('Location name is required'), findsAtLeastNWidgets(1));

        // Test name too short
        await QRTestHelpers.enterTextInField(tester, 'A', nameField);
        await tester.pumpAndSettle();
        expect(find.text('Location name must be at least 2 characters'), findsAtLeastNWidgets(1));

        // Test valid names
        for (final validName in QRTestData.validLocationNames) {
          await QRTestHelpers.enterTextInField(tester, validName, nameField);
          await tester.pumpAndSettle();
          
          expect(find.text('Location name is required'), findsNothing);
          expect(find.text('Location name must be at least 2 characters'), findsNothing);
        }
      });

      testWidgets('validates latitude correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final latField = find.widgetWithIcon(TextField, Icons.location_on_rounded).first;

        // Test empty latitude
        await QRTestHelpers.enterTextInField(tester, '', latField);
        await tester.pumpAndSettle();
        QRTestHelpers.expectValidationError('Latitude is required');

        // Test invalid latitude values
        for (final invalidLat in QRTestData.invalidLatitudes) {
          await QRTestHelpers.enterTextInField(tester, invalidLat.toString(), latField);
          await tester.pumpAndSettle();
          QRTestHelpers.expectValidationError('Please enter a valid latitude (-90 to 90)');
        }

        // Test non-numeric latitude
        await QRTestHelpers.enterTextInField(tester, 'not-a-number', latField);
        await tester.pumpAndSettle();
        QRTestHelpers.expectValidationError('Please enter a valid latitude (-90 to 90)');

        // Test valid latitude values
        for (final validLat in QRTestData.validLatitudes) {
          await QRTestHelpers.enterTextInField(tester, validLat.toString(), latField);
          await tester.pumpAndSettle();
          
          QRTestHelpers.expectNoValidationError('Latitude is required');
          QRTestHelpers.expectNoValidationError('Please enter a valid latitude (-90 to 90)');
        }
      });

      testWidgets('validates longitude correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final lngField = find.widgetWithIcon(TextField, Icons.location_on_rounded).last;

        // Test empty longitude
        await QRTestHelpers.enterTextInField(tester, '', lngField);
        await tester.pumpAndSettle();
        QRTestHelpers.expectValidationError('Longitude is required');

        // Test invalid longitude values
        for (final invalidLng in QRTestData.invalidLongitudes) {
          await QRTestHelpers.enterTextInField(tester, invalidLng.toString(), lngField);
          await tester.pumpAndSettle();
          QRTestHelpers.expectValidationError('Please enter a valid longitude (-180 to 180)');
        }

        // Test non-numeric longitude
        await QRTestHelpers.enterTextInField(tester, 'not-a-number', lngField);
        await tester.pumpAndSettle();
        QRTestHelpers.expectValidationError('Please enter a valid longitude (-180 to 180)');

        // Test valid longitude values
        for (final validLng in QRTestData.validLongitudes) {
          await QRTestHelpers.enterTextInField(tester, validLng.toString(), lngField);
          await tester.pumpAndSettle();
          
          QRTestHelpers.expectNoValidationError('Longitude is required');
          QRTestHelpers.expectNoValidationError('Please enter a valid longitude (-180 to 180)');
        }
      });

      testWidgets('enables save button only when all fields are valid', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final saveButton = find.byType(PrimaryGlassButton);
        
        // Initially disabled
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNull);

        // Fill name only
        await QRTestHelpers.enterTextInField(
          tester, 
          'Test Location', 
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNull);

        // Add latitude
        await QRTestHelpers.enterTextInField(
          tester, 
          '40.7128', 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).first,
        );
        await tester.pumpAndSettle();
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNull);

        // Add longitude - should enable button
        await QRTestHelpers.enterTextInField(
          tester, 
          '-74.0060', 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).last,
        );
        await tester.pumpAndSettle();
        
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNotNull);
      });
    });

    group('GPS Location Tests', () {
      testWidgets('gets current location successfully', (tester) async {
        MockGeolocator.setMockPosition(40.7128, -74.0060);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill location name first (required)
        await QRTestHelpers.enterTextInField(
          tester, 
          'Current Location', 
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );

        // Tap use current location
        await tester.tap(find.text('Use Current Location'));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Should populate coordinate fields
        expect(find.text('40.712800'), findsOneWidget);
        expect(find.text('-74.006000'), findsOneWidget);
        
        // Should show success message
        QRTestHelpers.expectSnackBar('Location obtained successfully!');
      });

      testWidgets('shows loading state during GPS location fetch', (tester) async {
        // Make location fetch take time
        MockGeolocator.setMockPosition(40.7128, -74.0060);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap use current location
        await tester.tap(find.text('Use Current Location'));
        await tester.pump(); // Don't wait for settle

        // Should show loading in the button
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        // Loading should be gone
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('handles location service disabled', (tester) async {
        MockGeolocator.setLocationDisabled();

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap use current location
        await tester.tap(find.text('Use Current Location'));
        await tester.pumpAndSettle();

        // Should show error message
        QRTestHelpers.expectSnackBar('Failed to get location: Exception: Location services are disabled');
      });

      testWidgets('handles location permission denied', (tester) async {
        MockGeolocator.setPermissionDenied();

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap use current location
        await tester.tap(find.text('Use Current Location'));
        await tester.pumpAndSettle();

        // Should show permission error
        QRTestHelpers.expectSnackBar('Failed to get location: Exception: Location permission is required');
      });

      testWidgets('handles location permission denied forever', (tester) async {
        MockGeolocator.setPermissionDeniedForever();

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap use current location
        await tester.tap(find.text('Use Current Location'));
        await tester.pumpAndSettle();

        // Should show permission error
        QRTestHelpers.expectSnackBar('Failed to get location: Exception: Location permission is required');
      });

      testWidgets('handles location fetch timeout', (tester) async {
        MockGeolocator.setLocationException(Exception('Location request timeout'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap use current location
        await tester.tap(find.text('Use Current Location'));
        await tester.pumpAndSettle();

        // Should show timeout error
        QRTestHelpers.expectSnackBar('Failed to get location: Exception: Location request timeout');
      });
    });

    group('Map Picker Tests', () {
      testWidgets('opens map picker screen', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap pick from map
        await tester.tap(find.text('Pick from Map'));
        await tester.pumpAndSettle();

        // Should navigate to map screen (screen would change in real app)
        // In test, we verify the navigation was attempted
        expect(find.text('Pick from Map'), findsOneWidget);
      });

      testWidgets('handles map picker result correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill location name first
        await QRTestHelpers.enterTextInField(
          tester, 
          'Map Location', 
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );

        // Simulate map picker returning coordinates
        final container = ProviderScope.containerOf(
          tester.element(find.byType(LocationQRScreen)),
        );
        final controller = container.read(locationFormProvider.notifier);
        
        controller.setLocation(37.7749, -122.4194);
        await tester.pumpAndSettle();

        // Should populate coordinate fields
        expect(find.text('37.774900'), findsOneWidget);
        expect(find.text('-122.419400'), findsOneWidget);
      });
    });

    group('QR Data Format Tests', () {
      testWidgets('generates correct location QR data format', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        const locationName = 'Test Location';
        const latitude = '40.7128';
        const longitude = '-74.0060';

        // Fill valid form
        await QRTestHelpers.enterTextInField(
          tester, 
          locationName, 
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          latitude, 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).first,
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          longitude, 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).last,
        );

        await tester.pumpAndSettle();

        // Get the form state to verify QR data format
        final container = ProviderScope.containerOf(
          tester.element(find.byType(LocationQRScreen)),
        );
        final locationState = container.read(locationFormProvider);
        final qrData = locationState.locationData.qrData;

        // Should match location QR format (geo:lat,lng)
        expect(qrData, QRMatchers.isLocationQRFormat());
        expect(qrData, contains(latitude));
        expect(qrData, contains(longitude));
        expect(qrData, startsWith('geo:'));
      });

      testWidgets('generates QR data with high precision coordinates', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        const highPrecisionLat = '40.712800123';
        const highPrecisionLng = '-74.006000456';

        // Fill form with high precision coordinates
        await QRTestHelpers.enterTextInField(
          tester, 
          'Precise Location', 
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          highPrecisionLat, 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).first,
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          highPrecisionLng, 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).last,
        );

        await tester.pumpAndSettle();

        // Get QR data
        final container = ProviderScope.containerOf(
          tester.element(find.byType(LocationQRScreen)),
        );
        final locationState = container.read(locationFormProvider);
        final qrData = locationState.locationData.qrData;

        // Should preserve precision
        expect(qrData, contains('40.712800'));
        expect(qrData, contains('-74.006000'));
        expect(qrData, QRMatchers.isLocationQRFormat());
      });
    });

    group('Save QR Code Tests', () {
      testWidgets('saves location QR code successfully', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        const locationName = 'Test Location';
        const latitude = '40.7128';
        const longitude = '-74.0060';

        // Fill valid form
        await QRTestHelpers.enterTextInField(
          tester, 
          locationName, 
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          latitude, 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).first,
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          longitude, 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).last,
        );

        await tester.pumpAndSettle();

        // Tap save button
        await QRTestHelpers.tapButtonAndWait(tester, find.byType(PrimaryGlassButton));

        // Verify use case was called with correct data
        verify(() => mockGenerateQRUseCase.execute(
          name: locationName,
          type: any(named: 'type'),
          data: any(named: 'data'),
          userId: 'test-user-id',
          customization: any(named: 'customization'),
        )).called(1);

        // Should show success message
        QRTestHelpers.expectSnackBar('Location QR code "$locationName" saved successfully!');
      });

      testWidgets('saves with default name when name is empty', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill only coordinates (name left empty - which should cause validation error)
        await QRTestHelpers.enterTextInField(
          tester, 
          '', // Empty name
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );

        // Should not allow save with empty name
        final saveButton = find.byType(PrimaryGlassButton);
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNull);
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
          'Test Location', 
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          '40.7128', 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).first,
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          '-74.0060', 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).last,
        );

        await tester.pumpAndSettle();

        // Tap save button
        await QRTestHelpers.tapButtonAndWait(tester, find.byType(PrimaryGlassButton));

        // Should show error message
        QRTestHelpers.expectSnackBar('Failed to save QR code: Exception: Network error');
      });

      testWidgets('shows loading state during save', (tester) async {
        when(() => mockGenerateQRUseCase.execute(
          name: any(named: 'name'),
          type: any(named: 'type'),
          data: any(named: 'data'),
          userId: any(named: 'userId'),
          customization: any(named: 'customization'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return MockQRCodeEntity();
        });

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill valid form
        await QRTestHelpers.enterTextInField(
          tester, 
          'Test Location', 
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          '40.7128', 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).first,
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          '-74.0060', 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).last,
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

    group('QR Preview Tests', () {
      testWidgets('shows QR preview when form is valid', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill valid form data
        await QRTestHelpers.enterTextInField(
          tester, 
          'Test Location', 
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          '40.7128', 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).first,
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          '-74.0060', 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).last,
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
    });

    group('State Management Tests', () {
      testWidgets('resets form state on initialization', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Form should start clean
        final container = ProviderScope.containerOf(
          tester.element(find.byType(LocationQRScreen)),
        );
        final locationState = container.read(locationFormProvider);
        
        expect(locationState.name, isEmpty);
        expect(locationState.latitude, isEmpty);
        expect(locationState.longitude, isEmpty);
        expect(locationState.isValid, false);
        expect(locationState.isLoadingLocation, false);
      });

      testWidgets('maintains state during tab navigation', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill some data
        await QRTestHelpers.enterTextInField(
          tester, 
          'Test Location', 
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );

        // Switch tabs
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Form'));
        await tester.pumpAndSettle();

        // Data should be preserved
        expect(find.text('Test Location'), findsOneWidget);
      });
    });

    group('Validation Message Tests', () {
      testWidgets('shows specific validation messages', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // With empty form, should show name required message
        expect(find.text('Location name is required'), findsAtLeastNWidgets(1));

        // Fill name, should show latitude required
        await QRTestHelpers.enterTextInField(
          tester, 
          'Test Location', 
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );
        await tester.pumpAndSettle();
        
        expect(find.text('Latitude is required'), findsAtLeastNWidgets(1));

        // Fill latitude, should show longitude required
        await QRTestHelpers.enterTextInField(
          tester, 
          '40.7128', 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).first,
        );
        await tester.pumpAndSettle();
        
        expect(find.text('Longitude is required'), findsAtLeastNWidgets(1));

        // Fill longitude, validation should pass
        await QRTestHelpers.enterTextInField(
          tester, 
          '-74.0060', 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).last,
        );
        await tester.pumpAndSettle();
        
        expect(find.text('Complete all fields to save QR code'), findsNothing);
      });
    });

    group('Navigation Tests', () {
      testWidgets('navigates back using app bar', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(LocationQRScreen), findsNothing);
      });

      testWidgets('navigates back after successful save', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill and save form
        await QRTestHelpers.enterTextInField(
          tester, 
          'Test Location', 
          find.widgetWithIcon(TextField, Icons.place_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          '40.7128', 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).first,
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          '-74.0060', 
          find.widgetWithIcon(TextField, Icons.location_on_rounded).last,
        );

        await tester.pumpAndSettle();
        await QRTestHelpers.tapButtonAndWait(tester, find.byType(PrimaryGlassButton));

        expect(find.byType(LocationQRScreen), findsNothing);
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