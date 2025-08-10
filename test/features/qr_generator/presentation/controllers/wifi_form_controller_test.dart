import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/qr_generator/presentation/pages/wifi_qr_screen.dart';

void main() {
  group('WiFiFormController Tests', () {
    late WiFiFormController controller;

    setUp(() {
      controller = WiFiFormController();
    });

    group('Network Name Validation', () {
      test('validates empty network name', () {
        controller.updateNetworkName('');
        
        expect(controller.state.networkName, isEmpty);
        expect(controller.state.networkNameError, isNotNull);
        expect(controller.state.isValid, false);
      });

      test('validates network name length', () {
        // Test valid names
        final validNames = ['MyWiFi', 'Home_Network_2024', 'Office-WiFi'];
        for (final validName in validNames) {
          controller.updateNetworkName(validName);
          expect(controller.state.networkNameError, isNull);
        }

        // Test too long name
        controller.updateNetworkName('This_is_a_very_long_network_name_that_exceeds_the_32_character_limit');
        expect(controller.state.networkNameError, isNotNull);
      });
    });

    group('Password Validation', () {
      test('requires password for secured networks', () {
        // Set network name first
        controller.updateNetworkName('TestNetwork');
        
        // For WPA (default), empty password should be invalid
        controller.updatePassword('');
        expect(controller.state.passwordError, isNotNull);
        expect(controller.state.isValid, false);
        
        // Valid password should clear error
        controller.updatePassword('validpassword');
        expect(controller.state.passwordError, isNull);
        expect(controller.state.isValid, true);
      });

      test('does not require password for open network', () {
        controller.updateNetworkName('TestNetwork');
        controller.updateSecurity('nopass');
        
        // Empty password should be fine for open network
        controller.updatePassword('');
        expect(controller.state.passwordError, isNull);
        expect(controller.state.isValid, true);
      });

      test('validates password length', () {
        controller.updateNetworkName('TestNetwork');
        
        // Test too long password
        controller.updatePassword('This_is_an_extremely_long_password_that_exceeds_the_63_character_limit_for_wifi_passwords');
        expect(controller.state.passwordError, isNotNull);
        expect(controller.state.isValid, false);
      });
    });

    group('Security Type Management', () {
      test('updates security type correctly', () {
        expect(controller.state.security, 'WPA'); // Default
        
        controller.updateSecurity('WEP');
        expect(controller.state.security, 'WEP');
        
        controller.updateSecurity('nopass');
        expect(controller.state.security, 'nopass');
      });

      test('clears password error when switching to open network', () {
        controller.updateNetworkName('TestNetwork');
        controller.updatePassword(''); // This creates an error for WPA
        
        expect(controller.state.passwordError, isNotNull);
        
        controller.updateSecurity('nopass');
        expect(controller.state.passwordError, isNull);
      });
    });

    group('Hidden Network Toggle', () {
      test('toggles hidden network setting', () {
        expect(controller.state.hidden, false); // Default
        
        controller.updateHidden(true);
        expect(controller.state.hidden, true);
        
        controller.updateHidden(false);
        expect(controller.state.hidden, false);
      });
    });

    group('WiFi QR Data Generation', () {
      test('generates correct WiFi QR data format', () {
        controller.updateNetworkName('TestNetwork');
        controller.updatePassword('password123');
        controller.updateSecurity('WPA');
        controller.updateHidden(false);
        
        final qrData = controller.state.wifiData.qrData;
        
        // Check basic WiFi QR format
        expect(qrData, startsWith('WIFI:'));
        expect(qrData, endsWith(';;'));
        expect(qrData, contains('T:WPA'));
        expect(qrData, contains('S:TestNetwork'));
        expect(qrData, contains('P:password123'));
        expect(qrData, contains('H:false'));
      });

      test('generates correct QR data for open network', () {
        controller.updateNetworkName('OpenNetwork');
        controller.updateSecurity('nopass');
        controller.updateHidden(true);
        
        final qrData = controller.state.wifiData.qrData;
        
        // Check WiFi QR format for open network
        expect(qrData, startsWith('WIFI:'));
        expect(qrData, endsWith(';;'));
        expect(qrData, contains('T:nopass'));
        expect(qrData, contains('S:OpenNetwork'));
        expect(qrData, contains('P:'));
        expect(qrData, contains('H:true'));
      });

      test('handles special characters in network data', () {
        controller.updateNetworkName('TestNetwork');
        controller.updatePassword('password123');
        
        final qrData = controller.state.wifiData.qrData;
        
        // Basic format check
        expect(qrData, startsWith('WIFI:'));
        expect(qrData, isNotEmpty);
      });
    });

    group('Form Reset', () {
      test('resets form to default state', () {
        // Fill form with data
        controller.updateNetworkName('TestNetwork');
        controller.updatePassword('password123');
        controller.updateSecurity('WEP');
        controller.updateHidden(true);
        
        // Reset
        controller.reset();
        
        // Should be back to defaults
        expect(controller.state.networkName, isEmpty);
        expect(controller.state.password, isEmpty);
        expect(controller.state.security, 'WPA');
        expect(controller.state.hidden, false);
        expect(controller.state.isValid, false);
      });
    });
  });
}