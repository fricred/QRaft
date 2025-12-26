import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../../../shared/widgets/glass_button.dart';
import 'edit_profile_modal.dart';

/// Displays user profile information in a read-only format
/// with an "Edit Profile" button that opens a full-screen modal for editing
class ProfileInfoSection extends ConsumerWidget {
  final UserProfileEntity? profile;

  const ProfileInfoSection({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2E2E2E).withValues(alpha: 0.7),
                  const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title
                Text(
                  l10n.personalInformation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Profile fields (read-only)
                _buildInfoRow(
                  icon: Icons.person_rounded,
                  label: l10n.displayName,
                  value: profile?.displayName,
                  l10n: l10n,
                ),
                _buildInfoRow(
                  icon: Icons.phone_rounded,
                  label: l10n.phoneNumber,
                  value: profile?.phoneNumber,
                  l10n: l10n,
                ),
                _buildInfoRow(
                  icon: Icons.info_rounded,
                  label: l10n.bio,
                  value: profile?.bio,
                  l10n: l10n,
                ),
                _buildInfoRow(
                  icon: Icons.location_on_rounded,
                  label: l10n.location,
                  value: profile?.location,
                  l10n: l10n,
                ),
                _buildInfoRow(
                  icon: Icons.language_rounded,
                  label: l10n.website,
                  value: profile?.website,
                  l10n: l10n,
                ),
                _buildInfoRow(
                  icon: Icons.business_rounded,
                  label: l10n.company,
                  value: profile?.company,
                  l10n: l10n,
                ),
                _buildInfoRow(
                  icon: Icons.work_rounded,
                  label: l10n.jobTitle,
                  value: profile?.jobTitle,
                  l10n: l10n,
                  showDivider: false,
                ),

                const SizedBox(height: 24),

                // Edit Profile Button
                PrimaryGlassButton(
                  text: l10n.editProfile,
                  icon: Icons.edit_rounded,
                  onPressed: () => _openEditModal(context),
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String? value,
    required AppLocalizations l10n,
    bool showDivider = true,
  }) {
    final hasValue = value != null && value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Value row
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: hasValue ? const Color(0xFF00FF88) : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValue ? value : l10n.notProvided,
                  style: TextStyle(
                    color: hasValue ? Colors.white : Colors.grey[500],
                    fontSize: 14,
                    fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (showDivider)
          Divider(
            color: Colors.grey[800],
            height: 1,
            thickness: 1,
          ),
        if (showDivider) const SizedBox(height: 16),
      ],
    );
  }

  void _openEditModal(BuildContext context) {
    EditProfileModal.show(context, profile);
  }
}

// Keep the old widget name for backwards compatibility during transition
// Can be removed after updating profile_screen.dart
@Deprecated('Use ProfileInfoSection instead')
class InlineEditableProfileInfo extends ProfileInfoSection {
  const InlineEditableProfileInfo({
    super.key,
    required super.profile,
    Function(String field, String? value)? onFieldSave, // Ignored, kept for compatibility
  });
}
