import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    super.displayName,
    super.photoURL,
    required super.emailVerified,
    super.createdAt,
    super.lastSignIn,
  });

  /// Create UserModel from Supabase User
  factory UserModel.fromSupabaseUser(User user) {
    return UserModel(
      uid: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['display_name'],
      photoURL: user.userMetadata?['avatar_url'],
      emailVerified: user.emailConfirmedAt != null,
      createdAt: DateTime.tryParse(user.createdAt),
      lastSignIn: DateTime.tryParse(user.lastSignInAt ?? ''),
    );
  }

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      emailVerified: json['emailVerified'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      lastSignIn: json['lastSignIn'] != null 
          ? DateTime.parse(json['lastSignIn']) 
          : null,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'lastSignIn': lastSignIn?.toIso8601String(),
    };
  }

  @override
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }
}