import 'package:equatable/equatable.dart';

/// Domain entity representing a qraft.link/{slug} redirect record.
///
/// Maps 1-to-1 with the `redirects` Supabase table.
/// Immutable value object — use [copyWith] for derived mutations.
class RedirectEntity extends Equatable {
  final String id;
  final String slug;
  final String destinationUrl;
  final String? ownerId;
  final int scanCount;
  final DateTime? lastScannedAt;
  final String? lastCountry;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RedirectEntity({
    required this.id,
    required this.slug,
    required this.destinationUrl,
    this.ownerId,
    required this.scanCount,
    this.lastScannedAt,
    this.lastCountry,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Construct from a Supabase row (JSON map).
  factory RedirectEntity.fromJson(Map<String, dynamic> json) {
    return RedirectEntity(
      id: json['id'] as String,
      slug: json['slug'] as String,
      destinationUrl: json['destination_url'] as String,
      ownerId: json['owner_id'] as String?,
      scanCount: (json['scan_count'] as int?) ?? 0,
      lastScannedAt: json['last_scanned_at'] != null
          ? DateTime.parse(json['last_scanned_at'] as String)
          : null,
      lastCountry: json['last_country'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Serialise to a JSON map (used for INSERT / UPDATE payloads).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'destination_url': destinationUrl,
      'owner_id': ownerId,
      'scan_count': scanCount,
      'last_scanned_at': lastScannedAt?.toIso8601String(),
      'last_country': lastCountry,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  RedirectEntity copyWith({
    String? id,
    String? slug,
    String? destinationUrl,
    String? ownerId,
    int? scanCount,
    DateTime? lastScannedAt,
    String? lastCountry,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RedirectEntity(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      destinationUrl: destinationUrl ?? this.destinationUrl,
      ownerId: ownerId ?? this.ownerId,
      scanCount: scanCount ?? this.scanCount,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      lastCountry: lastCountry ?? this.lastCountry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        slug,
        destinationUrl,
        ownerId,
        scanCount,
        lastScannedAt,
        lastCountry,
        createdAt,
        updatedAt,
      ];
}
