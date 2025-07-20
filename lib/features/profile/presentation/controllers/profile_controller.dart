import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../data/models/user_profile_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';

// Profile state
class ProfileState {
  final UserProfileEntity? profile;
  final bool isLoading;
  final String? errorMessage;
  final bool isEditing;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.isEditing = false,
  });

  ProfileState copyWith({
    UserProfileEntity? profile,
    bool? isLoading,
    String? errorMessage,
    bool? isEditing,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

// Profile controller
class ProfileController extends StateNotifier<ProfileState> {
  final Ref ref;

  ProfileController(this.ref) : super(const ProfileState()) {
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    final user = ref.read(supabaseAuthProvider).currentUser;
    debugPrint('🔍 Initializing profile - user: ${user?.email ?? 'null'}');
    if (user != null) {
      await loadProfile(user);
    } else {
      debugPrint('⚠️ No user found during profile initialization');
    }
  }

  Future<void> loadProfile(User user) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      UserProfileEntity profile;

      // Try to load from Supabase first
      if (SupabaseService.isInitialized) {
        debugPrint('🔍 Fetching profile from Supabase...');
        final supabaseProfile = await SupabaseService.getCurrentUserProfile(specificUser: user);
        debugPrint('📊 Supabase profile response: $supabaseProfile');
        
        if (supabaseProfile != null) {
          debugPrint('✅ Profile found in Supabase, loading...');
          profile = UserProfileModel.fromJson(supabaseProfile);
        } else {
          debugPrint('❌ No profile found in Supabase, creating new one...');
          // Create profile from Supabase user data
          profile = _createProfileFromSupabaseUser(user);
          
          // Save to Supabase
          debugPrint('💾 Saving new profile to Supabase...');
          await SupabaseService.createCurrentUserProfile(
            displayName: user.userMetadata?['display_name'],
            photoUrl: user.userMetadata?['avatar_url'],
            specificUser: user,
          );
          debugPrint('✅ Profile created successfully');
        }
      } else {
        // Fallback to Supabase user data only
        profile = _createProfileFromSupabaseUser(user);
      }

      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading profile: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load profile: $e',
      );
    }
  }

  UserProfileEntity _createProfileFromSupabaseUser(User user) {
    final now = DateTime.now();
    return UserProfileEntity(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['display_name'],
      photoUrl: user.userMetadata?['avatar_url'],
      phoneNumber: user.phone,
      createdAt: DateTime.tryParse(user.createdAt ?? '') ?? now,
      updatedAt: now,
    );
  }

  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? bio,
    String? location,
    String? website,
    String? company,
    String? jobTitle,
  }) async {
    if (state.profile == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final updatedProfile = state.profile!.copyWith(
        displayName: displayName,
        phoneNumber: phoneNumber,
        bio: bio,
        location: location,
        website: website,
        company: company,
        jobTitle: jobTitle,
        updatedAt: DateTime.now(),
      );

      // Update in Supabase if available
      if (SupabaseService.isInitialized) {
        debugPrint('🔄 Updating profile in Supabase...');
        await SupabaseService.updateUserProfile(
          displayName: displayName,
          photoUrl: state.profile!.photoUrl,
          phoneNumber: phoneNumber,
          bio: bio,
          location: location,
          website: website,
          company: company,
          jobTitle: jobTitle,
        );
        debugPrint('✅ Profile updated successfully in Supabase');
      } else {
        debugPrint('❌ Supabase not initialized, cannot update profile');
      }

      // Update Supabase Auth display name if changed
      final authProvider = ref.read(supabaseAuthProvider);
      if (authProvider.currentUser != null && displayName != null) {
        await authProvider.updateProfile(displayName: displayName);
      }

      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
        isEditing: false,
      );
    } catch (e) {
      debugPrint('Error updating profile: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update profile: $e',
      );
    }
  }

  Future<void> updateProfilePhoto(String photoUrl) async {
    if (state.profile == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final updatedProfile = state.profile!.copyWith(
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );

      // Update in Supabase if available
      if (SupabaseService.isInitialized) {
        await SupabaseService.updateUserProfile(
          photoUrl: photoUrl,
        );
      }

      // Update Supabase Auth photo URL
      final authProvider = ref.read(supabaseAuthProvider);
      if (authProvider.currentUser != null) {
        await authProvider.updateProfile(photoUrl: photoUrl);
      }

      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error updating profile photo: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update profile photo: $e',
      );
    }
  }

  void setEditing(bool isEditing) {
    state = state.copyWith(isEditing: isEditing);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> refreshProfile() async {
    final user = ref.read(supabaseAuthProvider).currentUser;
    if (user != null) {
      await loadProfile(user);
    }
  }
}

// Provider for the profile controller
final profileControllerProvider = StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(ref);
});

// Convenience provider for profile data
final profileProvider = Provider<UserProfileEntity?>((ref) {
  return ref.watch(profileControllerProvider).profile;
});

// Provider for profile loading state
final profileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileControllerProvider).isLoading;
});

// Provider for profile editing state
final profileEditingProvider = Provider<bool>((ref) {
  return ref.watch(profileControllerProvider).isEditing;
});