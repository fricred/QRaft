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

  const TextFormState({
    this.text = '',
    this.name = '',
    this.isValid = false,
  });

  TextFormState copyWith({
    String? text,
    String? name,
    bool? isValid,
  }) {
    return TextFormState(
      text: text ?? this.text,
      name: name ?? this.name,
      isValid: isValid ?? this.isValid,
    );
  }

  TextData get textData => TextData(text: text);
}

class TextFormController extends StateNotifier<TextFormState> {
  TextFormController() : super(const TextFormState());

  void updateText(String text) {
    state = state.copyWith(
      text: text,
      isValid: _validateForm(text, state.name),
    );
  }

  void updateName(String name) {
    state = state.copyWith(
      name: name,
      isValid: _validateForm(state.text, name),
    );
  }

  bool _validateForm(String text, String name) {
    return text.isNotEmpty && name.isNotEmpty;
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
    
    _textController.addListener(() {
      ref.read(textFormProvider.notifier).updateText(_textController.text);
    });
    
    _nameController.addListener(() {
      ref.read(textFormProvider.notifier).updateName(_nameController.text);
    });
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
              color: focusNode.hasFocus 
                  ? const Color(0xFFEF4444)
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
                  color: focusNode.hasFocus 
                      ? const Color(0xFFEF4444)
                      : Colors.grey[400],
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
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