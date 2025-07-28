import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/qr_data_models.dart';

final textFormProvider = StateNotifierProvider<TextFormController, TextFormState>((ref) {
  return TextFormController();
});

class TextFormState {
  final String text;
  final String name;
  final bool isValid;
  final String? textError;
  final String? nameError;

  const TextFormState({
    this.text = '',
    this.name = '',
    this.isValid = false,
    this.textError,
    this.nameError,
  });

  TextFormState copyWith({
    String? text,
    String? name,
    bool? isValid,
    String? textError,
    String? nameError,
  }) {
    return TextFormState(
      text: text ?? this.text,
      name: name ?? this.name,
      isValid: isValid ?? this.isValid,
      textError: textError,
      nameError: nameError,
    );
  }

  TextData get textData => TextData(text: text);
}

class TextFormController extends StateNotifier<TextFormState> {
  TextFormController() : super(const TextFormState());

  static const int maxTextLength = 1000; // QR code capacity limit
  static const int maxNameLength = 50;

  void updateText(String text) {
    final textError = _validateText(text);
    state = state.copyWith(
      text: text,
      textError: textError,
      isValid: _validateForm(text, state.name),
    );
  }

  void updateName(String name) {
    final nameError = _validateName(name);
    state = state.copyWith(
      name: name,
      nameError: nameError,
      isValid: _validateForm(state.text, name),
    );
  }

  String? _validateText(String text) {
    if (text.isEmpty) {
      return 'Please enter your text';
    }
    
    if (text.length > maxTextLength) {
      return 'Text is too long (max $maxTextLength characters)';
    }
    
    return null;
  }
  
  String? _validateName(String name) {
    if (name.isEmpty) {
      return 'Please enter a name for your QR code';
    }
    
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (name.length > maxNameLength) {
      return 'Name is too long (max $maxNameLength characters)';
    }
    
    return null;
  }

  bool _validateForm(String text, String name) {
    return text.isNotEmpty && 
           name.isNotEmpty && 
           _validateText(text) == null && 
           _validateName(name) == null;
  }

  void reset() {
    state = const TextFormState();
  }
}

class TextForm extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const TextForm({
    super.key,
    required this.onContinue,
  });

  @override
  ConsumerState<TextForm> createState() => _TextFormState();
}

class _TextFormState extends ConsumerState<TextForm> {
  final _textController = TextEditingController();
  final _nameController = TextEditingController();
  final _textFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = ref.read(textFormProvider);
      
      // Set initial values
      _textController.text = currentState.text;
      _nameController.text = currentState.name;
      
      // Trigger validation if we have existing values
      if (currentState.text.isNotEmpty || currentState.name.isNotEmpty) {
        ref.read(textFormProvider.notifier).updateText(currentState.text);
        ref.read(textFormProvider.notifier).updateName(currentState.name);
      }
      
      // Auto-focus the first field only if it's empty
      if (currentState.text.isEmpty) {
        _textFocusNode.requestFocus();
      }
    });
    
    // Add listeners
    _textController.addListener(_onTextChanged);
    _nameController.addListener(_onNameChanged);
  }
  
  void _onTextChanged() {
    ref.read(textFormProvider.notifier).updateText(_textController.text);
  }
  
  void _onNameChanged() {
    ref.read(textFormProvider.notifier).updateName(_nameController.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    _textFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(textFormProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Text Message',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Enter any text you want to share via QR code',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 100.ms),
          
          const SizedBox(height: 32),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInputField(
                    controller: _textController,
                    focusNode: _textFocusNode,
                    label: 'Text Content',
                    hint: 'Enter your message...',
                    icon: Icons.text_fields_rounded,
                    maxLines: 5,
                    errorText: formState.textError,
                    showCharacterCount: true,
                    maxLength: TextFormController.maxTextLength,
                    delay: 200,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildInputField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    label: 'QR Code Name',
                    hint: 'My Text Message',
                    icon: Icons.label_rounded,
                    maxLines: 1,
                    delay: 300,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Character count and preview
                  Container(
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
                                  colors: [Color(0xFFEF4444), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.info_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Text Information',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Characters: ${formState.text.length}',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCharacterCountColor(formState.text.length).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getCharacterCountLabel(formState.text.length),
                                style: TextStyle(
                                  color: _getCharacterCountColor(formState.text.length),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (formState.text.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'Preview: ${formState.text.length > 100 ? '${formState.text.substring(0, 100)}...' : formState.text}',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideY(begin: 0.3, duration: 600.ms, delay: 400.ms),
                ],
              ),
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
    required int maxLines,
    String? errorText,
    bool showCharacterCount = false,
    int? maxLength,
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
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
                child: Icon(
                  icon,
                  color: errorText != null
                      ? const Color(0xFFEF4444)
                      : focusNode.hasFocus 
                          ? const Color(0xFF1A73E8)
                          : Colors.grey[400],
                ),
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
        ],
        if (showCharacterCount && maxLength != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Characters: ${controller.text.length}/$maxLength',
                style: TextStyle(
                  color: controller.text.length > maxLength 
                      ? const Color(0xFFEF4444)
                      : Colors.grey[500],
                  fontSize: 11,
                ),
              ),
              if (controller.text.length > maxLength * 0.8) ...[
                Icon(
                  controller.text.length > maxLength 
                      ? Icons.error_outline
                      : Icons.warning_amber_outlined,
                  color: controller.text.length > maxLength 
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFFF9800),
                  size: 16,
                ),
              ],
            ],
          ),
        ],
      ],
    ).animate()
      .fadeIn(duration: 600.ms, delay: delay.ms)
      .slideY(begin: 0.3, duration: 600.ms, delay: delay.ms);
  }

  Color _getCharacterCountColor(int count) {
    if (count == 0) return Colors.grey;
    if (count < 100) return const Color(0xFF10B981);
    if (count < 500) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getCharacterCountLabel(int count) {
    if (count == 0) return 'Empty';
    if (count < 100) return 'Optimal';
    if (count < 500) return 'Good';
    return 'Large';
  }
}