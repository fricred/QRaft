import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../../domain/entities/user_profile_entity.dart';

class InlineEditableProfileInfo extends ConsumerStatefulWidget {
  final UserProfileEntity? profile;
  final Function(String field, String? value) onFieldSave;

  const InlineEditableProfileInfo({
    super.key,
    required this.profile,
    required this.onFieldSave,
  });

  @override
  ConsumerState<InlineEditableProfileInfo> createState() => _InlineEditableProfileInfoState();
}

class _InlineEditableProfileInfoState extends ConsumerState<InlineEditableProfileInfo> {
  String? _currentEditingField;
  bool _isUpdating = false;
  
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers['display_name'] = TextEditingController(text: widget.profile?.displayName ?? '');
    _controllers['phone_number'] = TextEditingController(text: widget.profile?.phoneNumber ?? '');
    _controllers['bio'] = TextEditingController(text: widget.profile?.bio ?? '');
    _controllers['location'] = TextEditingController(text: widget.profile?.location ?? '');
    _controllers['website'] = TextEditingController(text: widget.profile?.website ?? '');
    _controllers['company'] = TextEditingController(text: widget.profile?.company ?? '');
    _controllers['job_title'] = TextEditingController(text: widget.profile?.jobTitle ?? '');
  }

  @override
  void didUpdateWidget(InlineEditableProfileInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    _controllers['display_name']?.text = widget.profile?.displayName ?? '';
    _controllers['phone_number']?.text = widget.profile?.phoneNumber ?? '';
    _controllers['bio']?.text = widget.profile?.bio ?? '';
    _controllers['location']?.text = widget.profile?.location ?? '';
    _controllers['website']?.text = widget.profile?.website ?? '';
    _controllers['company']?.text = widget.profile?.company ?? '';
    _controllers['job_title']?.text = widget.profile?.jobTitle ?? '';
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startFieldEdit(String fieldKey) {
    setState(() {
      _currentEditingField = fieldKey;
    });
  }

  void _cancelFieldEdit() {
    setState(() {
      _currentEditingField = null;
      _isUpdating = false;
    });
    // Reset controller value
    if (_currentEditingField != null) {
      _updateControllers();
    }
  }

  Future<void> _saveField(String fieldKey, String? value) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await widget.onFieldSave(fieldKey, value?.isEmpty == true ? null : value);
      setState(() {
        _currentEditingField = null;
        _isUpdating = false;
      });
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToUpdate(fieldKey, e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
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
            l10n.personalInformation,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Display Name
          _buildEditableField(
            context: context,
            fieldKey: 'display_name',
            label: l10n.displayName,
            icon: Icons.person_rounded,
            currentValue: widget.profile?.displayName,
          ),

          // Phone Number
          _buildEditableField(
            context: context,
            fieldKey: 'phone_number',
            label: l10n.phoneNumber,
            icon: Icons.phone_rounded,
            currentValue: widget.profile?.phoneNumber,
            keyboardType: TextInputType.phone,
          ),

          // Bio
          _buildEditableField(
            context: context,
            fieldKey: 'bio',
            label: l10n.bio,
            icon: Icons.info_rounded,
            currentValue: widget.profile?.bio,
            maxLines: 3,
          ),

          // Location
          _buildEditableField(
            context: context,
            fieldKey: 'location',
            label: l10n.location,
            icon: Icons.location_on_rounded,
            currentValue: widget.profile?.location,
          ),

          // Website
          _buildEditableField(
            context: context,
            fieldKey: 'website',
            label: l10n.website,
            icon: Icons.language_rounded,
            currentValue: widget.profile?.website,
            keyboardType: TextInputType.url,
          ),

          // Company
          _buildEditableField(
            context: context,
            fieldKey: 'company',
            label: l10n.company,
            icon: Icons.business_rounded,
            currentValue: widget.profile?.company,
          ),

          // Job Title
          _buildEditableField(
            context: context,
            fieldKey: 'job_title',
            label: l10n.jobTitle,
            icon: Icons.work_rounded,
            currentValue: widget.profile?.jobTitle,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required BuildContext context,
    required String fieldKey,
    required String label,
    required IconData icon,
    String? currentValue,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool showDivider = true,
  }) {
    final isCurrentlyEditing = _currentEditingField == fieldKey;
    final controller = _controllers[fieldKey]!;
    
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
        
        if (isCurrentlyEditing) ...[
          // Editing mode
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, color: const Color(0xFF00FF88), size: 20),
                    hintText: AppLocalizations.of(context)!.enterField(label),
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00FF88), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                // Action buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isUpdating ? null : _cancelFieldEdit,
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(
                            color: _isUpdating ? Colors.grey[600] : Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isUpdating ? null : () => _saveField(fieldKey, controller.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF88),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                        ),
                        icon: _isUpdating 
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : Icon(Icons.check, size: 14),
                        label: Text(
                          _isUpdating ? AppLocalizations.of(context)!.saving : AppLocalizations.of(context)!.save,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Display mode
          GestureDetector(
            onTap: () => _startFieldEdit(fieldKey),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.grey[500], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      currentValue?.isNotEmpty == true ? currentValue! : AppLocalizations.of(context)!.notProvided,
                      style: TextStyle(
                        color: currentValue?.isNotEmpty == true ? Colors.white : Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit_rounded,
                    color: const Color(0xFF00FF88).withValues(alpha: 0.7),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
        
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
}