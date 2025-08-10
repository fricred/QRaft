import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:qraft/features/qr_generator/presentation/pages/email_qr_screen.dart';
import 'package:qraft/features/qr_generator/presentation/widgets/forms/email_form.dart';
import 'package:qraft/features/qr_generator/presentation/providers/qr_providers.dart';
import 'package:qraft/features/qr_generator/presentation/controllers/qr_customization_controller.dart';
import 'package:qraft/features/qr_generator/domain/use_cases/generate_qr_use_case.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_code_entity.dart';
import 'package:qraft/features/auth/data/providers/supabase_auth_provider.dart';
import 'package:qraft/shared/widgets/glass_button.dart';
import 'package:qraft/l10n/app_localizations.dart';

import '../../test_utilities/qr_test_utilities.dart';

// Mock Classes
class MockGenerateQRUseCase extends Mock implements GenerateQRUseCase {}
class MockSupabaseAuthProvider extends Mock implements SupabaseAuthProvider {}

void main() {
  group('EmailQRScreen Tests', () {
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
      
      // Reset mock external services
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
          home: const EmailQRScreen(),
        ),
      );
    }

    group('Widget Rendering Tests', () {
      testWidgets('renders email QR screen with correct structure', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify main components
        expect(find.byType(EmailQRScreen), findsOneWidget);
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
        expect(find.text('Email QR'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_ios_rounded), findsOneWidget);
      });

      testWidgets('shows form tab by default', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Form should be visible by default
        expect(find.byType(EmailForm), findsOneWidget);
      });

      testWidgets('can switch between form and style tabs', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap on Style tab
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();

        // Should show style customization content
        expect(find.text('Customize your QR'), findsOneWidget);
        
        // Go back to Form tab
        await tester.tap(find.text('Form'));
        await tester.pumpAndSettle();

        expect(find.byType(EmailForm), findsOneWidget);
      });
    });

    group('Email Form Tests', () {
      testWidgets('displays all required form fields', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for form fields
        expect(find.text('QR Code Name *'), findsOneWidget);
        expect(find.text('Email Address *'), findsOneWidget);
        expect(find.text('Subject'), findsOneWidget);
        expect(find.text('Message'), findsOneWidget);
        
        // Check for contact picker button
        expect(find.byIcon(Icons.contacts_rounded), findsOneWidget);
      });

      testWidgets('validates required fields correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Try to save with empty form
        final saveButton = find.byType(PrimaryGlassButton);
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNull);
        
        // Should show validation message
        expect(find.text('Complete the form to save QR code'), findsOneWidget);
      });

      testWidgets('accepts valid form input', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill in required fields
        await QRTestHelpers.enterTextInField(
          tester, 
          'Test Email QR', 
          find.widgetWithText(TextField, 'Email QR').first,
        );
        
        await QRTestHelpers.enterTextInField(
          tester, 
          'test@example.com', 
          find.widgetWithIcon(TextField, Icons.email_outlined),
        );

        await tester.pumpAndSettle();

        // Save button should be enabled
        final saveButton = find.byType(PrimaryGlassButton);
        expect(tester.widget<PrimaryGlassButton>(saveButton).onPressed, isNotNull);
      });

      testWidgets('validates email format correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter valid name first
        await QRTestHelpers.enterTextInField(
          tester, 
          'Test Email QR', 
          find.widgetWithText(TextField, 'Email QR').first,
        );

        // Test invalid email formats
        for (final invalidEmail in QRTestData.invalidEmails) {
          await QRTestHelpers.enterTextInField(
            tester, 
            invalidEmail, 
            find.widgetWithIcon(TextField, Icons.email_outlined),
          );
          await tester.pumpAndSettle();

          if (invalidEmail.isEmpty) {
            QRTestHelpers.expectValidationError('Email address is required');
          } else {
            QRTestHelpers.expectValidationError('Please enter a valid email address');
          }
        }

        // Test valid email formats
        for (final validEmail in QRTestData.validEmails) {
          await QRTestHelpers.enterTextInField(
            tester, 
            validEmail, 
            find.widgetWithIcon(TextField, Icons.email_outlined),
          );
          await tester.pumpAndSettle();

          // Should not show email error
          QRTestHelpers.expectNoValidationError('Please enter a valid email address');
          QRTestHelpers.expectNoValidationError('Email address is required');
        }
      });

      testWidgets('validates QR name correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter valid email
        await QRTestHelpers.enterTextInField(
          tester, 
          'test@example.com', 
          find.widgetWithIcon(TextField, Icons.email_outlined),
        );

        // Test empty name
        await QRTestHelpers.enterTextInField(
          tester, 
          '', 
          find.widgetWithIcon(TextField, Icons.label_outline_rounded),
        );
        await tester.pumpAndSettle();
        QRTestHelpers.expectValidationError('QR code name is required');

        // Test short name
        await QRTestHelpers.enterTextInField(
          tester, 
          'A', 
          find.widgetWithIcon(TextField, Icons.label_outline_rounded),
        );
        await tester.pumpAndSettle();
        QRTestHelpers.expectValidationError('Name must be at least 2 characters');

        // Test valid name
        await QRTestHelpers.enterTextInField(
          tester, 
          'Valid Name', 
          find.widgetWithIcon(TextField, Icons.label_outline_rounded),
        );
        await tester.pumpAndSettle();
        QRTestHelpers.expectNoValidationError('QR code name is required');
        QRTestHelpers.expectNoValidationError('Name must be at least 2 characters');
      });
    });

    group('Contact Picker Integration Tests', () {
      testWidgets('shows contact picker when contacts button is tapped', (tester) async {
        // Setup mock contacts
        MockFlutterContacts.setMockContacts([
          QRTestHelpers.createTestContact(
            name: 'John Doe', 
            emails: ['john@example.com'],
          ),
        ]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap contact picker button
        await tester.tap(find.byIcon(Icons.contacts_rounded));
        await tester.pumpAndSettle();

        // Should show contact selection dialog
        expect(find.text('Select Contact Email'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('john@example.com'), findsOneWidget);
      });

      testWidgets('handles contact permission denied', (tester) async {
        MockFlutterContacts.setPermissionDenied();

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.contacts_rounded));
        await tester.pumpAndSettle();

        QRTestHelpers.expectSnackBar('Contacts permission is required to import email addresses');
      });

      testWidgets('handles no contacts with emails', (tester) async {
        MockFlutterContacts.setMockContacts([]); // Empty contacts list

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.contacts_rounded));
        await tester.pumpAndSettle();

        QRTestHelpers.expectSnackBar('No contacts with email addresses found');
      });

      testWidgets('selects contact email correctly', (tester) async {
        const testEmail = 'selected@example.com';
        MockFlutterContacts.setMockContacts([
          QRTestHelpers.createTestContact(
            name: 'Test Contact', 
            emails: [testEmail],
          ),
        ]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap contact picker
        await tester.tap(find.byIcon(Icons.contacts_rounded));
        await tester.pumpAndSettle();

        // Select the contact
        await tester.tap(find.text(testEmail));
        await tester.pumpAndSettle();

        // Email should be populated in field
        expect(find.text(testEmail), findsOneWidget);
        QRTestHelpers.expectSnackBar('Contact email imported successfully!');
      });
    });

    group('QR Customization Tests', () {
      testWidgets('shows QR preview when form is valid', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill valid form data
        await QRTestHelpers.enterTextInField(
          tester, 
          'Test QR', 
          find.widgetWithIcon(TextField, Icons.label_outline_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          'test@example.com', 
          find.widgetWithIcon(TextField, Icons.email_outlined),
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

      testWidgets('can customize QR colors', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to style tab
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();

        // Should show color customization options
        expect(find.text('Colors'), findsWidgets);
        expect(find.text('QR Color'), findsOneWidget);
        expect(find.text('Background'), findsOneWidget);
        expect(find.text('Eye Color'), findsOneWidget);
      });

      testWidgets('can customize QR size', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to style tab
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();

        // Navigate to Size tab
        await tester.tap(find.text('Size'));
        await tester.pumpAndSettle();

        // Should show size controls
        expect(find.text('QR Code Size'), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);
        expect(find.text('150px'), findsOneWidget);
        expect(find.text('500px'), findsOneWidget);
      });
    });

    group('Logo Management Tests', () {
      testWidgets('can add logo to QR code', (tester) async {
        MockImagePicker.setMockImage('/test/path/logo.png');

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to style tab and logo section
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Logo'));
        await tester.pumpAndSettle();

        // Should show add logo button
        expect(find.text('Add Logo'), findsOneWidget);
        expect(find.text('No Logo'), findsOneWidget);

        // Tap add logo
        await tester.tap(find.text('Add Logo'));
        await tester.pumpAndSettle();

        // Should show success message
        QRTestHelpers.expectSnackBar('Logo updated successfully!');
      });

      testWidgets('handles logo picker errors', (tester) async {
        MockImagePicker.setException(Exception('Permission denied'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to logo section
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Logo'));
        await tester.pumpAndSettle();

        // Tap add logo
        await tester.tap(find.text('Add Logo'));
        await tester.pumpAndSettle();

        // Should show error message
        QRTestHelpers.expectSnackBar('Failed to pick image: Exception: Permission denied');
      });

      testWidgets('can remove logo from QR code', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // First add a logo (simulate existing logo)
        final container = ProviderScope.containerOf(
          tester.element(find.byType(EmailQRScreen)),
        );
        container.read(qrCustomizationControllerProvider.notifier)
            .updateLogo('/test/path/logo.png', 40.0);

        await tester.pump();

        // Switch to logo section
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Logo'));
        await tester.pumpAndSettle();

        // Should show remove button
        expect(find.text('Remove'), findsOneWidget);
        expect(find.text('Logo Added'), findsOneWidget);

        // Remove logo
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        // Should revert to no logo state
        expect(find.text('Add Logo'), findsOneWidget);
        expect(find.text('No Logo'), findsOneWidget);
      });
    });

    group('Save QR Code Tests', () {
      testWidgets('saves QR code successfully with valid data', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill valid form
        await QRTestHelpers.enterTextInField(
          tester, 
          'My Email QR', 
          find.widgetWithIcon(TextField, Icons.label_outline_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          'test@example.com', 
          find.widgetWithIcon(TextField, Icons.email_outlined),
        );

        await tester.pumpAndSettle();

        // Tap save button
        await QRTestHelpers.tapButtonAndWait(tester, find.byType(PrimaryGlassButton));

        // Verify use case was called
        verify(() => mockGenerateQRUseCase.execute(
          name: 'My Email QR',
          type: any(named: 'type'),
          data: any(named: 'data'),
          userId: 'test-user-id',
          customization: any(named: 'customization'),
        )).called(1);

        // Should show success message
        QRTestHelpers.expectSnackBar('QR code "My Email QR" saved successfully!');
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
          'My Email QR', 
          find.widgetWithIcon(TextField, Icons.label_outline_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          'test@example.com', 
          find.widgetWithIcon(TextField, Icons.email_outlined),
        );

        await tester.pumpAndSettle();

        // Tap save button
        await QRTestHelpers.tapButtonAndWait(tester, find.byType(PrimaryGlassButton));

        // Should show error message
        QRTestHelpers.expectSnackBar('Failed to save QR code: Exception: Network error');
      });

      testWidgets('prevents save when user not authenticated', (tester) async {
        when(() => mockAuthProvider.currentUser).thenReturn(null);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill valid form
        await QRTestHelpers.enterTextInField(
          tester, 
          'My Email QR', 
          find.widgetWithIcon(TextField, Icons.label_outline_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          'test@example.com', 
          find.widgetWithIcon(TextField, Icons.email_outlined),
        );

        await tester.pumpAndSettle();

        // Tap save button
        await QRTestHelpers.tapButtonAndWait(tester, find.byType(PrimaryGlassButton));

        // Should show authentication error
        QRTestHelpers.expectSnackBar('Failed to save QR code: Exception: User not authenticated');
      });

      testWidgets('shows loading state during save', (tester) async {
        // Make the use case take some time to complete
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
          'My Email QR', 
          find.widgetWithIcon(TextField, Icons.label_outline_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          'test@example.com', 
          find.widgetWithIcon(TextField, Icons.email_outlined),
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

    group('Navigation Tests', () {
      testWidgets('can navigate back using app bar', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap back button
        await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
        await tester.pumpAndSettle();

        // Screen should be popped (in real app would navigate back)
        expect(find.byType(EmailQRScreen), findsNothing);
      });

      testWidgets('navigates back after successful save', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill and save form
        await QRTestHelpers.enterTextInField(
          tester, 
          'Test QR', 
          find.widgetWithIcon(TextField, Icons.label_outline_rounded),
        );
        await QRTestHelpers.enterTextInField(
          tester, 
          'test@example.com', 
          find.widgetWithIcon(TextField, Icons.email_outlined),
        );

        await tester.pumpAndSettle();
        await QRTestHelpers.tapButtonAndWait(tester, find.byType(PrimaryGlassButton));

        // Should navigate back after successful save
        expect(find.byType(EmailQRScreen), findsNothing);
      });
    });

    group('State Management Integration Tests', () {
      testWidgets('resets form state when screen initializes', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Form should start in clean state
        final emailFormState = ProviderScope.containerOf(
          tester.element(find.byType(EmailQRScreen)),
        ).read(emailFormProvider);
        
        expect(emailFormState.email, isEmpty);
        expect(emailFormState.subject, isEmpty);
        expect(emailFormState.body, isEmpty);
        expect(emailFormState.name, isEmpty);
        expect(emailFormState.isValid, false);
      });

      testWidgets('maintains form state during tab switches', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fill form data
        await QRTestHelpers.enterTextInField(
          tester, 
          'Test Data', 
          find.widgetWithIcon(TextField, Icons.label_outline_rounded),
        );

        // Switch tabs
        await tester.tap(find.text('Style'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Form'));
        await tester.pumpAndSettle();

        // Data should be preserved
        expect(find.text('Test Data'), findsOneWidget);
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