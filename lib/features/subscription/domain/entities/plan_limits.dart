import 'package:equatable/equatable.dart';
import '../../../qr_generator/domain/entities/qr_type.dart';

// Re-export QRType for convenience
export '../../../qr_generator/domain/entities/qr_type.dart';

/// Available QR code templates
enum QRTemplate {
  classic,
  modern,
  vibrant,
  elegant,
}

/// Defines the limits and features available for each plan
class PlanLimits extends Equatable {
  final int maxQRCodes;  // -1 for unlimited
  final List<QRType> allowedQRTypes;
  final bool colorCustomization;
  final List<QRTemplate> allowedTemplates;
  final bool logoInsertion;
  final bool advancedShapes;
  final int maxScanHistory;  // -1 for unlimited

  const PlanLimits({
    required this.maxQRCodes,
    required this.allowedQRTypes,
    required this.colorCustomization,
    required this.allowedTemplates,
    required this.logoInsertion,
    required this.advancedShapes,
    required this.maxScanHistory,
  });

  /// Free plan limits
  static const PlanLimits free = PlanLimits(
    maxQRCodes: 5,
    allowedQRTypes: [QRType.url, QRType.text],
    colorCustomization: false,
    allowedTemplates: [QRTemplate.classic],
    logoInsertion: false,
    advancedShapes: false,
    maxScanHistory: 10,
  );

  /// Pro plan limits (everything unlocked)
  static const PlanLimits pro = PlanLimits(
    maxQRCodes: -1,  // unlimited
    allowedQRTypes: QRType.values,
    colorCustomization: true,
    allowedTemplates: QRTemplate.values,
    logoInsertion: true,
    advancedShapes: true,
    maxScanHistory: -1,  // unlimited
  );

  /// Check if user can create more QR codes
  bool canCreateQR(int currentCount) =>
      maxQRCodes == -1 || currentCount < maxQRCodes;

  /// Check if a QR type is allowed
  bool isQRTypeAllowed(QRType type) => allowedQRTypes.contains(type);

  /// Check if a template is allowed
  bool isTemplateAllowed(QRTemplate template) => allowedTemplates.contains(template);

  /// Get remaining QR codes (-1 if unlimited)
  int getRemainingQRCodes(int currentCount) {
    if (maxQRCodes == -1) return -1;
    return maxQRCodes - currentCount;
  }

  /// Check if scan history is unlimited
  bool get hasUnlimitedHistory => maxScanHistory == -1;

  @override
  List<Object?> get props => [
    maxQRCodes,
    allowedQRTypes,
    colorCustomization,
    allowedTemplates,
    logoInsertion,
    advancedShapes,
    maxScanHistory,
  ];
}
