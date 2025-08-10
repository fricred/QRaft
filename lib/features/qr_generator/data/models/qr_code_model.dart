import '../../domain/entities/qr_code_entity.dart';
import '../../domain/entities/qr_type.dart';

class QRCodeModel extends QRCodeEntity {
  const QRCodeModel({
    required super.id,
    required super.name,
    required super.type,
    required super.data,
    required super.displayData,
    required super.customization,
    required super.createdAt,
    required super.updatedAt,
    required super.userId,
    super.isFavorite = false,
  });

  factory QRCodeModel.fromJson(Map<String, dynamic> json) {
    return QRCodeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: QRType.values.firstWhere((e) => e.identifier == json['type']),
      data: json['data'] as String,
      displayData: json['display_data'] as String,
      customization: QRCustomizationModel.fromJson(json['customization'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userId: json['user_id'] as String,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.identifier,
      'data': data,
      'display_data': displayData,
      'customization': (customization as QRCustomizationModel).toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'is_favorite': isFavorite,
    };
  }

  factory QRCodeModel.fromEntity(QRCodeEntity entity) {
    return QRCodeModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      data: entity.data,
      displayData: entity.displayData,
      customization: QRCustomizationModel.fromEntity(entity.customization),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      userId: entity.userId,
      isFavorite: entity.isFavorite,
    );
  }
}

class QRCustomizationModel extends QRCustomization {
  const QRCustomizationModel({
    super.foregroundColor,
    super.backgroundColor,
    super.eyeColor,
    super.size,
    super.errorCorrectionLevel,
    super.logoPath,
    super.hasLogo,
    super.eyeShape,
    super.dataShape,
    super.roundedCorners,
    super.logoSize,
  });

  factory QRCustomizationModel.fromJson(Map<String, dynamic> json) {
    return QRCustomizationModel(
      foregroundColor: json['foreground_color'] as int? ?? 0xFF000000,
      backgroundColor: json['background_color'] as int? ?? 0xFFFFFFFF,
      eyeColor: json['eye_color'] as int? ?? 0xFF000000,
      size: (json['size'] as num?)?.toDouble() ?? 200.0,
      errorCorrectionLevel: json['error_correction_level'] as int? ?? 1,
      logoPath: json['logo_path'] as String?,
      hasLogo: json['has_logo'] as bool? ?? false,
      eyeShape: json['eye_shape'] as int? ?? 0,
      dataShape: json['data_shape'] as int? ?? 0,
      roundedCorners: json['rounded_corners'] as bool? ?? false,
      logoSize: (json['logo_size'] as num?)?.toDouble() ?? 40.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }
  
  factory QRCustomizationModel.fromEntity(QRCustomization entity) {
    return QRCustomizationModel(
      foregroundColor: entity.foregroundColor,
      backgroundColor: entity.backgroundColor,
      eyeColor: entity.eyeColor,
      size: entity.size,
      errorCorrectionLevel: entity.errorCorrectionLevel,
      logoPath: entity.logoPath,
      hasLogo: entity.hasLogo,
      eyeShape: entity.eyeShape,
      dataShape: entity.dataShape,
      roundedCorners: entity.roundedCorners,
      logoSize: entity.logoSize,
    );
  }
}