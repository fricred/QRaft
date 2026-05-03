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

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['texture_url'] as String? ?? '';
    // T-07-02: Accept only empty string or https:// URLs.
    // Non-empty values that are not https are sanitized to '' (fail-safe).
    final safeUrl =
        rawUrl.isEmpty || rawUrl.startsWith('https://') ? rawUrl : '';
    return MaterialModel(
      id: json['id'] as String,
      displayNameEs: json['display_name_es'] as String,
      displayNameEn: json['display_name_en'] as String,
      textureUrl: safeUrl,
      laserCompatible: json['laser_compatible'] as bool? ?? true,
    );
  }

  MaterialEntity toEntity() => MaterialEntity(
        id: id,
        displayNameEs: displayNameEs,
        displayNameEn: displayNameEn,
        textureUrl: textureUrl,
        laserCompatible: laserCompatible,
      );
}
