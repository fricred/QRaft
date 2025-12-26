import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable form field widget for profile editing
/// Supports text, phone, URL, and multiline input types
class ProfileFormField extends StatefulWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final bool isRequired;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final bool showCharacterCount;

  const ProfileFormField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.isRequired = false,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.hintText,
    this.showCharacterCount = false,
  });

  @override
  State<ProfileFormField> createState() => _ProfileFormFieldState();
}

class _ProfileFormFieldState extends State<ProfileFormField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    // Validate on blur
    if (!_focusNode.hasFocus && widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
    }
  }

  void _validate() {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null;
    final borderColor = hasError
        ? Colors.red
        : _isFocused
            ? const Color(0xFF00FF88)
            : const Color(0xFF2E2E2E);
    final iconColor = hasError
        ? Colors.red
        : _isFocused
            ? const Color(0xFF00FF88)
            : Colors.grey[500];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: const Color(0xFF00FF88),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Input field
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _isFocused || hasError ? 2 : 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  widget.icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              hintText: widget.hintText ?? widget.label,
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: widget.maxLines > 1 ? 16 : 14,
              ),
              counterText: '', // Hide default counter
            ),
            onChanged: (value) {
              widget.onChanged?.call(value);
              // Clear error when user starts typing
              if (_errorText != null) {
                _validate();
              }
            },
          ),
        ),

        // Error text and character count
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
          child: Row(
            children: [
              // Error text
              if (hasError)
                Expanded(
                  child: Text(
                    _errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                const Spacer(),

              // Character count
              if (widget.showCharacterCount && widget.maxLength != null)
                Text(
                  '${widget.controller.text.length}/${widget.maxLength}',
                  style: TextStyle(
                    color: widget.controller.text.length > (widget.maxLength! * 0.9)
                        ? Colors.orange
                        : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Validators for profile fields
class ProfileValidators {
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required';
    }
    if (value.trim().length < 2) {
      return 'Display name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Display name must be less than 50 characters';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    // Basic phone validation - allows +, digits, spaces, dashes, parentheses
    final phoneRegex = RegExp(r'^[\+]?[(]?[0-9]{1,4}[)]?[-\s\./0-9]*$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    // Basic URL validation
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  static String? bio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.length > 500) {
      return 'Bio must be less than 500 characters';
    }
    return null;
  }

  static String? maxLength(String? value, int max) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (value.length > max) {
      return 'Must be less than $max characters';
    }
    return null;
  }
}
