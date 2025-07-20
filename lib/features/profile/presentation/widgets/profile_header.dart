import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../controllers/profile_controller.dart';
import '../../../../core/services/image_service.dart';
import '../../../../shared/widgets/image_source_selector.dart';

class ProfileHeader extends ConsumerWidget {
  final UserProfileEntity? profile;

  const ProfileHeader({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile photo
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00FF88),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profile?.photoUrl != null
                      ? Image.network(
                          profile!.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              
              // Edit photo button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showPhotoOptions(context, ref),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Display name
          Text(
            profile?.displayName ?? l10n.anonymousUser,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            profile?.email ?? l10n.noEmail,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Bio
          if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile!.bio!,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Location
          if (profile?.location != null && profile!.location!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  profile!.location!,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          // Join date
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Colors.grey[500],
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.joinedDate(_formatDate(profile?.createdAt, l10n)),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A73E8),
            const Color(0xFF00FF88),
          ],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 48,
      ),
    );
  }

  void _showPhotoOptions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ImageSourceSelector.show(
      context,
      title: l10n.changeProfilePhoto,
      subtitle: l10n.choosePhotoSource,
      onSourceSelected: (source) => _handleImageSourceSelection(context, ref, source),
    );
  }

  void _handleImageSourceSelection(BuildContext context, WidgetRef ref, ImageSource source) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    
    try {
      // First, check and request permissions
      final permissionResult = await ImageService.checkAndRequestPermissions(source);
      
      if (!context.mounted) return;
      
      // Handle permission results
      switch (permissionResult) {
        case PermissionResult.denied:
          _showPermissionDeniedDialog(context, l10n, source, ref, canRetry: true);
          return;
          
        case PermissionResult.permanentlyDenied:
          _showPermissionDeniedDialog(context, l10n, source, ref, canRetry: false);
          return;
          
        case PermissionResult.granted:
        case PermissionResult.notApplicable:
          // Continue with image selection
          break;
      }
      
      // Use ImageService to handle complete avatar change process with cropping
      final response = await ImageService.changeUserAvatarWithCropping(
        context: context,
        source: source,
        aspectRatio: 1.0, // Square for profile photos
        withCircleUi: true, // Circular cropping UI
      );

      if (!context.mounted) return;

      switch (response.result) {
        case ImageChangeResult.success:
          // Success - update profile controller
          ref.read(profileControllerProvider.notifier).updateProfilePhoto(response.avatarUrl!);
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00FF88)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.profilePhotoUpdatedSuccess,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2E2E2E),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
          break;

        case ImageChangeResult.cancelled:
          // User cancelled - no need to show error
          debugPrint('📷 User cancelled photo selection');
          break;

        case ImageChangeResult.permissionDenied:
        case ImageChangeResult.uploadFailed:
        case ImageChangeResult.unknownError:
          // Failed - show specific error message
          String errorMessage;
          if (response.result == ImageChangeResult.permissionDenied) {
            errorMessage = source == ImageSource.camera 
                ? l10n.cameraPermissionDenied
                : l10n.galleryPermissionDenied;
          } else {
            errorMessage = response.errorMessage ?? l10n.profilePhotoUpdateFailed;
          }
        
        if (context.mounted) {
          // Show both SnackBar and Dialog for better visibility
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2E2E2E),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          
          // Also show dialog for better visibility
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF2E2E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Error',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: Text(
                errorMessage,
                style: TextStyle(color: Colors.grey[300]),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.ok,
                    style: const TextStyle(color: Color(0xFF00FF88)),
                  ),
                ),
              ],
            ),
          );
        }
          break;
      }
    } catch (e) {
      if (!context.mounted) return;
      
      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.error(e.toString()),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E2E2E),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog(
    BuildContext context,
    AppLocalizations l10n,
    ImageSource source,
    WidgetRef ref, {
    required bool canRetry,
  }) {
    final String title = source == ImageSource.camera ? l10n.camera : l10n.gallery;
    final String message = source == ImageSource.camera 
        ? l10n.cameraPermissionDenied 
        : l10n.galleryPermissionDenied;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              source == ImageSource.camera ? Icons.camera_alt : Icons.photo_library,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              '$title ${l10n.notifications}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: Colors.grey[300]),
            ),
            if (!canRetry) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Abre Configuración > ${l10n.privacy} > $title para habilitar el acceso.',
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (canRetry)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Retry permission request
                _handleImageSourceSelection(context, ref, source);
              },
              child: Text(
                l10n.retry,
                style: const TextStyle(color: Color(0xFF00FF88)),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.ok,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date, AppLocalizations l10n) {
    if (date == null) return l10n.unknown;
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 30) {
      return l10n.daysAgo(difference.inDays);
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return l10n.monthsAgo(months, months == 1 ? '' : 's');
    } else {
      final years = (difference.inDays / 365).floor();
      return l10n.yearsAgo(years, years == 1 ? '' : 's');
    }
  }
}