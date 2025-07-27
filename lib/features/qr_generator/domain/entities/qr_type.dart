import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

enum QRType {
  personalInfo('personalInfo', 'vcard'),
  url('websiteUrl', 'url'),
  wifi('wifi', 'wifi'),
  text('text', 'text'),
  email('email', 'email'),
  location('location', 'geo');

  const QRType(this.translationKey, this.identifier);

  final String translationKey;
  final String identifier;
}

extension QRTypeExtension on QRType {
  String getDisplayName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case QRType.personalInfo:
        return l10n.qrTypePersonalInfo;
      case QRType.url:
        return l10n.qrTypeWebsiteUrl;
      case QRType.wifi:
        return l10n.qrTypeWifi;
      case QRType.text:
        return l10n.qrTypeText;
      case QRType.email:
        return l10n.qrTypeEmail;
      case QRType.location:
        return l10n.qrTypeLocation;
    }
  }

  String getDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case QRType.personalInfo:
        return l10n.qrTypePersonalInfoDesc;
      case QRType.url:
        return l10n.qrTypeWebsiteUrlDesc;
      case QRType.wifi:
        return l10n.qrTypeWifiDesc;
      case QRType.text:
        return l10n.qrTypeTextDesc;
      case QRType.email:
        return l10n.qrTypeEmailDesc;
      case QRType.location:
        return l10n.qrTypeLocationDesc;
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