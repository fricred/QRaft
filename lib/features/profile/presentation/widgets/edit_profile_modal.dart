import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../controllers/profile_controller.dart';
import '../../../../shared/widgets/glass_button.dart';
import 'profile_form_field.dart';

class EditProfileModal extends ConsumerStatefulWidget {
  final UserProfileEntity? profile;

  const EditProfileModal({
    super.key,
    required this.profile,
  });

  /// Show the edit profile modal
  static Future<bool?> show(BuildContext context, UserProfileEntity? profile) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModal(profile: profile),
    );
  }

  @override
  ConsumerState<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends ConsumerState<EditProfileModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _companyController;
  late TextEditingController _jobTitleController;

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _displayNameController = TextEditingController(text: widget.profile?.displayName ?? '');
    _phoneController = TextEditingController(text: widget.profile?.phoneNumber ?? '');
    _bioController = TextEditingController(text: widget.profile?.bio ?? '');
    _locationController = TextEditingController(text: widget.profile?.location ?? '');
    _websiteController = TextEditingController(text: widget.profile?.website ?? '');
    _companyController = TextEditingController(text: widget.profile?.company ?? '');
    _jobTitleController = TextEditingController(text: widget.profile?.jobTitle ?? '');

    // Listen for changes
    _displayNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);
    _websiteController.addListener(_onFieldChanged);
    _companyController.addListener(_onFieldChanged);
    _jobTitleController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final hasChanges = _displayNameController.text != (widget.profile?.displayName ?? '') ||
        _phoneController.text != (widget.profile?.phoneNumber ?? '') ||
        _bioController.text != (widget.profile?.bio ?? '') ||
        _locationController.text != (widget.profile?.location ?? '') ||
        _websiteController.text != (widget.profile?.website ?? '') ||
        _companyController.text != (widget.profile?.company ?? '') ||
        _jobTitleController.text != (widget.profile?.jobTitle ?? '');

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    // Remove listeners first to prevent memory leaks
    _displayNameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _bioController.removeListener(_onFieldChanged);
    _locationController.removeListener(_onFieldChanged);
    _websiteController.removeListener(_onFieldChanged);
    _companyController.removeListener(_onFieldChanged);
    _jobTitleController.removeListener(_onFieldChanged);

    // Then dispose controllers
    _displayNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // Validate form
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(profileControllerProvider.notifier).updateProfile(
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        company: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        jobTitle: _jobTitleController.text.trim().isEmpty
            ? null
            : _jobTitleController.text.trim(),
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF00FF88)),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)?.profileUpdatedSuccess ?? 'Profile updated successfully',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E2E2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)?.failedToUpdateProfile ?? 'Failed to update profile'}: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E2E2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateForm() {
    // Validate display name
    final displayNameError = ProfileValidators.displayName(_displayNameController.text);
    if (displayNameError != null) {
      _showValidationError(displayNameError);
      return false;
    }

    // Validate phone
    final phoneError = ProfileValidators.phone(_phoneController.text);
    if (phoneError != null) {
      _showValidationError(phoneError);
      return false;
    }

    // Validate bio
    final bioError = ProfileValidators.bio(_bioController.text);
    if (bioError != null) {
      _showValidationError(bioError);
      return false;
    }

    // Validate website
    final websiteError = ProfileValidators.url(_websiteController.text);
    if (websiteError != null) {
      _showValidationError(websiteError);
      return false;
    }

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF2E2E2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleClose() async {
    if (_hasChanges) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            AppLocalizations.of(context)?.discardChanges ?? 'Discard changes?',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            AppLocalizations.of(context)?.discardChangesMessage ??
                'You have unsaved changes. Are you sure you want to discard them?',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppLocalizations.of(context)?.keepEditing ?? 'Keep Editing',
                style: const TextStyle(color: Color(0xFF00FF88)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocalizations.of(context)?.discard ?? 'Discard',
                style: TextStyle(color: Colors.red[400]),
              ),
            ),
          ],
        ),
      );

      if (shouldDiscard == true && mounted) {
        Navigator.of(context).pop(false);
      }
    } else {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(l10n),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: bottomPadding + 100, // Space for bottom button
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Details Section
                    _buildSection(
                      title: l10n?.personalDetails ?? 'PERSONAL DETAILS',
                      children: [
                        ProfileFormField(
                          label: l10n?.displayName ?? 'Display Name',
                          icon: Icons.person_rounded,
                          controller: _displayNameController,
                          isRequired: true,
                          validator: ProfileValidators.displayName,
                          hintText: l10n?.enterDisplayName ?? 'Enter your name',
                        ),
                        const SizedBox(height: 20),
                        ProfileFormField(
                          label: l10n?.phoneNumber ?? 'Phone Number',
                          icon: Icons.phone_rounded,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: ProfileValidators.phone,
                          hintText: l10n?.enterPhoneNumber ?? '+1 234 567 8900',
                        ),
                        const SizedBox(height: 20),
                        ProfileFormField(
                          label: l10n?.bio ?? 'Bio',
                          icon: Icons.info_rounded,
                          controller: _bioController,
                          maxLines: 3,
                          maxLength: 500,
                          showCharacterCount: true,
                          validator: ProfileValidators.bio,
                          hintText: l10n?.enterBio ?? 'Tell us about yourself...',
                        ),
                      ],
                      index: 0,
                    ),

                    const SizedBox(height: 24),

                    // Work & Social Section
                    _buildSection(
                      title: l10n?.workAndSocial ?? 'WORK & SOCIAL',
                      children: [
                        ProfileFormField(
                          label: l10n?.location ?? 'Location',
                          icon: Icons.location_on_rounded,
                          controller: _locationController,
                          hintText: l10n?.enterLocation ?? 'City, Country',
                        ),
                        const SizedBox(height: 20),
                        ProfileFormField(
                          label: l10n?.website ?? 'Website',
                          icon: Icons.language_rounded,
                          controller: _websiteController,
                          keyboardType: TextInputType.url,
                          validator: ProfileValidators.url,
                          hintText: 'https://example.com',
                        ),
                        const SizedBox(height: 20),
                        ProfileFormField(
                          label: l10n?.company ?? 'Company',
                          icon: Icons.business_rounded,
                          controller: _companyController,
                          hintText: l10n?.enterCompany ?? 'Your company name',
                        ),
                        const SizedBox(height: 20),
                        ProfileFormField(
                          label: l10n?.jobTitle ?? 'Job Title',
                          icon: Icons.work_rounded,
                          controller: _jobTitleController,
                          hintText: l10n?.enterJobTitle ?? 'Your job title',
                        ),
                      ],
                      index: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom save button
          _buildBottomBar(l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: _handleClose,
            tooltip: l10n?.close ?? 'Close',
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),

          // Title
          Expanded(
            child: Text(
              l10n?.editProfile ?? 'Edit Profile',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Save button (header)
          TextButton(
            onPressed: _hasChanges && !_isLoading ? _handleSave : null,
            child: Text(
              l10n?.save ?? 'Save',
              style: TextStyle(
                color: _hasChanges && !_isLoading
                    ? const Color(0xFF00FF88)
                    : Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required int index,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withValues(alpha: 0.08),
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
                // Section title
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (100 * index).ms)
      .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
      .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOutQuart);
  }

  Widget _buildBottomBar(AppLocalizations? l10n) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: PrimaryGlassButton(
        text: _isLoading
            ? (l10n?.saving ?? 'Saving...')
            : (l10n?.saveChanges ?? 'Save Changes'),
        onPressed: _hasChanges && !_isLoading ? _handleSave : null,
        isLoading: _isLoading,
        width: double.infinity,
      ),
    );
  }
}
