import '../../domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.phoneNumber,
    super.bio,
    super.location,
    super.website,
    super.company,
    super.jobTitle,
    required super.createdAt,
    required super.updatedAt,
    super.preferences,
    super.statistics,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      website: json['website'] as String?,
      company: json['company'] as String?,
      jobTitle: json['job_title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      statistics: json['statistics'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'phone_number': phoneNumber,
      'bio': bio,
      'location': location,
      'website': website,
      'company': company,
      'job_title': jobTitle,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'preferences': preferences,
      'statistics': statistics,
    };
  }

  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
    return UserProfileModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      phoneNumber: entity.phoneNumber,
      bio: entity.bio,
      location: entity.location,
      website: entity.website,
      company: entity.company,
      jobTitle: entity.jobTitle,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      preferences: entity.preferences,
      statistics: entity.statistics,
    );
  }

  @override
  UserProfileModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    String? location,
    String? website,
    String? company,
    String? jobTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? statistics,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      statistics: statistics ?? this.statistics,
    );
  }
}