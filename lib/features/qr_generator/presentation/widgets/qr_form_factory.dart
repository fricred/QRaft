import 'package:flutter/material.dart';
import '../../domain/entities/qr_type.dart';
import 'forms/colombian_tax_form.dart';
import 'forms/url_form.dart';
import 'forms/wifi_form.dart';
import 'forms/text_form.dart';
import 'forms/email_form.dart';
import 'forms/location_form.dart';

class QRFormFactory {
  static Widget buildForm(QRType qrType, VoidCallback onContinue) {
    switch (qrType) {
      case QRType.personalInfo:
        return ColombianTaxForm(onContinue: onContinue);
      case QRType.url:
        return URLForm(onContinue: onContinue);
      case QRType.wifi:
        return WiFiForm(onContinue: onContinue);
      case QRType.text:
        return TextForm(onContinue: onContinue);
      case QRType.email:
        return EmailForm(onContinue: onContinue);
      case QRType.location:
        return LocationForm(onContinue: onContinue);
    }
  }
}