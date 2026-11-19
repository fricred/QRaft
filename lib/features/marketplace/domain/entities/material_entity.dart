import 'package:equatable/equatable.dart';

class MaterialEntity extends Equatable {
  final String id; // 'wood','acrylic','metal','leather','glass','stone'
  final String displayNameEs;
  final String displayNameEn;
  final String textureUrl; // may be empty string — caller must guard
  final bool laserCompatible;

  const MaterialEntity({
    required this.id,
    required this.displayNameEs,
    required this.displayNameEn,
    required this.textureUrl,
    this.laserCompatible = true,
  });

  @override
  List<Object?> get props =>
      [id, displayNameEs, displayNameEn, textureUrl, laserCompatible];
}
