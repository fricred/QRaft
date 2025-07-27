enum QRType {
  personalInfo('Personal Info', 'vcard'),
  url('Website URL', 'url'),
  wifi('WiFi Network', 'wifi'),
  text('Text Message', 'text'),
  email('Email', 'email'),
  location('Location', 'geo');

  const QRType(this.displayName, this.identifier);

  final String displayName;
  final String identifier;
}

extension QRTypeExtension on QRType {
  String get description {
    switch (this) {
      case QRType.personalInfo:
        return 'Contact details\nvCard format';
      case QRType.url:
        return 'Links to websites\nand web pages';
      case QRType.wifi:
        return 'Share WiFi\ncredentials easily';
      case QRType.text:
        return 'Plain text content\nfor any purpose';
      case QRType.email:
        return 'Send email with\npre-filled content';
      case QRType.location:
        return 'GPS coordinates\nand map points';
    }
  }

  String get iconName {
    switch (this) {
      case QRType.personalInfo:
        return 'person_rounded';
      case QRType.url:
        return 'link_rounded';
      case QRType.wifi:
        return 'wifi_rounded';
      case QRType.text:
        return 'text_fields_rounded';
      case QRType.email:
        return 'email_rounded';
      case QRType.location:
        return 'location_on_rounded';
    }
  }

  List<int> get gradientColors {
    switch (this) {
      case QRType.personalInfo:
        return [0xFF00FF88, 0xFF1A73E8];
      case QRType.url:
        return [0xFF1A73E8, 0xFF6366F1];
      case QRType.wifi:
        return [0xFF8B5CF6, 0xFF1A73E8];
      case QRType.text:
        return [0xFFEF4444, 0xFF8B5CF6];
      case QRType.email:
        return [0xFFF59E0B, 0xFFEF4444];
      case QRType.location:
        return [0xFF10B981, 0xFF00FF88];
    }
  }
}