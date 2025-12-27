import 'package:equatable/equatable.dart';

/// Types of features that can be gated
enum FeatureType {
  // QR Creation
  createQR,

  // QR Types
  qrTypeUrl,
  qrTypeText,
  qrTypeWifi,
  qrTypeVcard,
  qrTypeEmail,
  qrTypeLocation,

  // Customization
  colorCustomization,
  templateClassic,
  templateModern,
  templateVibrant,
  templateElegant,
  logoInsertion,
  advancedShapes,

  // History
  unlimitedScanHistory,
}

/// Represents access status for a feature
class FeatureAccess extends Equatable {
  final FeatureType feature;
  final bool isAllowed;
  final String? lockedReason;

  const FeatureAccess({
    required this.feature,
    required this.isAllowed,
    this.lockedReason,
  });

  /// Create an allowed feature access
  factory FeatureAccess.allowed(FeatureType feature) => FeatureAccess(
    feature: feature,
    isAllowed: true,
  );

  /// Create a locked feature access with reason
  factory FeatureAccess.locked(FeatureType feature, String reason) => FeatureAccess(
    feature: feature,
    isAllowed: false,
    lockedReason: reason,
  );

  @override
  List<Object?> get props => [feature, isAllowed, lockedReason];
}

/// Extension to get display name for feature types
extension FeatureTypeExtension on FeatureType {
  String get displayName {
    switch (this) {
      case FeatureType.createQR:
        return 'Create QR Code';
      case FeatureType.qrTypeUrl:
        return 'URL QR Code';
      case FeatureType.qrTypeText:
        return 'Text QR Code';
      case FeatureType.qrTypeWifi:
        return 'WiFi QR Code';
      case FeatureType.qrTypeVcard:
        return 'vCard QR Code';
      case FeatureType.qrTypeEmail:
        return 'Email QR Code';
      case FeatureType.qrTypeLocation:
        return 'Location QR Code';
      case FeatureType.colorCustomization:
        return 'Color Customization';
      case FeatureType.templateClassic:
        return 'Classic Template';
      case FeatureType.templateModern:
        return 'Modern Template';
      case FeatureType.templateVibrant:
        return 'Vibrant Template';
      case FeatureType.templateElegant:
        return 'Elegant Template';
      case FeatureType.logoInsertion:
        return 'Logo Insertion';
      case FeatureType.advancedShapes:
        return 'Advanced Shapes';
      case FeatureType.unlimitedScanHistory:
        return 'Unlimited Scan History';
    }
  }
}
