import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'colombian_tax_form.dart';

class ColombianPersonalStep extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const ColombianPersonalStep({
    super.key,
    required this.onContinue,
  });

  @override
  ConsumerState<ColombianPersonalStep> createState() => _ColombianPersonalStepState();
}

class _ColombianPersonalStepState extends ConsumerState<ColombianPersonalStep> {
  final _documentNumberController = TextEditingController();
  final _verificationDigitController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _qrNameController = TextEditingController();
  
  // Focus nodes for keyboard navigation
  final _documentNumberFocus = FocusNode();
  final _verificationDigitFocus = FocusNode();
  final _fullNameFocus = FocusNode();
  final _businessNameFocus = FocusNode();
  final _qrNameFocus = FocusNode();

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_initialized) {
      _initialized = true;
      
      // Initialize controllers with existing state
      final currentState = ref.read(colombianTaxFormProvider);
      
      _documentNumberController.text = currentState.documentNumber;
      _verificationDigitController.text = currentState.verificationDigit;
      _fullNameController.text = currentState.fullName;
      _businessNameController.text = currentState.businessName;
      _qrNameController.text = currentState.qrName;
      
      // Defer listener setup to avoid provider modification during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupListeners();
        
        // Auto-focus the first field if it's empty
        if (currentState.documentNumber.isEmpty) {
          _documentNumberFocus.requestFocus();
        }
      });
    }
  }

  void _setupListeners() {
    _documentNumberController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updateDocumentNumber(_documentNumberController.text);
    });
    
    _verificationDigitController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updateVerificationDigit(_verificationDigitController.text);
    });
    
    _fullNameController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updateFullName(_fullNameController.text);
    });
    
    _businessNameController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updateBusinessName(_businessNameController.text);
    });
    
    _qrNameController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updateQRName(_qrNameController.text);
    });
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    _verificationDigitController.dispose();
    _fullNameController.dispose();
    _businessNameController.dispose();
    _qrNameController.dispose();
    
    _documentNumberFocus.dispose();
    _verificationDigitFocus.dispose();
    _fullNameFocus.dispose();
    _businessNameFocus.dispose();
    _qrNameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(colombianTaxFormProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24, 
        24, 
        24, 
        24 + MediaQuery.of(context).viewInsets.bottom
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Personal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Datos personales básicos',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 100.ms),
          
          const SizedBox(height: 32),
          
          // Document type dropdown
          _buildDropdownField(
            label: 'Tipo de Documento *',
            value: formState.documentType,
            items: ColombianTaxFormController.documentTypes,
            onChanged: (value) {
              ref.read(colombianTaxFormProvider.notifier).updateDocumentType(value!);
            },
            hint: 'Selecciona el tipo de documento',
            icon: Icons.badge_rounded,
          ),
          
          const SizedBox(height: 24),
          
          // Document number
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  controller: _documentNumberController,
                  focusNode: _documentNumberFocus,
                  label: 'Número de Documento *',
                  hint: formState.documentType == 'CC' ? '12345678' : '900123456',
                  errorText: formState.errors['documentNumber'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  icon: Icons.numbers_rounded,
                  textInputAction: formState.documentType == 'NIT' 
                      ? TextInputAction.next 
                      : TextInputAction.next,
                  onSubmitted: (_) {
                    if (formState.documentType == 'NIT') {
                      _verificationDigitFocus.requestFocus();
                    } else {
                      _fullNameFocus.requestFocus();
                    }
                  },
                ),
              ),
              if (formState.documentType == 'NIT') ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    controller: _verificationDigitController,
                    focusNode: _verificationDigitFocus,
                    label: 'DV *',
                    hint: '1',
                    errorText: formState.errors['verificationDigit'],
                    maxLength: 1,
                    textCapitalization: TextCapitalization.characters,
                    icon: Icons.verified_rounded,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _fullNameFocus.requestFocus(),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Full name
          _buildTextField(
            controller: _fullNameController,
            focusNode: _fullNameFocus,
            label: 'Nombre Completo *',
            hint: 'Juan Pérez García',
            errorText: formState.errors['fullName'],
            textCapitalization: TextCapitalization.words,
            icon: Icons.person_rounded,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _businessNameFocus.requestFocus(),
          ),
          
          const SizedBox(height: 24),
          
          // Business name (optional)
          _buildTextField(
            controller: _businessNameController,
            focusNode: _businessNameFocus,
            label: 'Razón Social (Opcional)',
            hint: 'Empresa ABC S.A.S.',
            textCapitalization: TextCapitalization.words,
            icon: Icons.business_rounded,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _qrNameFocus.requestFocus(),
          ),
          
          const SizedBox(height: 24),
          
          // QR Name
          _buildTextField(
            controller: _qrNameController,
            focusNode: _qrNameFocus,
            label: 'Nombre del QR *',
            hint: 'Mi Info Fiscal',
            errorText: formState.errors['qrName'],
            textCapitalization: TextCapitalization.words,
            icon: Icons.qr_code_rounded,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              // Try to continue if form is valid
              final controller = ref.read(colombianTaxFormProvider.notifier);
              if (controller.validatePersonalInfo()) {
                widget.onContinue();
              }
            },
          ),
          
          const SizedBox(height: 32),
          
          // Required fields info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blue[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Los campos marcados con * son obligatorios',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int? maxLength,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
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
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            maxLength: maxLength,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(
                icon,
                color: errorText != null
                    ? const Color(0xFFEF4444)
                    : focusNode?.hasFocus == true
                        ? const Color(0xFF1A73E8)
                        : Colors.grey[400],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
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
      ],
    ).animate()
      .fadeIn(duration: 600.ms, delay: 300.ms)
      .slideY(begin: 0.3, duration: 600.ms, delay: 300.ms);
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    String? errorText,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
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
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  icon,
                  color: errorText != null
                      ? const Color(0xFFEF4444)
                      : Colors.grey[400],
                ),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    hint: Text(
                      hint ?? 'Seleccionar...',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    dropdownColor: const Color(0xFF2E2E2E),
                    style: const TextStyle(color: Colors.white),
                    onChanged: onChanged,
                    items: items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
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
      ],
    ).animate()
      .fadeIn(duration: 600.ms, delay: 200.ms)
      .slideY(begin: 0.3, duration: 600.ms, delay: 200.ms);
  }
}