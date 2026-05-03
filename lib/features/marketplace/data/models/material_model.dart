import '../../domain/entities/material_entity.dart';

class MaterialModel {
  final String id;
  final String displayNameEs;
  final String displayNameEn;
  final String textureUrl;
  final bool laserCompatible;

  const MaterialModel({
    required this.id,
    required this.displayNameEs,
    required this.displayNameEn,
    required this.textureUrl,
    this.laserCompatible = true,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) => MaterialModel(
        id: json['id'] as String,
        displayNameEs: json['display_name_es'] as String,
        displayNameEn: json['display_name_en'] as String,
        textureUrl: json['texture_url'] as String? ?? '',
        laserCompatible: json['laser_compatible'] as bool? ?? true,
      );

  MaterialEntity toEntity() => MaterialEntity(
        id: id,
        displayNameEs: displayNameEs,
        displayNameEn: displayNameEn,
        textureUrl: textureUrl,
        laserCompatible: laserCompatible,
      );
}
