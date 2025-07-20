import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? bio;
  final String? location;
  final String? website;
  final String? company;
  final String? jobTitle;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> statistics;

  const UserProfileEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.bio,
    this.location,
    this.website,
    this.company,
    this.jobTitle,
    required this.createdAt,
    required this.updatedAt,
    this.preferences = const {},
    this.statistics = const {},
  });

  UserProfileEntity copyWith({
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
    return UserProfileEntity(
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

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        phoneNumber,
        bio,
        location,
        website,
        company,
        jobTitle,
        createdAt,
        updatedAt,
        preferences,
        statistics,
      ];
}