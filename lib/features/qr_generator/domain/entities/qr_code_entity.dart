import 'package:equatable/equatable.dart';
import 'qr_type.dart';
import '../value_objects/qr_profile.dart';

class QRCodeEntity extends Equatable {
  final String id;
  final String name;
  final QRType type;
  final String data;
  final String displayData;
  final QRCustomization customization;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final bool isFavorite;

  const QRCodeEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.data,
    required this.displayData,
    required this.customization,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.isFavorite = false,
  });

  QRCodeEntity copyWith({
    String? id,
    String? name,
    QRType? type,
    String? data,
    String? displayData,
    QRCustomization? customization,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    bool? isFavorite,
  }) {
    return QRCodeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      data: data ?? this.data,
      displayData: displayData ?? this.displayData,
      customization: customization ?? this.customization,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        data,
        displayData,
        customization,
        createdAt,
        updatedAt,
        userId,
        isFavorite,
      ];
}

class QRCustomization extends Equatable {
  // --- Legacy / preserved fields ---
  final int foregroundColor;
  final int backgroundColor;
  final int eyeColor;
  final double size;
  final int errorCorrectionLevel; // 0=L, 1=M, 2=Q, 3=H
  final String? logoPath;
  final bool hasLogo;
  final int eyeShape; // 0: square, 1: circle — backward compat, superseded by eyePreset
  final int dataShape; // 0: square, 1: circle — backward compat, superseded by modulePreset
  final bool roundedCorners;
  final double logoSize; // backward compat — superseded by logoCoverage

  // --- Phase 5 new fields ---
  final bool hasGradient;
  final int? gradientStart; // ARGB int; null when solid
  final int? gradientEnd; // ARGB int; null when solid
  final GradientType gradientType; // default: solid
  final int modulePreset; // 0-7; default 0 (Classic)
  final int eyePreset; // 0-7; default 0 (Classic Square)
  final int profile; // 0=printSafe, 1=digitalOnly, 2=tattooSafe; default 0
  final String? frameText; // null = no frame
  final double logoCoverage; // 0.0-0.20 scale; default 0.0

  const QRCustomization({
    this.foregroundColor = 0xFF000000,
    this.backgroundColor = 0xFFFFFFFF,
    this.eyeColor = 0xFF000000,
    this.size = 200.0,
    this.errorCorrectionLevel = 1, // 0-3 (L, M, Q, H)
    this.logoPath,
    this.hasLogo = false,
    this.eyeShape = 0,
    this.dataShape = 0,
    this.roundedCorners = false,
    this.logoSize = 40.0,
    // Phase 5 defaults — preserve existing behavior
    this.hasGradient = false,
    this.gradientStart,
    this.gradientEnd,
    this.gradientType = GradientType.solid,
    this.modulePreset = 0,
    this.eyePreset = 0,
    this.profile = 0,
    this.frameText,
    this.logoCoverage = 0.0,
  });

  QRCustomization copyWith({
    int? foregroundColor,
    int? backgroundColor,
    int? eyeColor,
    double? size,
    int? errorCorrectionLevel,
    // Nullable clearance sentinel pattern
    Object? logoPath = _sentinelRef,
    bool? hasLogo,
    int? eyeShape,
    int? dataShape,
    bool? roundedCorners,
    double? logoSize,
    // Phase 5 fields
    bool? hasGradient,
    Object? gradientStart = _sentinelRef,
    Object? gradientEnd = _sentinelRef,
    GradientType? gradientType,
    int? modulePreset,
    int? eyePreset,
    int? profile,
    Object? frameText = _sentinelRef,
    double? logoCoverage,
  }) {
    return QRCustomization(
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      eyeColor: eyeColor ?? this.eyeColor,
      size: size ?? this.size,
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
      logoPath: identical(logoPath, _sentinelRef)
          ? this.logoPath
          : logoPath as String?,
      hasLogo: hasLogo ?? this.hasLogo,
      eyeShape: eyeShape ?? this.eyeShape,
      dataShape: dataShape ?? this.dataShape,
      roundedCorners: roundedCorners ?? this.roundedCorners,
      logoSize: logoSize ?? this.logoSize,
      hasGradient: hasGradient ?? this.hasGradient,
      gradientStart: identical(gradientStart, _sentinelRef)
          ? this.gradientStart
          : gradientStart as int?,
      gradientEnd: identical(gradientEnd, _sentinelRef)
          ? this.gradientEnd
          : gradientEnd as int?,
      gradientType: gradientType ?? this.gradientType,
      modulePreset: modulePreset ?? this.modulePreset,
      eyePreset: eyePreset ?? this.eyePreset,
      profile: profile ?? this.profile,
      frameText: identical(frameText, _sentinelRef)
          ? this.frameText
          : frameText as String?,
      logoCoverage: logoCoverage ?? this.logoCoverage,
    );
  }

  @override
  List<Object?> get props => [
        foregroundColor,
        backgroundColor,
        eyeColor,
        size,
        errorCorrectionLevel,
        logoPath,
        hasLogo,
        eyeShape,
        dataShape,
        roundedCorners,
        logoSize,
        hasGradient,
        gradientStart,
        gradientEnd,
        gradientType,
        modulePreset,
        eyePreset,
        profile,
        frameText,
        logoCoverage,
      ];
}

// Module-level sentinel constant for copyWith nullable clearance.
// ignore: prefer_const_declarations
const _sentinelRef = Object();
