import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/qr_scanner/models/scan_result.dart';

void main() {
  group('ScanResult UUID Fix Tests', () {
    test('should generate proper UUID format for scan result ID', () {
      // Arrange
      const testRawValue = 'https://example.com/test';
      
      // Act
      final scanResult = ScanResult.fromRawValue(testRawValue);
      
      // Assert
      expect(scanResult.id, isNotNull);
      expect(scanResult.id.length, equals(36)); // UUID v4 format length
      expect(scanResult.id.contains('-'), isTrue); // UUIDs contain hyphens
      
      // Verify UUID format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      // ignore: deprecated_member_use
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(uuidRegex.hasMatch(scanResult.id), isTrue, 
        reason: 'Generated ID should be a valid UUID v4: ${scanResult.id}');
      
      debugPrint('✅ Generated valid UUID: ${scanResult.id}');
    });

    test('should generate different UUIDs for each scan result', () {
      // Arrange
      const testRawValue = 'https://example.com/test';
      
      // Act
      final scanResult1 = ScanResult.fromRawValue(testRawValue);
      final scanResult2 = ScanResult.fromRawValue(testRawValue);
      
      // Assert
      expect(scanResult1.id, isNot(equals(scanResult2.id)));
      debugPrint('✅ UUID 1: ${scanResult1.id}');
      debugPrint('✅ UUID 2: ${scanResult2.id}');
    });

    test('should parse QR data correctly with UUID', () {
      // Arrange
      const testRawValue = 'https://github.com/test';
      
      // Act
      final scanResult = ScanResult.fromRawValue(testRawValue);
      
      // Assert
      expect(scanResult.rawValue, equals(testRawValue));
      expect(scanResult.type, equals(QRCodeType.url));
      expect(scanResult.displayValue, equals('github.com/test'));
      expect(scanResult.scannedAt, isNotNull);
      
      debugPrint('✅ Scan result with UUID ${scanResult.id}:');
      debugPrint('   Raw: ${scanResult.rawValue}');
      debugPrint('   Type: ${scanResult.type}');
      debugPrint('   Display: ${scanResult.displayValue}');
    });
  });
}