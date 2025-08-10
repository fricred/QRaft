import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:qraft/features/qr_generator/domain/entities/qr_code_entity.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_type.dart';

// Mock Classes for QR Form Testing
class MockFlutterContacts extends Mock {
  static bool mockPermissionGranted = true;
  static List<Contact> mockContacts = [];
  
  static Future<bool> requestPermission() async => mockPermissionGranted;
  
  static Future<List<Contact>> getContacts({
    bool withProperties = false,
    bool withAccounts = false,
  }) async => mockContacts;
  
  static void reset() {
    mockPermissionGranted = true;
    mockContacts = [];
  }
  
  static void setMockContacts(List<Contact> contacts) {
    mockContacts = contacts;
  }
  
  static void setPermissionDenied() {
    mockPermissionGranted = false;
  }
}

class MockGeolocator extends Mock {
  static bool mockServiceEnabled = true;
  static LocationPermission mockPermission = LocationPermission.always;
  static Position? mockPosition;
  static Exception? mockException;
  
  static Future<bool> isLocationServiceEnabled() async => mockServiceEnabled;
  
  static Future<LocationPermission> checkPermission() async => mockPermission;
  
  static Future<LocationPermission> requestPermission() async => mockPermission;
  
  static Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
    LocationAccuracy? desiredAccuracy,
    Duration? timeLimit,
  }) async {
    if (mockException != null) {
      throw mockException!;
    }
    return mockPosition ?? _defaultPosition;
  }
  
  static void reset() {
    mockServiceEnabled = true;
    mockPermission = LocationPermission.always;
    mockPosition = null;
    mockException = null;
  }
  
  static void setLocationDisabled() {
    mockServiceEnabled = false;
  }
  
  static void setPermissionDenied() {
    mockPermission = LocationPermission.denied;
  }
  
  static void setPermissionDeniedForever() {
    mockPermission = LocationPermission.deniedForever;
  }
  
  static void setMockPosition(double latitude, double longitude) {
    mockPosition = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }
  
  static void setLocationException(Exception exception) {
    mockException = exception;
  }
  
  static Position get _defaultPosition => Position(
    latitude: 40.7128,
    longitude: -74.0060,
    timestamp: DateTime.now(),
    accuracy: 5.0,
    altitude: 0.0,
    heading: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  );
}

class MockImagePicker extends Mock implements ImagePicker {
  static XFile? mockImage;
  static Exception? mockException;
  
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (mockException != null) {
      throw mockException!;
    }
    return mockImage;
  }
  
  static void reset() {
    mockImage = null;
    mockException = null;
  }
  
  static void setMockImage(String path) {
    mockImage = XFile(path);
  }
  
  static void setException(Exception exception) {
    mockException = exception;
  }
}

// Mock classes for QR testing
class MockUser extends Mock implements User {
  final String _id;
  final String? _email;

  MockUser({required String id, String? email}) 
    : _id = id, _email = email;

  @override
  String get id => _id;

  @override
  String? get email => _email;
}

class MockQRCodeEntity extends Mock implements QRCodeEntity {
  final String _id;
  final String _name;
  final QRType _type;
  final String _data;
  final String _displayData;
  final QRCustomization _customization;
  final DateTime _createdAt;
  final DateTime _updatedAt;
  final String _userId;

  MockQRCodeEntity({
    String? id,
    String? name,
    QRType? type,
    String? data,
    String? displayData,
    QRCustomization? customization,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) : _id = id ?? 'test-qr-id',
       _name = name ?? 'Test QR',
       _type = type ?? QRType.text,
       _data = data ?? 'test-data',
       _displayData = displayData ?? 'Test QR Data',
       _customization = customization ?? const QRCustomization(),
       _createdAt = createdAt ?? DateTime.now(),
       _updatedAt = updatedAt ?? DateTime.now(),
       _userId = userId ?? 'test-user-id';

  @override
  String get id => _id;

  @override
  String get name => _name;

  @override
  QRType get type => _type;

  @override
  String get data => _data;

  @override
  String get displayData => _displayData;

  @override
  QRCustomization get customization => _customization;

  @override
  DateTime get createdAt => _createdAt;

  @override
  DateTime get updatedAt => _updatedAt;

  @override
  String get userId => _userId;
}

// Test Helper Functions
class QRTestHelpers {
  /// Creates a test contact with email
  static Contact createTestContact({
    required String name,
    required List<String> emails,
  }) {
    final contact = Contact();
    contact.displayName = name;
    contact.emails = emails.map((email) {
      final emailObj = Email('');
      emailObj.address = email;
      return emailObj;
    }).toList();
    return contact;
  }
  
  /// Creates a provider container with overrides for testing
  static ProviderContainer createTestContainer([List<Override>? overrides]) {
    return ProviderContainer(overrides: overrides ?? []);
  }
  
  /// Creates a test widget wrapped with necessary providers
  static Widget createTestWidget(Widget child, [List<Override>? overrides]) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }
  
  /// Creates a test widget with full localization support
  static Widget createTestWidgetWithLocalization(Widget child, [List<Override>? overrides]) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        localizationsDelegates: const [],
        supportedLocales: const [Locale('en', 'US')],
        home: Scaffold(body: child),
      ),
    );
  }
  
  /// Simulates text input in a text field
  static Future<void> enterTextInField(
    WidgetTester tester, 
    String text, 
    Finder fieldFinder,
  ) async {
    await tester.tap(fieldFinder);
    await tester.enterText(fieldFinder, text);
    await tester.pump();
  }
  
  /// Waits for all animations and async operations to complete
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pump();
    await tester.pumpAndSettle();
  }
  
  /// Simulates a button tap and waits for response
  static Future<void> tapButtonAndWait(WidgetTester tester, Finder buttonFinder) async {
    await tester.tap(buttonFinder);
    await pumpAndSettle(tester);
  }
  
  /// Finds a text field by its label
  static Finder findTextFieldByLabel(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(TextField),
    );
  }
  
  /// Verifies form validation error is shown
  static void expectValidationError(String errorText) {
    expect(find.text(errorText), findsOneWidget);
  }
  
  /// Verifies form validation error is not shown
  static void expectNoValidationError(String errorText) {
    expect(find.text(errorText), findsNothing);
  }
  
  /// Verifies a snackbar with specific message is shown
  static void expectSnackBar(String message) {
    expect(find.text(message), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  }
  
}

/// Common test data for validation testing
class QRTestData {
    // Email test data
    static const validEmails = [
      'test@example.com',
      'user.name@domain.co.uk',
      'test+tag@gmail.com',
    ];
    
    static const invalidEmails = [
      '',
      'invalid-email',
      '@domain.com',
      'user@',
      'user name@domain.com',
    ];
    
    // WiFi test data
    static const validNetworkNames = [
      'MyWiFi',
      'Home_Network_2024',
      'Office-WiFi',
    ];
    
    static const invalidNetworkNames = [
      '',
      'A', // too short
      'This_is_a_very_long_network_name_that_exceeds_the_32_character_limit',
    ];
    
    static const validPasswords = [
      'password123',
      'MySecureP@ssw0rd!',
      '12345678',
    ];
    
    static const invalidPasswords = [
      '', // empty for secured networks
      'This_is_an_extremely_long_password_that_exceeds_the_63_character_limit_for_wifi_passwords',
    ];
    
    // Location test data
    static const validLatitudes = [40.7128, -34.6037, 0.0, 90.0, -90.0];
    static const invalidLatitudes = [91.0, -91.0, 180.0];
    
    static const validLongitudes = [-74.0060, 151.2093, 0.0, 180.0, -180.0];
    static const invalidLongitudes = [181.0, -181.0, 360.0];
    
    static const validLocationNames = [
      'Home',
      'Office Building',
      'Central Park',
    ];
    
    static const invalidLocationNames = [
      '',
      'A', // too short
    ];
  }
}

// Custom matchers for QR-specific testing
class QRMatchers {
  /// Matcher for verifying QR data format
  static Matcher isValidQRData() => _IsValidQRDataMatcher();
  
  /// Matcher for email QR format: mailto:email@domain.com?subject=...&body=...
  static Matcher isEmailQRFormat() => _IsEmailQRFormatMatcher();
  
  /// Matcher for WiFi QR format: WIFI:T:WPA;S:NetworkName;P:password;;
  static Matcher isWiFiQRFormat() => _IsWiFiQRFormatMatcher();
  
  /// Matcher for location QR format: geo:latitude,longitude
  static Matcher isLocationQRFormat() => _IsLocationQRFormatMatcher();
}

class _IsValidQRDataMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    return item is String && item.isNotEmpty && item.length <= 4296; // QR code limit
  }
  
  @override
  Description describe(Description description) => 
      description.add('a valid QR code data string');
}

class _IsEmailQRFormatMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! String) return false;
    final emailPattern = RegExp(r'^mailto:[^@]+@[^@]+\.[a-zA-Z]{2,}');
    return emailPattern.hasMatch(item);
  }
  
  @override
  Description describe(Description description) => 
      description.add('a valid email QR code format (mailto:...)');
}

class _IsWiFiQRFormatMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! String) return false;
    final wifiPattern = RegExp(r'^WIFI:T:[^;]*;S:[^;]*;P:[^;]*;H:[^;]*;;$');
    return wifiPattern.hasMatch(item);
  }
  
  @override
  Description describe(Description description) => 
      description.add('a valid WiFi QR code format (WIFI:...)');
}

class _IsLocationQRFormatMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! String) return false;
    final locationPattern = RegExp(r'^geo:-?\d+\.?\d*,-?\d+\.?\d*');
    return locationPattern.hasMatch(item);
  }
  
  @override
  Description describe(Description description) => 
      description.add('a valid location QR code format (geo:lat,lng)');
}

// Test Configuration
class QRTestConfig {
  static const Duration defaultTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(seconds: 10);
  static const Duration animationTimeout = Duration(milliseconds: 500);
  
  static const testContactsPermissionTimeout = Duration(seconds: 3);
  static const testLocationPermissionTimeout = Duration(seconds: 3);
  static const testImagePickerTimeout = Duration(seconds: 3);
}