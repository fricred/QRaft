import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/qr_data_models.dart';
import '../../../../../l10n/app_localizations.dart';

final urlFormProvider = StateNotifierProvider<URLFormController, URLFormState>((ref) {
  return URLFormController();
});

class URLFormState {
  final String url;
  final String name;
  final bool isValid;
  final String? urlError;
  final String? nameError;

  const URLFormState({
    this.url = '',
    this.name = '',
    this.isValid = false,
    this.urlError,
    this.nameError,
  });

  URLFormState copyWith({
    String? url,
    String? name,
    bool? isValid,
    String? urlError,
    String? nameError,
  }) {
    return URLFormState(
      url: url ?? this.url,
      name: name ?? this.name,
      isValid: isValid ?? this.isValid,
      urlError: urlError,
      nameError: nameError,
    );
  }

  URLData get urlData {
    final controller = URLFormController();
    return URLData(url: controller.getFormattedURL(url));
  }
}

class URLFormController extends StateNotifier<URLFormState> {
  URLFormController() : super(const URLFormState());

  void updateURL(String url, [AppLocalizations? l10n]) {
    final urlError = l10n != null ? _validateURL(url, l10n) : null;
    state = state.copyWith(
      url: url,
      urlError: urlError,
      isValid: l10n != null ? _validateForm(url, state.name, l10n) : false,
    );
  }

  void updateName(String name, [AppLocalizations? l10n]) {
    final nameError = l10n != null ? _validateName(name, l10n) : null;
    state = state.copyWith(
      name: name,
      nameError: nameError,
      isValid: l10n != null ? _validateForm(state.url, name, l10n) : false,
    );
  }

  bool _validateForm(String url, String name, AppLocalizations l10n) {
    return url.isNotEmpty && 
           name.isNotEmpty && 
           _validateURL(url, l10n) == null && 
           _validateName(name, l10n) == null;
  }

  String? _validateURL(String url, AppLocalizations l10n) {
    if (url.isEmpty) {
      return l10n.urlValidationEmpty;
    }

    // Clean the URL by trimming spaces
    final cleanUrl = url.trim();

    // Check for spaces in URL
    if (cleanUrl.contains(' ')) {
      return l10n.urlValidationSpaces;
    }

    // Add protocol if missing
    String urlToValidate = cleanUrl;
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      urlToValidate = 'https://$cleanUrl';
    }

    // Validate URI structure
    final uri = Uri.tryParse(urlToValidate);
    if (uri == null) {
      return l10n.urlValidationInvalid;
    }

    // Check if host exists
    if (uri.host.isEmpty) {
      return l10n.urlValidationDomain;
    }

    // Check for valid domain format (at least one dot)
    if (!uri.host.contains('.') || uri.host.startsWith('.') || uri.host.endsWith('.')) {
      return l10n.urlValidationDomain;
    }

    // Check for common domain patterns
    final domainRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.([a-zA-Z]{2,}|[a-zA-Z]{2,}\.[a-zA-Z]{2,})$');
    if (!domainRegex.hasMatch(uri.host)) {
      return l10n.urlValidationDomain;
    }

    // Check for minimum length
    if (cleanUrl.length < 3) {
      return l10n.urlValidationInvalid;
    }

    return null; // Valid URL
  }

  String? _validateName(String name, AppLocalizations? l10n) {
    if (name.isEmpty) {
      return l10n?.pleaseEnterName ?? 'Please enter your name';
    }

    if (name.length < 2) {
      return l10n?.nameMinLength ?? 'Name must be at least 2 characters';
    }

    if (name.length > 50) {
      return 'Name is too long';
    }

    return null; // Valid name
  }

  String getFormattedURL(String url) {
    final cleanUrl = url.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      return 'https://$cleanUrl';
    }
    return cleanUrl;
  }

  void reset() {
    state = const URLFormState();
  }
}

class URLForm extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const URLForm({
    super.key,
    required this.onContinue,
  });

  @override
  ConsumerState<URLForm> createState() => _URLFormState();
}

class _URLFormState extends ConsumerState<URLForm> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _urlFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    _urlController.addListener(() {
      final l10n = AppLocalizations.of(context);
      ref.read(urlFormProvider.notifier).updateURL(_urlController.text, l10n);
    });
    
    _nameController.addListener(() {
      final l10n = AppLocalizations.of(context);
      ref.read(urlFormProvider.notifier).updateName(_nameController.text, l10n);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _urlFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(urlFormProvider);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.qrFormWebsiteUrl ?? 'Website URL',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Enter the website URL you want to share',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 100.ms),
          
          const SizedBox(height: 32),
          
          Expanded(
            child: Column(
              children: [
                  _buildInputField(
                    controller: _urlController,
                    focusNode: _urlFocusNode,
                    label: l10n?.urlFieldLabel ?? 'Website URL',
                    hint: l10n?.urlFieldPlaceholder ?? 'example.com or https://example.com',
                    helperText: 'Protocol (https://) will be added automatically',
                    icon: Icons.link_rounded,
                    keyboardType: TextInputType.url,
                    errorText: formState.urlError,
                    delay: 200,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildInputField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    label: 'QR Code Name',
                    hint: 'My Website',
                    helperText: 'This name will help you identify your QR code',
                    icon: Icons.label_rounded,
                    keyboardType: TextInputType.text,
                    errorText: formState.nameError,
                    delay: 300,
                  ),
                  
                const SizedBox(height: 32),
                
                // Preview container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1A73E8), Color(0xFF6366F1)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.visibility_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n?.preview ?? 'Preview',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                        if (formState.url.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                formState.urlError == null ? Icons.check_circle : Icons.error,
                                color: formState.urlError == null 
                                    ? const Color(0xFF10B981) 
                                    : const Color(0xFFEF4444),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'URL: ${ref.read(urlFormProvider.notifier).getFormattedURL(formState.url)}',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (formState.urlError != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        formState.urlError!,
                                        style: const TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (formState.name.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                formState.nameError == null ? Icons.check_circle : Icons.error,
                                color: formState.nameError == null 
                                    ? const Color(0xFF10B981) 
                                    : const Color(0xFFEF4444),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Name: ${formState.name}',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (formState.nameError != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        formState.nameError!,
                                        style: const TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (formState.url.isEmpty && formState.name.isEmpty) ...[
                          Text(
                            'Fill in the form to see preview',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'Valid URL examples:',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...[ 
                            'google.com',
                            'https://example.com',
                            'docs.flutter.dev/guides',
                            'github.com/user/repo',
                          ].map((example) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFF10B981),
                                  size: 12,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  example,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideY(begin: 0.3, duration: 600.ms, delay: 400.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    String? errorText,
    String? helperText,
    required int delay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFEF4444)
                  : focusNode.hasFocus 
                      ? const Color(0xFF1A73E8)
                      : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(
                icon,
                color: errorText != null
                    ? const Color(0xFFEF4444)
                    : focusNode.hasFocus 
                        ? const Color(0xFF1A73E8)
                        : Colors.grey[400],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12,
            ),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ],
    ).animate()
      .fadeIn(duration: 600.ms, delay: delay.ms)
      .slideY(begin: 0.3, duration: 600.ms, delay: delay.ms);
  }
}