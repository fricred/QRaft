import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/plan_limits.dart';
import '../../domain/entities/feature_access.dart';
import 'subscription_providers.dart';

/// Check if specific QR type is allowed
final qrTypeAccessProvider = Provider.family<FeatureAccess, QRType>((ref, qrType) {
  final limits = ref.watch(planLimitsProvider);

  if (limits.isQRTypeAllowed(qrType)) {
    return FeatureAccess.allowed(_qrTypeToFeature(qrType));
  }

  return FeatureAccess.locked(
    _qrTypeToFeature(qrType),
    'Upgrade to Pro to create ${_qrTypeDisplayName(qrType)} QR codes',
  );
});

FeatureType _qrTypeToFeature(QRType type) {
  switch (type) {
    case QRType.url:
      return FeatureType.qrTypeUrl;
    case QRType.text:
      return FeatureType.qrTypeText;
    case QRType.wifi:
      return FeatureType.qrTypeWifi;
    case QRType.personalInfo:
      return FeatureType.qrTypeVcard;
    case QRType.email:
      return FeatureType.qrTypeEmail;
    case QRType.location:
      return FeatureType.qrTypeLocation;
  }
}

String _qrTypeDisplayName(QRType type) {
  switch (type) {
    case QRType.url:
      return 'URL';
    case QRType.text:
      return 'Text';
    case QRType.wifi:
      return 'WiFi';
    case QRType.personalInfo:
      return 'vCard';
    case QRType.email:
      return 'Email';
    case QRType.location:
      return 'Location';
  }
}

/// Check if template is allowed
final templateAccessProvider = Provider.family<FeatureAccess, QRTemplate>((ref, template) {
  final limits = ref.watch(planLimitsProvider);

  if (limits.isTemplateAllowed(template)) {
    return FeatureAccess.allowed(_templateToFeature(template));
  }

  return FeatureAccess.locked(
    _templateToFeature(template),
    'Upgrade to Pro to use the ${_templateDisplayName(template)} template',
  );
});

FeatureType _templateToFeature(QRTemplate template) {
  switch (template) {
    case QRTemplate.classic:
      return FeatureType.templateClassic;
    case QRTemplate.modern:
      return FeatureType.templateModern;
    case QRTemplate.vibrant:
      return FeatureType.templateVibrant;
    case QRTemplate.elegant:
      return FeatureType.templateElegant;
  }
}

String _templateDisplayName(QRTemplate template) {
  switch (template) {
    case QRTemplate.classic:
      return 'Classic';
    case QRTemplate.modern:
      return 'Modern';
    case QRTemplate.vibrant:
      return 'Vibrant';
    case QRTemplate.elegant:
      return 'Elegant';
  }
}

/// Check if color customization is allowed
final colorCustomizationAccessProvider = Provider<FeatureAccess>((ref) {
  final limits = ref.watch(planLimitsProvider);

  if (limits.colorCustomization) {
    return FeatureAccess.allowed(FeatureType.colorCustomization);
  }

  return FeatureAccess.locked(
    FeatureType.colorCustomization,
    'Upgrade to Pro to customize QR code colors',
  );
});

/// Check if logo insertion is allowed
final logoInsertionAccessProvider = Provider<FeatureAccess>((ref) {
  final limits = ref.watch(planLimitsProvider);

  if (limits.logoInsertion) {
    return FeatureAccess.allowed(FeatureType.logoInsertion);
  }

  return FeatureAccess.locked(
    FeatureType.logoInsertion,
    'Upgrade to Pro to add logos to your QR codes',
  );
});

/// Check if advanced shapes are allowed
final advancedShapesAccessProvider = Provider<FeatureAccess>((ref) {
  final limits = ref.watch(planLimitsProvider);

  if (limits.advancedShapes) {
    return FeatureAccess.allowed(FeatureType.advancedShapes);
  }

  return FeatureAccess.locked(
    FeatureType.advancedShapes,
    'Upgrade to Pro to use advanced QR code shapes',
  );
});

/// Check if unlimited scan history is available
final unlimitedHistoryAccessProvider = Provider<FeatureAccess>((ref) {
  final limits = ref.watch(planLimitsProvider);

  if (limits.hasUnlimitedHistory) {
    return FeatureAccess.allowed(FeatureType.unlimitedScanHistory);
  }

  return FeatureAccess.locked(
    FeatureType.unlimitedScanHistory,
    'Upgrade to Pro for unlimited scan history',
  );
});

/// Check if user can create QR codes (based on limit)
final createQRAccessProvider = Provider<FeatureAccess>((ref) {
  final canCreate = ref.watch(canCreateQRProvider);

  if (canCreate) {
    return FeatureAccess.allowed(FeatureType.createQR);
  }

  return FeatureAccess.locked(
    FeatureType.createQR,
    'You\'ve reached your QR code limit. Upgrade to Pro for unlimited QR codes.',
  );
});
