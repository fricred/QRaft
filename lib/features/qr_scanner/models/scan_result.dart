import 'package:equatable/equatable.dart';

/// Represents different types of QR code content
enum QRCodeType {
  url,
  text,
  wifi,
  email,
  sms,
  phone,
  vcard,
  location,
  unknown,
}

/// Model for QR scan results
class ScanResult extends Equatable {
  final String id;
  final String rawValue;
  final QRCodeType type;
  final String displayValue;
  final Map<String, dynamic>? parsedData;
  final DateTime scannedAt;

  const ScanResult({
    required this.id,
    required this.rawValue,
    required this.type,
    required this.displayValue,
    this.parsedData,
    required this.scannedAt,
  });

  /// Factory constructor to create ScanResult from raw QR data
  factory ScanResult.fromRawValue(String rawValue) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final scannedAt = DateTime.now();
    
    // Determine QR code type and parse data
    final type = _determineQRType(rawValue);
    final parsedData = _parseQRData(rawValue, type);
    final displayValue = _getDisplayValue(rawValue, type, parsedData);

    return ScanResult(
      id: id,
      rawValue: rawValue,
      type: type,
      displayValue: displayValue,
      parsedData: parsedData,
      scannedAt: scannedAt,
    );
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'raw_value': rawValue,
      'type': _getTypeName(type),
      'display_value': displayValue,
      'parsed_data': parsedData,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }

  /// Helper method to get enum name as string
  static String _getTypeName(QRCodeType type) {
    switch (type) {
      case QRCodeType.url:
        return 'url';
      case QRCodeType.text:
        return 'text';
      case QRCodeType.wifi:
        return 'wifi';
      case QRCodeType.email:
        return 'email';
      case QRCodeType.sms:
        return 'sms';
      case QRCodeType.phone:
        return 'phone';
      case QRCodeType.vcard:
        return 'vcard';
      case QRCodeType.location:
        return 'location';
      case QRCodeType.unknown:
        return 'unknown';
    }
  }

  /// Create from JSON from database
  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'],
      rawValue: json['raw_value'],
      type: _getTypeFromName(json['type']),
      displayValue: json['display_value'],
      parsedData: json['parsed_data'] as Map<String, dynamic>?,
      scannedAt: DateTime.parse(json['scanned_at']),
    );
  }

  /// Helper method to get enum from string name
  static QRCodeType _getTypeFromName(String typeName) {
    switch (typeName) {
      case 'url':
        return QRCodeType.url;
      case 'text':
        return QRCodeType.text;
      case 'wifi':
        return QRCodeType.wifi;
      case 'email':
        return QRCodeType.email;
      case 'sms':
        return QRCodeType.sms;
      case 'phone':
        return QRCodeType.phone;
      case 'vcard':
        return QRCodeType.vcard;
      case 'location':
        return QRCodeType.location;
      case 'unknown':
      default:
        return QRCodeType.unknown;
    }
  }

  /// Determine QR code type from raw value
  static QRCodeType _determineQRType(String rawValue) {
    final value = rawValue.toLowerCase();
    
    // URL detection
    if (value.startsWith('http://') || value.startsWith('https://') || 
        value.startsWith('www.') || value.contains('.com') || 
        value.contains('.org') || value.contains('.net')) {
      return QRCodeType.url;
    }
    
    // WiFi detection
    if (value.startsWith('wifi:')) {
      return QRCodeType.wifi;
    }
    
    // Email detection
    if (value.startsWith('mailto:') || value.contains('@') && value.contains('.')) {
      return QRCodeType.email;
    }
    
    // SMS detection
    if (value.startsWith('sms:') || value.startsWith('smsto:')) {
      return QRCodeType.sms;
    }
    
    // Phone detection
    if (value.startsWith('tel:') || RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(rawValue)) {
      return QRCodeType.phone;
    }
    
    // vCard detection
    if (value.startsWith('begin:vcard')) {
      return QRCodeType.vcard;
    }
    
    // Location detection
    if (value.startsWith('geo:') || value.startsWith('google.com/maps')) {
      return QRCodeType.location;
    }
    
    return QRCodeType.text;
  }

  /// Parse QR data based on type
  static Map<String, dynamic>? _parseQRData(String rawValue, QRCodeType type) {
    switch (type) {
      case QRCodeType.wifi:
        return _parseWiFiData(rawValue);
      case QRCodeType.vcard:
        return _parseVCardData(rawValue);
      case QRCodeType.location:
        return _parseLocationData(rawValue);
      case QRCodeType.email:
        return _parseEmailData(rawValue);
      case QRCodeType.sms:
        return _parseSMSData(rawValue);
      case QRCodeType.phone:
        return _parsePhoneData(rawValue);
      default:
        return null;
    }
  }

  /// Get display-friendly value
  static String _getDisplayValue(String rawValue, QRCodeType type, Map<String, dynamic>? parsedData) {
    switch (type) {
      case QRCodeType.wifi:
        return parsedData?['ssid'] ?? 'WiFi Network';
      case QRCodeType.email:
        return parsedData?['email'] ?? rawValue;
      case QRCodeType.phone:
        return parsedData?['number'] ?? rawValue;
      case QRCodeType.url:
        // Clean up URL for display
        String url = rawValue;
        if (url.startsWith('http://')) url = url.substring(7);
        if (url.startsWith('https://')) url = url.substring(8);
        if (url.startsWith('www.')) url = url.substring(4);
        return url;
      case QRCodeType.vcard:
        return parsedData?['name'] ?? 'Contact Card';
      case QRCodeType.location:
        return 'Location: ${parsedData?['latitude']}, ${parsedData?['longitude']}';
      default:
        return rawValue.length > 50 ? '${rawValue.substring(0, 50)}...' : rawValue;
    }
  }

  // Parsing methods for different QR types
  static Map<String, dynamic> _parseWiFiData(String rawValue) {
    final data = <String, dynamic>{};
    final parts = rawValue.substring(5).split(';'); // Remove 'WIFI:'
    
    for (final part in parts) {
      if (part.contains(':')) {
        final keyValue = part.split(':');
        if (keyValue.length >= 2) {
          final key = keyValue[0].toLowerCase();
          final value = keyValue.sublist(1).join(':');
          
          switch (key) {
            case 't':
              data['security'] = value;
              break;
            case 's':
              data['ssid'] = value;
              break;
            case 'p':
              data['password'] = value;
              break;
            case 'h':
              data['hidden'] = value == 'true';
              break;
          }
        }
      }
    }
    
    return data;
  }

  static Map<String, dynamic> _parseVCardData(String rawValue) {
    final data = <String, dynamic>{};
    final lines = rawValue.split('\n');
    
    for (final line in lines) {
      if (line.startsWith('FN:')) {
        data['name'] = line.substring(3);
      } else if (line.startsWith('TEL:')) {
        data['phone'] = line.substring(4);
      } else if (line.startsWith('EMAIL:')) {
        data['email'] = line.substring(6);
      } else if (line.startsWith('ORG:')) {
        data['organization'] = line.substring(4);
      }
    }
    
    return data;
  }

  static Map<String, dynamic> _parseLocationData(String rawValue) {
    final data = <String, dynamic>{};
    
    if (rawValue.startsWith('geo:')) {
      final coords = rawValue.substring(4).split(',');
      if (coords.length >= 2) {
        data['latitude'] = double.tryParse(coords[0]);
        data['longitude'] = double.tryParse(coords[1]);
      }
    }
    
    return data;
  }

  static Map<String, dynamic> _parseEmailData(String rawValue) {
    final data = <String, dynamic>{};
    
    if (rawValue.startsWith('mailto:')) {
      final email = rawValue.substring(7);
      data['email'] = email.split('?')[0]; // Remove query parameters
    } else {
      data['email'] = rawValue;
    }
    
    return data;
  }

  static Map<String, dynamic> _parseSMSData(String rawValue) {
    final data = <String, dynamic>{};
    
    if (rawValue.startsWith('sms:') || rawValue.startsWith('smsto:')) {
      final parts = rawValue.split(':')[1].split('?');
      data['number'] = parts[0];
      if (parts.length > 1) {
        data['body'] = parts[1].replaceFirst('body=', '');
      }
    }
    
    return data;
  }

  static Map<String, dynamic> _parsePhoneData(String rawValue) {
    final data = <String, dynamic>{};
    
    if (rawValue.startsWith('tel:')) {
      data['number'] = rawValue.substring(4);
    } else {
      data['number'] = rawValue;
    }
    
    return data;
  }

  @override
  List<Object?> get props => [id, rawValue, type, displayValue, parsedData, scannedAt];
}