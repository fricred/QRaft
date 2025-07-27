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
    };
  }

  factory QRCodeModel.fromEntity(QRCodeEntity entity) {
    return QRCodeModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      data: entity.data,
      displayData: entity.displayData,
      customization: entity.customization,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      userId: entity.userId,
    );
  }
}

class QRCustomizationModel extends QRCustomization {
  const QRCustomizationModel({
    super.foregroundColor,
    super.backgroundColor,
    super.size,
    super.errorCorrectionLevel,
    super.logoPath,
    super.hasLogo,
  });

  factory QRCustomizationModel.fromJson(Map<String, dynamic> json) {
    return QRCustomizationModel(
      foregroundColor: json['foreground_color'] as int? ?? 0xFF000000,
      backgroundColor: json['background_color'] as int? ?? 0xFFFFFFFF,
      size: (json['size'] as num?)?.toDouble() ?? 200.0,
      errorCorrectionLevel: json['error_correction_level'] as int? ?? 1,
      logoPath: json['logo_path'] as String?,
      hasLogo: json['has_logo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foreground_color': foregroundColor,
      'background_color': backgroundColor,
      'size': size,
      'error_correction_level': errorCorrectionLevel,
      'logo_path': logoPath,
      'has_logo': hasLogo,
    };
  }
}