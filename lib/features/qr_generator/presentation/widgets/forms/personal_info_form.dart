import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone_form_field/phone_form_field.dart';
import '../../../domain/entities/qr_data_models.dart';
import '../../../../../l10n/app_localizations.dart';

final personalInfoFormProvider = StateNotifierProvider<PersonalInfoFormController, PersonalInfoFormState>((ref) {
  return PersonalInfoFormController();
});

class PersonalInfoFormState {
  final String firstName;
  final String lastName;
  final String organization;
  final String jobTitle;
  final String phone;
  final String email;
  final String website;
  final String address;
  final String note;
  final String name; // QR name for saving
  final bool isValid;
  final String? firstNameError;
  final String? lastNameError;
  final String? emailError;
  final String? phoneError;
  final String? nameError;

  const PersonalInfoFormState({
    this.firstName = '',
    this.lastName = '',
    this.organization = '',
    this.jobTitle = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.address = '',
    this.note = '',
    this.name = '',
    this.isValid = false,
    this.firstNameError,
    this.lastNameError,
    this.emailError,
    this.phoneError,
    this.nameError,
  });

  PersonalInfoFormState copyWith({
    String? firstName,
    String? lastName,
    String? organization,
    String? jobTitle,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? note,
    String? name,
    bool? isValid,
    String? firstNameError,
    String? lastNameError,
    String? emailError,
    String? phoneError,
    String? nameError,
  }) {
    return PersonalInfoFormState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      organization: organization ?? this.organization,
      jobTitle: jobTitle ?? this.jobTitle,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      note: note ?? this.note,
      name: name ?? this.name,
      isValid: isValid ?? this.isValid,
      firstNameError: firstNameError,
      lastNameError: lastNameError,
      emailError: emailError,
      phoneError: phoneError,
      nameError: nameError,
    );
  }

  PersonalInfoData get personalInfoData {
    return PersonalInfoData(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      organization: organization.trim(),
      jobTitle: jobTitle.trim(),
      phone: phone.trim(),
      email: email.trim(),
      website: website.trim(),
      address: address.trim(),
      note: note.trim(),
    );
  }
}

class PersonalInfoFormController extends StateNotifier<PersonalInfoFormState> {
  PersonalInfoFormController() : super(const PersonalInfoFormState());

  void updateFirstName(String firstName) {
    state = state.copyWith(
      firstName: firstName,
      firstNameError: null,
    );
    _validateForm();
  }

  void updateLastName(String lastName) {
    state = state.copyWith(
      lastName: lastName,
      lastNameError: null,
    );
    _validateForm();
  }

  void updateOrganization(String organization) {
    state = state.copyWith(organization: organization);
    _validateForm();
  }

  void updateJobTitle(String jobTitle) {
    state = state.copyWith(jobTitle: jobTitle);
    _validateForm();
  }

  void updatePhone(String phone) {
    state = state.copyWith(
      phone: phone,
      phoneError: null,
    );
    _validateForm();
  }

  void updateEmail(String email) {
    state = state.copyWith(
      email: email,
      emailError: null,
    );
    _validateForm();
  }

  void updateWebsite(String website) {
    state = state.copyWith(website: website);
    _validateForm();
  }

  void updateAddress(String address) {
    state = state.copyWith(address: address);
    _validateForm();
  }

  void updateNote(String note) {
    state = state.copyWith(note: note);
    _validateForm();
  }

  void updateName(String name) {
    state = state.copyWith(
      name: name,
      nameError: null,
    );
    _validateForm();
  }

  void _validateForm() {
    String? firstNameError;
    String? lastNameError;
    String? emailError;
    String? phoneError;
    String? nameError;

    // Required fields validation
    if (state.firstName.trim().isEmpty) {
      firstNameError = 'First name is required';
    }

    if (state.lastName.trim().isEmpty) {
      lastNameError = 'Last name is required';
    }

    if (state.name.trim().isEmpty) {
      nameError = 'QR code name is required';
    } else if (state.name.trim().length < 2) {
      nameError = 'Name must be at least 2 characters';
    }

    // Optional but validate if provided
    if (state.email.trim().isNotEmpty && !_isValidEmail(state.email.trim())) {
      emailError = 'Please enter a valid email address';
    }

    if (state.phone.trim().isNotEmpty && !_isValidPhone(state.phone.trim())) {
      phoneError = 'Please enter a valid phone number';
    }

    final isValid = firstNameError == null &&
                   lastNameError == null &&
                   emailError == null &&
                   phoneError == null &&
                   nameError == null;

    state = state.copyWith(
      isValid: isValid,
      firstNameError: firstNameError,
      lastNameError: lastNameError,
      emailError: emailError,
      phoneError: phoneError,
      nameError: nameError,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Allow various phone formats
    return RegExp(r'^[\+]?[0-9\-\s\(\)]{10,}$').hasMatch(phone);
  }

  void reset() {
    state = const PersonalInfoFormState();
  }
}

class PersonalInfoForm extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const PersonalInfoForm({
    super.key,
    required this.onContinue,
  });

  @override
  ConsumerState<PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends ConsumerState<PersonalInfoForm> {
  final _scrollController = ScrollController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _organizationController.dispose();
    _jobTitleController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalInfoFormProvider);
    final controller = ref.read(personalInfoFormProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.personalInfoFormTitle ?? 'Personal Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            AppLocalizations.of(context)?.personalInfoFormSubtitle ?? 'Create a vCard with your contact information',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 100.ms),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // QR Name field
                  _buildTextField(
                    controller: _nameController,
                    label: AppLocalizations.of(context)?.qrCodeNameLabel ?? 'QR Code Name *',
                    hint: AppLocalizations.of(context)?.qrCodeNameHint ?? 'My Contact Card',
                    icon: Icons.label_outline_rounded,
                    error: state.nameError,
                    onChanged: controller.updateName,
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 200.ms),

                  const SizedBox(height: 20),

                  // Name fields row
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _firstNameController,
                          label: AppLocalizations.of(context)?.firstName ?? 'First Name *',
                          hint: AppLocalizations.of(context)?.firstNameHint ?? 'John',
                          icon: Icons.person_outline_rounded,
                          error: state.firstNameError,
                          onChanged: controller.updateFirstName,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _lastNameController,
                          label: AppLocalizations.of(context)?.lastName ?? 'Last Name *',
                          hint: AppLocalizations.of(context)?.lastNameHint ?? 'Doe',
                          icon: Icons.person_outline_rounded,
                          error: state.lastNameError,
                          onChanged: controller.updateLastName,
                        ),
                      ),
                    ],
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 300.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 300.ms),

                  const SizedBox(height: 20),

                  // Organization field
                  _buildTextField(
                    controller: _organizationController,
                    label: AppLocalizations.of(context)?.organization ?? 'Organization',
                    hint: AppLocalizations.of(context)?.organizationHint ?? 'Acme Corporation',
                    icon: Icons.business_outlined,
                    onChanged: controller.updateOrganization,
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 400.ms),

                  const SizedBox(height: 20),

                  // Job Title field
                  _buildTextField(
                    controller: _jobTitleController,
                    label: AppLocalizations.of(context)?.jobTitle ?? 'Job Title',
                    hint: 'Software Developer',
                    icon: Icons.work_outline_rounded,
                    onChanged: controller.updateJobTitle,
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 500.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 500.ms),

                  const SizedBox(height: 20),

                  // Phone field
                  _buildPhoneField(
                    controller: controller,
                    error: state.phoneError,
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 600.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 600.ms),

                  const SizedBox(height: 20),

                  // Email field
                  _buildTextField(
                    controller: _emailController,
                    label: AppLocalizations.of(context)?.email ?? 'Email',
                    hint: AppLocalizations.of(context)?.emailHint ?? 'john@example.com',
                    icon: Icons.email_outlined,
                    error: state.emailError,
                    onChanged: controller.updateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 700.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 700.ms),

                  const SizedBox(height: 20),

                  // Website field
                  _buildTextField(
                    controller: _websiteController,
                    label: AppLocalizations.of(context)?.website ?? 'Website',
                    hint: AppLocalizations.of(context)?.websiteHint ?? 'https://johndoe.com',
                    icon: Icons.language_outlined,
                    onChanged: controller.updateWebsite,
                    keyboardType: TextInputType.url,
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 800.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 800.ms),

                  const SizedBox(height: 20),

                  // Address field
                  _buildTextField(
                    controller: _addressController,
                    label: AppLocalizations.of(context)?.address ?? 'Address',
                    hint: AppLocalizations.of(context)?.addressHint ?? '123 Main St, City, State 12345',
                    icon: Icons.location_on_outlined,
                    onChanged: controller.updateAddress,
                    maxLines: 2,
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 900.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 900.ms),

                  const SizedBox(height: 20),

                  // Note field
                  _buildTextField(
                    controller: _noteController,
                    label: AppLocalizations.of(context)?.note ?? 'Note',
                    hint: AppLocalizations.of(context)?.noteHint ?? 'Additional information...',
                    icon: Icons.note_outlined,
                    onChanged: controller.updateNote,
                    maxLines: 3,
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 1000.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 1000.ms),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    String? error,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null 
                  ? Colors.red.withValues(alpha: 0.5) 
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            maxLines: maxLines ?? 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.grey[400],
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneField({
    required PersonalInfoFormController controller,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null 
                  ? Colors.red.withValues(alpha: 0.5) 
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Phone icon to match other inputs
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(
                  Icons.phone_outlined,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ),
              // Phone input
              Expanded(
                child: PhoneFormField(
                  onChanged: (PhoneNumber? number) {
                    if (number != null) {
                      controller.updatePhone(number.international);
                    } else {
                      controller.updatePhone('');
                    }
                  },
                  initialValue: PhoneNumber.parse('+57'), // Default to Colombia
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)?.phoneHint ?? '(555) 123-4567',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                  ),
                  validator: null, // We handle validation in the controller
                  autovalidateMode: AutovalidateMode.disabled,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  countrySelectorNavigator: const CountrySelectorNavigator.bottomSheet(),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[ 
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}