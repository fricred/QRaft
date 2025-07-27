import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/qr_code_entity.dart';

class QRCustomizationState {
  final QRCustomization customization;
  final bool isPreviewMode;

  const QRCustomizationState({
    this.customization = const QRCustomization(),
    this.isPreviewMode = false,
  });

  QRCustomizationState copyWith({
    QRCustomization? customization,
    bool? isPreviewMode,
  }) {
    return QRCustomizationState(
      customization: customization ?? this.customization,
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
    );
  }
}

class QRCustomizationController extends StateNotifier<QRCustomizationState> {
  QRCustomizationController() : super(const QRCustomizationState());

  void updateForegroundColor(Color color) {
    final customization = state.customization.copyWith(
      foregroundColor: _colorToInt(color),
    );
    state = state.copyWith(customization: customization);
  }

  void updateBackgroundColor(Color color) {
    final customization = state.customization.copyWith(
      backgroundColor: _colorToInt(color),
    );
    state = state.copyWith(customization: customization);
  }

  void updateEyeColor(Color color) {
    final customization = state.customization.copyWith(
      eyeColor: _colorToInt(color),
    );
    state = state.copyWith(customization: customization);
  }


  // Helper method to convert Color to int without deprecated value property
  int _colorToInt(Color color) {
    return (color.a * 255).round() << 24 |
           (color.r * 255).round() << 16 |
           (color.g * 255).round() << 8 |
           (color.b * 255).round();
  }


  void updateSize(double size) {
    final customization = state.customization.copyWith(size: size);
    state = state.copyWith(customization: customization);
  }

  void updateEyeShape(int shape) {
    final customization = state.customization.copyWith(eyeShape: shape);
    state = state.copyWith(customization: customization);
  }

  void updateDataShape(int shape) {
    final customization = state.customization.copyWith(dataShape: shape);
    state = state.copyWith(customization: customization);
  }

  void updateRoundedCorners(bool rounded) {
    final customization = state.customization.copyWith(roundedCorners: rounded);
    state = state.copyWith(customization: customization);
  }

  void updateErrorCorrection(int level) {
    final customization = state.customization.copyWith(errorCorrectionLevel: level);
    state = state.copyWith(customization: customization);
  }

  void updateLogo(String? logoPath, double? logoSize) {
    final customization = state.customization.copyWith(
      logoPath: logoPath,
      hasLogo: logoPath != null,
      logoSize: logoSize ?? state.customization.logoSize,
    );
    state = state.copyWith(customization: customization);
  }

  void removeLogo() {
    final customization = state.customization.copyWith(
      logoPath: null,
      hasLogo: false,
    );
    state = state.copyWith(customization: customization);
  }

  void togglePreviewMode() {
    state = state.copyWith(isPreviewMode: !state.isPreviewMode);
  }

  void applyTemplate(QRTemplate template) {
    QRCustomization customization;
    
    switch (template) {
      case QRTemplate.classic:
        customization = const QRCustomization(
          foregroundColor: 0xFF000000,
          backgroundColor: 0xFFFFFFFF,
          eyeColor: 0xFF000000,
        );
        break;
      case QRTemplate.modern:
        customization = const QRCustomization(
          foregroundColor: 0xFF1A73E8,
          backgroundColor: 0xFFF5F7FA,
          eyeColor: 0xFF1A73E8,
          eyeShape: 1, // circle
          roundedCorners: true,
        );
        break;
      case QRTemplate.vibrant:
        customization = const QRCustomization(
          foregroundColor: 0xFF00FF88,
          backgroundColor: 0xFF1A1A1A,
          eyeColor: 0xFF00FF88,
          roundedCorners: true,
        );
        break;
      case QRTemplate.elegant:
        customization = const QRCustomization(
          foregroundColor: 0xFF2E2E2E,
          backgroundColor: 0xFFFAFAFA,
          eyeColor: 0xFF6366F1,
          eyeShape: 1, // circle
          dataShape: 1, // circle
          roundedCorners: true,
        );
        break;
    }
    
    state = state.copyWith(customization: customization);
  }

  void reset() {
    state = const QRCustomizationState();
  }
}

enum QRTemplate {
  classic,
  modern,
  vibrant,
  elegant,
}

extension QRTemplateExtension on QRTemplate {
  String get name {
    switch (this) {
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

  String get description {
    switch (this) {
      case QRTemplate.classic:
        return 'Black on white, traditional style';
      case QRTemplate.modern:
        return 'Blue theme with rounded corners';
      case QRTemplate.vibrant:
        return 'Gradient colors on dark background';
      case QRTemplate.elegant:
        return 'Sophisticated circular design';
    }
  }

  List<int> get previewColors {
    switch (this) {
      case QRTemplate.classic:
        return [0xFF000000, 0xFFFFFFFF];
      case QRTemplate.modern:
        return [0xFF1A73E8, 0xFFF5F7FA];
      case QRTemplate.vibrant:
        return [0xFF00FF88, 0xFF1A73E8];
      case QRTemplate.elegant:
        return [0xFF6366F1, 0xFFFAFAFA];
    }
  }
}

final qrCustomizationControllerProvider = StateNotifierProvider<QRCustomizationController, QRCustomizationState>((ref) {
  return QRCustomizationController();
});