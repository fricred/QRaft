import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../domain/entities/qr_data_models.dart';
import '../../../../../l10n/app_localizations.dart';

final emailFormProvider = StateNotifierProvider<EmailFormController, EmailFormState>((ref) {
  return EmailFormController();
});

class EmailFormState {
  final String email;
  final String subject;
  final String body;
  final String name; // QR name for saving
  final bool isValid;
  final String? emailError;
  final String? nameError;

  const EmailFormState({
    this.email = '',
    this.subject = '',
    this.body = '',
    this.name = '',
    this.isValid = false,
    this.emailError,
    this.nameError,
  });

  EmailFormState copyWith({
    String? email,
    String? subject,
    String? body,
    String? name,
    bool? isValid,
    String? emailError,
    String? nameError,
  }) {
    return EmailFormState(
      email: email ?? this.email,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      name: name ?? this.name,
      isValid: isValid ?? this.isValid,
      emailError: emailError,
      nameError: nameError,
    );
  }

  EmailData get emailData {
    return EmailData(
      email: email.trim(),
      subject: subject.trim(),
      body: body.trim(),
    );
  }
}

class EmailFormController extends StateNotifier<EmailFormState> {
  EmailFormController() : super(const EmailFormState());

  void updateEmail(String email) {
    state = state.copyWith(
      email: email,
      emailError: null,
    );
    _validateForm();
  }

  void updateSubject(String subject) {
    state = state.copyWith(subject: subject);
    _validateForm();
  }

  void updateBody(String body) {
    state = state.copyWith(body: body);
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
    String? emailError;
    String? nameError;

    // Required fields validation
    if (state.email.trim().isEmpty) {
      emailError = 'Email address is required';
    } else if (!_isValidEmail(state.email.trim())) {
      emailError = 'Please enter a valid email address';
    }

    if (state.name.trim().isEmpty) {
      nameError = 'QR code name is required';
    } else if (state.name.trim().length < 2) {
      nameError = 'Name must be at least 2 characters';
    }

    final isValid = emailError == null && nameError == null;

    state = state.copyWith(
      isValid: isValid,
      emailError: emailError,
      nameError: nameError,
    );
  }

  bool _isValidEmail(String email) {
    // ignore: deprecated_member_use
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<bool> pickContactEmail() async {
    try {
      // Request permission to access contacts
      if (await FlutterContacts.requestPermission()) {
        // Get all contacts with emails
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withAccounts: false,
        );
        
        // Filter contacts that have email addresses
        final contactsWithEmails = contacts
            .where((contact) => contact.emails.isNotEmpty)
            .toList();
            
        if (contactsWithEmails.isEmpty) {
          return false; // No contacts with emails found
        }
        
        // Return the contacts list for the UI to handle
        return contactsWithEmails.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<Contact>> getContactsWithEmails() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withAccounts: false,
        );
        
        return contacts
            .where((contact) => contact.emails.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  void setSelectedEmail(String email) {
    state = state.copyWith(
      email: email,
      emailError: null,
    );
    _validateForm();
  }

  void reset() {
    state = const EmailFormState();
  }

  /// Load form data from an existing QR code entity (for edit mode)
  void loadFromEntity(EmailData emailData, String qrName, [AppLocalizations? l10n]) {
    state = EmailFormState(
      email: emailData.email,
      subject: emailData.subject,
      body: emailData.body,
      name: qrName,
      isValid: true, // Pre-existing data is already valid
      emailError: null,
      nameError: null,
    );

    // Trigger validation if l10n available
    if (l10n != null) {
      _validateForm();
    }
  }
}

class EmailForm extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const EmailForm({
    super.key,
    required this.onContinue,
  });

  @override
  ConsumerState<EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends ConsumerState<EmailForm> {
  final _scrollController = ScrollController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing provider state (for edit mode)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = ref.read(emailFormProvider);

      // Set initial values
      _emailController.text = currentState.email;
      _subjectController.text = currentState.subject;
      _bodyController.text = currentState.body;
      _nameController.text = currentState.name;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailFormProvider);
    final controller = ref.read(emailFormProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.emailFormTitle ?? 'Email',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            AppLocalizations.of(context)?.emailFormSubtitle ?? 'Create QR code for sending pre-filled email',
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
                    hint: AppLocalizations.of(context)?.emailQrNameHint ?? 'Email QR',
                    icon: Icons.label_outline_rounded,
                    error: state.nameError,
                    onChanged: controller.updateName,
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 200.ms),

                  const SizedBox(height: 20),

                  // Email field with contact picker
                  _buildEmailFieldWithPicker(
                    controller: _emailController,
                    label: AppLocalizations.of(context)?.emailRecipientLabel ?? 'Email Address *',
                    hint: AppLocalizations.of(context)?.emailRecipientHint ?? 'recipient@example.com',
                    error: state.emailError,
                    onChanged: controller.updateEmail,
                    onPickContact: () => _handlePickContact(controller),
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 300.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 300.ms),

                  const SizedBox(height: 20),

                  // Subject field
                  _buildTextField(
                    controller: _subjectController,
                    label: AppLocalizations.of(context)?.emailSubjectLabel ?? 'Subject',
                    hint: AppLocalizations.of(context)?.emailSubjectHint ?? 'Email subject...',
                    icon: Icons.subject_outlined,
                    onChanged: controller.updateSubject,
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 400.ms),

                  const SizedBox(height: 20),

                  // Body field
                  _buildTextField(
                    controller: _bodyController,
                    label: AppLocalizations.of(context)?.emailBodyLabel ?? 'Message',
                    hint: AppLocalizations.of(context)?.emailBodyHint ?? 'Type your message here...',
                    icon: Icons.message_outlined,
                    onChanged: controller.updateBody,
                    maxLines: 5,
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 500.ms)
                    .slideX(begin: -0.3, duration: 600.ms, delay: 500.ms),

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

  Widget _buildEmailFieldWithPicker({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    required VoidCallback onPickContact,
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
              // Email icon and input field
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: TextInputType.emailAddress,
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
                      Icons.email_outlined,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              
              // Contact picker button
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onPickContact,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.contacts_rounded,
                        color: const Color(0xFF1A73E8),
                        size: 20,
                      ),
                    ),
                  ),
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

  Future<void> _handlePickContact(EmailFormController controller) async {
    try {
      // Check if permission is available first
      if (!await FlutterContacts.requestPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts permission is required to import email addresses'),
              backgroundColor: Color(0xFFEF4444),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      final contacts = await controller.getContactsWithEmails();
      
      if (contacts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No contacts with email addresses found'),
              backgroundColor: Color(0xFFF59E0B),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      if (mounted) {
        final selectedEmail = await _showContactPickerDialog(contacts);
        
        if (selectedEmail != null) {
          controller.setSelectedEmail(selectedEmail);
          _emailController.text = selectedEmail;
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact email imported successfully!'),
                backgroundColor: Color(0xFF00FF88),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Contact picker error: $e');
      if (mounted) {
        String errorMessage = 'Failed to import contact';
        if (e.toString().contains('permission')) {
          errorMessage = 'Contacts permission denied. Please enable it in device settings.';
        } else if (e.toString().contains('not available')) {
          errorMessage = 'Contact access is not available on this device.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<String?> _showContactPickerDialog(List<Contact> contacts) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Select Contact Email',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: contacts.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.white.withValues(alpha: 0.1),
                thickness: 1,
              ),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: contact.emails.map((email) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1A73E8),
                        child: Text(
                          contact.displayName.isNotEmpty 
                              ? contact.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.displayName.isNotEmpty 
                            ? contact.displayName
                            : 'Unknown Contact',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        email.address,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop(email.address);
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}