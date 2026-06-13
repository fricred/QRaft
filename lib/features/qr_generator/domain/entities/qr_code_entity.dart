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

  /// Dynamic-redirect metadata, populated from the `redirects` table when
  /// this QR has a scanqraft.app/{slug} redirect minted (engraved orders,
  /// RDR-01). All null for purely static QRs or until the redirects link
  /// migration (20260612000001) is applied.
  final String? slug;
  final int? scanCount;
  final DateTime? lastScannedAt;

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
    this.slug,
    this.scanCount,
    this.lastScannedAt,
  });

  /// True when this QR is dynamic — it has a scanqraft.app redirect whose
  /// destination can be edited after engraving.
  bool get isDynamic => slug != null && slug!.isNotEmpty;

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
    String? slug,
    int? scanCount,
    DateTime? lastScannedAt,
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
      slug: slug ?? this.slug,
      scanCount: scanCount ?? this.scanCount,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
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
        slug,
        scanCount,
        lastScannedAt,
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

  /// Serializes all customization fields to a JSON-safe map.
  ///
  /// Used to freeze a snapshot into [cart_items.customization_snapshot] JSONB
  /// and later into [order_items.customization_snapshot] at checkout.
  /// All values are primitives (int, double, bool, String?) so the map is
  /// directly compatible with Supabase JSONB encoding.
  Map<String, dynamic> toJson() => {
        'foreground_color': foregroundColor,
        'background_color': backgroundColor,
        'eye_color': eyeColor,
        'size': size,
        'error_correction_level': errorCorrectionLevel,
        'logo_path': logoPath,
        'has_logo': hasLogo,
        'eye_shape': eyeShape,
        'data_shape': dataShape,
        'rounded_corners': roundedCorners,
        'logo_size': logoSize,
        'has_gradient': hasGradient,
        'gradient_start': gradientStart,
        'gradient_end': gradientEnd,
        'gradient_type': gradientType.name,
        'module_preset': modulePreset,
        'eye_preset': eyePreset,
        'profile': profile,
        'frame_text': frameText,
        'logo_coverage': logoCoverage,
      };

  /// Deserializes a [QRCustomization] from a JSON map (e.g., from Supabase JSONB).
  ///
  /// Unknown [gradient_type] values fall back to [GradientType.solid] so that
  /// future enum additions do not crash older app versions reading old snapshots.
  factory QRCustomization.fromJson(Map<String, dynamic> json) {
    final gradientTypeName = json['gradient_type'] as String?;
    final resolvedGradientType = gradientTypeName != null
        ? GradientType.values.firstWhere(
            (e) => e.name == gradientTypeName,
            orElse: () => GradientType.solid,
          )
        : GradientType.solid;

    return QRCustomization(
      foregroundColor: (json['foreground_color'] as num?)?.toInt() ?? 0xFF000000,
      backgroundColor: (json['background_color'] as num?)?.toInt() ?? 0xFFFFFFFF,
      eyeColor: (json['eye_color'] as num?)?.toInt() ?? 0xFF000000,
      size: (json['size'] as num?)?.toDouble() ?? 200.0,
      errorCorrectionLevel:
          (json['error_correction_level'] as num?)?.toInt() ?? 1,
      logoPath: json['logo_path'] as String?,
      hasLogo: json['has_logo'] as bool? ?? false,
      eyeShape: (json['eye_shape'] as num?)?.toInt() ?? 0,
      dataShape: (json['data_shape'] as num?)?.toInt() ?? 0,
      roundedCorners: json['rounded_corners'] as bool? ?? false,
      logoSize: (json['logo_size'] as num?)?.toDouble() ?? 40.0,
      hasGradient: json['has_gradient'] as bool? ?? false,
      gradientStart: (json['gradient_start'] as num?)?.toInt(),
      gradientEnd: (json['gradient_end'] as num?)?.toInt(),
      gradientType: resolvedGradientType,
      modulePreset: (json['module_preset'] as num?)?.toInt() ?? 0,
      eyePreset: (json['eye_preset'] as num?)?.toInt() ?? 0,
      profile: (json['profile'] as num?)?.toInt() ?? 0,
      frameText: json['frame_text'] as String?,
      logoCoverage: (json['logo_coverage'] as num?)?.toDouble() ?? 0.0,
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
