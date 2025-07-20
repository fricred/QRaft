import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile_entity.dart';

class ProfileInfoSection extends ConsumerStatefulWidget {
  final UserProfileEntity? profile;
  final bool isEditing;
  final Function(Map<String, String?>) onSave;
  final VoidCallback onCancel;

  const ProfileInfoSection({
    super.key,
    required this.profile,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  });

  @override
  ConsumerState<ProfileInfoSection> createState() => _ProfileInfoSectionState();
}

class _ProfileInfoSectionState extends ConsumerState<ProfileInfoSection> {
  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _companyController;
  late TextEditingController _jobTitleController;
  
  // Individual editing states for each field

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _displayNameController = TextEditingController(text: widget.profile?.displayName ?? '');
    _phoneController = TextEditingController(text: widget.profile?.phoneNumber ?? '');
    _bioController = TextEditingController(text: widget.profile?.bio ?? '');
    _locationController = TextEditingController(text: widget.profile?.location ?? '');
    _websiteController = TextEditingController(text: widget.profile?.website ?? '');
    _companyController = TextEditingController(text: widget.profile?.company ?? '');
    _jobTitleController = TextEditingController(text: widget.profile?.jobTitle ?? '');
  }

  @override
  void didUpdateWidget(ProfileInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile || oldWidget.isEditing != widget.isEditing) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    _displayNameController.text = widget.profile?.displayName ?? '';
    _phoneController.text = widget.profile?.phoneNumber ?? '';
    _bioController.text = widget.profile?.bio ?? '';
    _locationController.text = widget.profile?.location ?? '';
    _websiteController.text = widget.profile?.website ?? '';
    _companyController.text = widget.profile?.company ?? '';
    _jobTitleController.text = widget.profile?.jobTitle ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Display Name
          _buildInfoField(
            label: 'Display Name',
            controller: _displayNameController,
            icon: Icons.person_rounded,
            isEditing: widget.isEditing,
            displayValue: widget.profile?.displayName,
          ),

          const SizedBox(height: 16),

          // Phone Number
          _buildInfoField(
            label: 'Phone Number',
            controller: _phoneController,
            icon: Icons.phone_rounded,
            isEditing: widget.isEditing,
            displayValue: widget.profile?.phoneNumber,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 16),

          // Bio
          _buildInfoField(
            label: 'Bio',
            controller: _bioController,
            icon: Icons.info_rounded,
            isEditing: widget.isEditing,
            displayValue: widget.profile?.bio,
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          // Location
          _buildInfoField(
            label: 'Location',
            controller: _locationController,
            icon: Icons.location_on_rounded,
            isEditing: widget.isEditing,
            displayValue: widget.profile?.location,
          ),

          const SizedBox(height: 16),

          // Website
          _buildInfoField(
            label: 'Website',
            controller: _websiteController,
            icon: Icons.language_rounded,
            isEditing: widget.isEditing,
            displayValue: widget.profile?.website,
            keyboardType: TextInputType.url,
          ),

          const SizedBox(height: 16),

          // Company
          _buildInfoField(
            label: 'Company',
            controller: _companyController,
            icon: Icons.business_rounded,
            isEditing: widget.isEditing,
            displayValue: widget.profile?.company,
          ),

          const SizedBox(height: 16),

          // Job Title
          _buildInfoField(
            label: 'Job Title',
            controller: _jobTitleController,
            icon: Icons.work_rounded,
            isEditing: widget.isEditing,
            displayValue: widget.profile?.jobTitle,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    String? displayValue,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    if (!isEditing) {
      return _buildDisplayField(
        label: label,
        value: displayValue,
        icon: icon,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF00FF88), size: 20),
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF00FF88),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayField({
    required String label,
    String? value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF00FF88),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value?.isNotEmpty == true ? value! : 'Not provided',
                style: TextStyle(
                  color: value?.isNotEmpty == true ? Colors.white : Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}