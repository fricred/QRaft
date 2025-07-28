import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'colombian_tax_form.dart';

class ColombianAddressStep extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const ColombianAddressStep({
    super.key,
    required this.onContinue,
  });

  @override
  ConsumerState<ColombianAddressStep> createState() => _ColombianAddressStepState();
}

class _ColombianAddressStepState extends ConsumerState<ColombianAddressStep> {
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  // Focus nodes for keyboard navigation
  final _addressFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _postalCodeFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

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
      
      _addressController.text = currentState.address;
      _cityController.text = currentState.city;
      _postalCodeController.text = currentState.postalCode;
      _phoneController.text = currentState.phone;
      _emailController.text = currentState.email;
      
      // Defer listener setup to avoid provider modification during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupListeners();
        
        // Auto-focus the first field if it's empty
        if (currentState.address.isEmpty) {
          _addressFocus.requestFocus();
        }
      });
    }
  }

  void _setupListeners() {
    _addressController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updateAddress(_addressController.text);
    });
    
    _cityController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updateCity(_cityController.text);
    });
    
    _postalCodeController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updatePostalCode(_postalCodeController.text);
    });
    
    _phoneController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updatePhone(_phoneController.text);
    });
    
    _emailController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updateEmail(_emailController.text);
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    
    _addressFocus.dispose();
    _cityFocus.dispose();
    _postalCodeFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
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
            'Información de Contacto',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Dirección y datos de contacto',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 100.ms),
          
          const SizedBox(height: 32),
          
          // Address
          _buildTextField(
            controller: _addressController,
            focusNode: _addressFocus,
            label: 'Dirección Completa *',
            hint: 'Calle 123 # 45-67, Barrio Centro',
            errorText: formState.errors['address'],
            maxLines: 2,
            icon: Icons.home_rounded,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _cityFocus.requestFocus(),
          ),
          
          const SizedBox(height: 24),
          
          // Department dropdown
          _buildDropdownField(
            label: 'Departamento *',
            value: formState.department.isEmpty ? null : formState.department,
            items: ColombianTaxFormController.departments.keys.toList(),
            onChanged: (value) {
              ref.read(colombianTaxFormProvider.notifier).updateDepartment(value!);
            },
            errorText: formState.errors['department'],
            hint: 'Selecciona el departamento',
            icon: Icons.map_rounded,
          ),
          
          const SizedBox(height: 24),
          
          // City and postal code
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _cityController,
                  focusNode: _cityFocus,
                  label: 'Ciudad/Municipio *',
                  hint: 'Bogotá',
                  errorText: formState.errors['city'],
                  textCapitalization: TextCapitalization.words,
                  icon: Icons.location_city_rounded,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _postalCodeFocus.requestFocus(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildTextField(
                  controller: _postalCodeController,
                  focusNode: _postalCodeFocus,
                  label: 'Código Postal',
                  hint: '110111',
                  keyboardType: TextInputType.number,
                  icon: Icons.local_post_office_rounded,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _phoneFocus.requestFocus(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Phone
          _buildTextField(
            controller: _phoneController,
            focusNode: _phoneFocus,
            label: 'Teléfono *',
            hint: '+57 300 123 4567',
            errorText: formState.errors['phone'],
            keyboardType: TextInputType.phone,
            icon: Icons.phone_rounded,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _emailFocus.requestFocus(),
          ),
          
          const SizedBox(height: 24),
          
          // Email
          _buildTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            label: 'Correo Electrónico *',
            hint: 'correo@ejemplo.com',
            errorText: formState.errors['email'],
            keyboardType: TextInputType.emailAddress,
            icon: Icons.email_rounded,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              // Try to continue if form is valid
              final controller = ref.read(colombianTaxFormProvider.notifier);
              if (controller.validatePersonalInfo() && controller.validateAddressInfo()) {
                widget.onContinue();
              }
            },
          ),
          
          const SizedBox(height: 32),
          
          // Address validation info
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.green[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Información de Contacto',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Asegúrate de que la información de contacto sea correcta y esté completa.',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12,
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
    int maxLines = 1,
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
            maxLines: maxLines,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
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
                      : focusNode?.hasFocus == true
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