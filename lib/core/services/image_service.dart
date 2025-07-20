import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
  notApplicable,
}

enum ImageChangeResult {
  success,
  cancelled,
  permissionDenied,
  uploadFailed,
  unknownError,
}

class ImageChangeResponse {
  final ImageChangeResult result;
  final String? avatarUrl;
  final String? errorMessage;

  const ImageChangeResponse({
    required this.result,
    this.avatarUrl,
    this.errorMessage,
  });
}

class ImageService {
  static const String _avatarsBucket = 'avatars';
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from camera or gallery (without cropping for stability)
  static Future<File?> pickAndCropImage({
    required ImageSource source,
    int maxWidth = 512,
    int maxHeight = 512,
    int imageQuality = 85,
  }) async {
    try {
      // Request permissions
      bool hasPermission = await _requestPermissions(source);
      if (!hasPermission) {
        debugPrint('❌ Permission denied for image source: $source');
        debugPrint('ℹ️  Please allow camera/gallery access in your browser or device settings');
        return null;
      }

      // Pick image with automatic sizing for square aspect ratio
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile == null) {
        debugPrint('📷 No image selected');
        return null;
      }

      debugPrint('📷 Image picked and sized: ${pickedFile.path}');

      // Convert XFile to File and return (skip cropping for stability)
      final File imageFile = File(pickedFile.path);
      
      // Validate file exists
      if (!await imageFile.exists()) {
        debugPrint('❌ Picked image file does not exist: ${pickedFile.path}');
        return null;
      }

      debugPrint('✅ Image ready for upload: ${imageFile.path}');
      return imageFile;

    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  /// Upload image to Supabase Storage and return public URL
  static Future<String?> uploadAvatarImage(File imageFile) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user for avatar upload');
        return null;
      }

      // Generate unique filename with user folder structure
      final String fileName = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '$_avatarsBucket/$fileName';

      debugPrint('☁️ Uploading avatar to: $filePath');
      debugPrint('📝 User ID: ${user.id}');
      debugPrint('🗂️ Expected folder: ${user.id}/');
      debugPrint('🔑 User authenticated: ${user.email}');
      debugPrint('🎫 Session valid: ${SupabaseService.client.auth.currentSession != null}');

      // Read file as bytes
      final Uint8List fileBytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage with authentication context
      final String uploadPath = await SupabaseService.client.storage
          .from(_avatarsBucket)
          .uploadBinary(fileName, fileBytes);

      debugPrint('✅ Avatar uploaded successfully: $uploadPath');

      // Get public URL
      final String publicUrl = SupabaseService.client.storage
          .from(_avatarsBucket)
          .getPublicUrl(fileName);

      debugPrint('🔗 Avatar public URL: $publicUrl');
      return publicUrl;

    } catch (e) {
      debugPrint('❌ Error uploading avatar: $e');
      return null;
    }
  }

  /// Delete old avatar from storage
  static Future<bool> deleteAvatarImage(String avatarUrl) async {
    try {
      if (avatarUrl.isEmpty) {
        debugPrint('⚠️ Empty avatar URL, nothing to delete');
        return false;
      }

      // Skip deletion if it's not our bucket (external images, etc.)
      if (!avatarUrl.contains(_avatarsBucket)) {
        debugPrint('⚠️ Avatar URL not from our storage bucket, skipping deletion: $avatarUrl');
        return false;
      }

      // Extract full path from URL (including user folder)
      final Uri uri = Uri.parse(avatarUrl);
      
      // Get the path after the bucket name
      String filePath = '';
      bool foundBucket = false;
      for (String segment in uri.pathSegments) {
        if (foundBucket) {
          filePath += (filePath.isEmpty ? '' : '/') + segment;
        } else if (segment == _avatarsBucket) {
          foundBucket = true;
        }
      }

      if (filePath.isEmpty) {
        debugPrint('⚠️ Could not extract file path from avatar URL: $avatarUrl');
        return false;
      }

      debugPrint('🗑️ Deleting avatar at path: $filePath');

      // Delete from Supabase Storage
      final response = await SupabaseService.client.storage
          .from(_avatarsBucket)
          .remove([filePath]);

      debugPrint('✅ Avatar deleted successfully: $filePath');
      debugPrint('🔍 Storage response: $response');
      return true;

    } catch (e) {
      debugPrint('❌ Error deleting avatar: $e');
      return false;
    }
  }

  /// Update user profile with new avatar URL
  static Future<bool> updateUserAvatar(String avatarUrl) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user for avatar update');
        return false;
      }

      debugPrint('👤 Updating user avatar in auth metadata');

      // Update auth user metadata
      await SupabaseService.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': avatarUrl}),
      );

      // Update profile in database
      await SupabaseService.updateUserProfile(photoUrl: avatarUrl);

      debugPrint('✅ User avatar updated successfully');
      return true;

    } catch (e) {
      debugPrint('❌ Error updating user avatar: $e');
      return false;
    }
  }

  /// Complete avatar change process: pick, crop, upload, and update profile
  static Future<ImageChangeResponse> changeUserAvatar({
    required ImageSource source,
  }) async {
    try {
      debugPrint('🚀 Starting avatar change process from: $source');

      // Step 1: Pick and crop image
      final File? imageFile = await pickAndCropImage(source: source);
      if (imageFile == null) {
        debugPrint('📷 User cancelled image selection or cropping');
        return const ImageChangeResponse(result: ImageChangeResult.cancelled);
      }

      // Step 2: Get current avatar URL to delete later (check multiple sources)
      final user = SupabaseService.client.auth.currentUser;
      String? oldAvatarUrl = user?.userMetadata?['avatar_url'];
      
      // Also check user profile in database for more accurate avatar URL
      try {
        final profileResponse = await SupabaseService.client
            .from('user_profiles')
            .select('photo_url')
            .eq('id', user!.id)
            .single();
        
        // Use database avatar if available, otherwise use auth metadata
        oldAvatarUrl = profileResponse['photo_url'] ?? oldAvatarUrl;
        debugPrint('🗑️ Previous avatar to delete: $oldAvatarUrl');
      } catch (e) {
        debugPrint('⚠️ Could not fetch previous avatar from profile: $e');
      }

      // Step 3: Upload new image
      final String? newAvatarUrl = await uploadAvatarImage(imageFile);
      if (newAvatarUrl == null) {
        debugPrint('❌ Failed to upload new avatar');
        return const ImageChangeResponse(
          result: ImageChangeResult.uploadFailed,
          errorMessage: 'Failed to upload image to storage',
        );
      }

      // Step 4: Update user profile
      final bool updateSuccess = await updateUserAvatar(newAvatarUrl);
      if (!updateSuccess) {
        debugPrint('❌ Failed to update user profile, rolling back...');
        // Try to delete the uploaded image
        await deleteAvatarImage(newAvatarUrl);
        return const ImageChangeResponse(
          result: ImageChangeResult.uploadFailed,
          errorMessage: 'Failed to update user profile',
        );
      }

      // Step 5: Delete old avatar (if exists and different)
      if (oldAvatarUrl != null && 
          oldAvatarUrl.isNotEmpty && 
          oldAvatarUrl != newAvatarUrl) {
        debugPrint('🔄 Cleaning up old avatar...');
        final bool deleteSuccess = await deleteAvatarImage(oldAvatarUrl);
        if (deleteSuccess) {
          debugPrint('✅ Old avatar cleaned up successfully');
        } else {
          debugPrint('⚠️ Could not delete old avatar, but continuing...');
        }
      } else {
        debugPrint('ℹ️ No old avatar to delete or same URL');
      }

      // Step 6: Clean up local file
      try {
        await imageFile.delete();
        debugPrint('🧹 Local image file cleaned up');
      } catch (e) {
        debugPrint('⚠️ Could not delete local file: $e');
      }

      debugPrint('🎉 Avatar change completed successfully: $newAvatarUrl');
      return ImageChangeResponse(
        result: ImageChangeResult.success,
        avatarUrl: newAvatarUrl,
      );

    } catch (e) {
      debugPrint('❌ Error in avatar change process: $e');
      return ImageChangeResponse(
        result: ImageChangeResult.unknownError,
        errorMessage: e.toString(),
      );
    }
  }

  /// Check and request permissions with detailed result
  static Future<PermissionResult> checkAndRequestPermissions(ImageSource source) async {
    try {
      // Web doesn't need explicit permission requests
      if (kIsWeb) {
        return PermissionResult.notApplicable;
      }
      
      // Debug mode: Log but still request permissions to test emulator behavior
      if (kDebugMode) {
        debugPrint('🚧 DEBUG MODE: Testing permission request in emulator/simulator...');
        debugPrint('ℹ️  Let\'s see if permission dialog appears in emulator');
      }
      
      Permission permission;
      
      if (source == ImageSource.camera) {
        permission = Permission.camera;
      } else {
        // For gallery access on Android
        if (Platform.isAndroid) {
          // Use photos permission for Android 13+ (API 33+)
          permission = Permission.photos;
        } else {
          // iOS doesn't need explicit permission for photo library
          return PermissionResult.notApplicable;
        }
      }
      
      // Check current status
      final currentStatus = await permission.status;
      debugPrint('📱 ${source.name} permission current status: $currentStatus');
      
      if (currentStatus.isGranted || currentStatus.isLimited) {
        return PermissionResult.granted;
      }
      
      if (currentStatus.isPermanentlyDenied) {
        debugPrint('⚠️  Permission permanently denied - opening app settings');
        if (kDebugMode) {
          debugPrint('🔧 DEBUG: You may need to manually enable camera in iOS Simulator Settings');
          debugPrint('   Go to: Settings → Privacy & Security → Camera → QRaft');
        }
        return PermissionResult.permanentlyDenied;
      }
      
      // Request permission
      final requestResult = await permission.request();
      debugPrint('📱 ${source.name} permission request result: $requestResult');
      
      if (requestResult.isGranted || requestResult.isLimited) {
        return PermissionResult.granted;
      } else if (requestResult.isPermanentlyDenied) {
        return PermissionResult.permanentlyDenied;
      } else {
        return PermissionResult.denied;
      }
      
    } catch (e) {
      debugPrint('❌ Error checking/requesting permissions: $e');
      return PermissionResult.denied;
    }
  }

  // Private helper methods

  static Future<bool> _requestPermissions(ImageSource source) async {
    try {
      // Web doesn't need explicit permission requests for image picker
      if (kIsWeb) {
        return true;
      }
      
      if (source == ImageSource.camera) {
        // Check current permission status first
        final currentStatus = await Permission.camera.status;
        debugPrint('📷 Current camera permission status: $currentStatus');
        
        if (currentStatus.isGranted || currentStatus.isLimited) {
          return true;
        }
        
        // If denied permanently, we can't request again
        if (currentStatus.isPermanentlyDenied) {
          debugPrint('📷 Camera permission permanently denied');
          return false;
        }
        
        // Request permission
        final status = await Permission.camera.request();
        debugPrint('📷 Camera permission request result: $status');
        return status.isGranted || status.isLimited;
      } else {
        // For gallery access on Android
        if (Platform.isAndroid) {
          // Use photos permission for Android 13+ (API 33+)
          final currentStatus = await Permission.photos.status;
          debugPrint('📱 Current photos permission status: $currentStatus');
          
          if (currentStatus.isGranted || currentStatus.isLimited) {
            return true;
          }
          
          // If denied permanently, we can't request again
          if (currentStatus.isPermanentlyDenied) {
            debugPrint('📱 Photos permission permanently denied');
            return false;
          }
          
          // Request permission
          final status = await Permission.photos.request();
          debugPrint('📱 Photos permission request result: $status');
          return status.isGranted || status.isLimited;
        }
        return true; // iOS doesn't need explicit permission for photo library
      }
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      // If permission request fails, still try to proceed
      return true;
    }
  }

}