import 'package:equatable/equatable.dart';
import 'qr_type.dart';

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
  final int foregroundColor;
  final int backgroundColor;
  final int eyeColor;
  final double size;
  final int errorCorrectionLevel;
  final String? logoPath;
  final bool hasLogo;
  final int eyeShape; // 0: square, 1: circle
  final int dataShape; // 0: square, 1: circle
  final bool roundedCorners;
  final double logoSize;

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
  });

  QRCustomization copyWith({
    int? foregroundColor,
    int? backgroundColor,
    int? eyeColor,
    double? size,
    int? errorCorrectionLevel,
    String? logoPath,
    bool? hasLogo,
    int? eyeShape,
    int? dataShape,
    bool? roundedCorners,
    double? logoSize,
  }) {
    return QRCustomization(
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      eyeColor: eyeColor ?? this.eyeColor,
      size: size ?? this.size,
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
      logoPath: logoPath ?? this.logoPath,
      hasLogo: hasLogo ?? this.hasLogo,
      eyeShape: eyeShape ?? this.eyeShape,
      dataShape: dataShape ?? this.dataShape,
      roundedCorners: roundedCorners ?? this.roundedCorners,
      logoSize: logoSize ?? this.logoSize,
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
      ];
}