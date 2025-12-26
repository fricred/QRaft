import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/qr_data_models.dart';

final colombianTaxFormProvider = StateNotifierProvider<ColombianTaxFormController, ColombianTaxFormState>((ref) {
  return ColombianTaxFormController();
});

class ColombianTaxFormState {
  final String documentType;
  final String documentNumber;
  final String verificationDigit;
  final String fullName;
  final String businessName;
  final String address;
  final String city;
  final String cityCode;
  final String department;
  final String departmentCode;
  final String postalCode;
  final String phone;
  final String email;
  final String taxRegime;
  final List<String> taxResponsibilities;
  final String economicActivity;
  final String qrName;
  final bool isValid;
  final bool isPersonalInfoValid;
  final bool isAddressInfoValid;
  final Map<String, String?> errors;

  const ColombianTaxFormState({
    this.documentType = 'CC',
    this.documentNumber = '',
    this.verificationDigit = '',
    this.fullName = '',
    this.businessName = '',
    this.address = '',
    this.city = '',
    this.cityCode = '',
    this.department = '',
    this.departmentCode = '',
    this.postalCode = '',
    this.phone = '',
    this.email = '',
    this.taxRegime = 'Común',
    this.taxResponsibilities = const [],
    this.economicActivity = '',
    this.qrName = '',
    this.isValid = false,
    this.isPersonalInfoValid = false,
    this.isAddressInfoValid = false,
    this.errors = const {},
  });

  ColombianTaxFormState copyWith({
    String? documentType,
    String? documentNumber,
    String? verificationDigit,
    String? fullName,
    String? businessName,
    String? address,
    String? city,
    String? cityCode,
    String? department,
    String? departmentCode,
    String? postalCode,
    String? phone,
    String? email,
    String? taxRegime,
    List<String>? taxResponsibilities,
    String? economicActivity,
    String? qrName,
    bool? isValid,
    bool? isPersonalInfoValid,
    bool? isAddressInfoValid,
    Map<String, String?>? errors,
  }) {
    return ColombianTaxFormState(
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      verificationDigit: verificationDigit ?? this.verificationDigit,
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      city: city ?? this.city,
      cityCode: cityCode ?? this.cityCode,
      department: department ?? this.department,
      departmentCode: departmentCode ?? this.departmentCode,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      taxRegime: taxRegime ?? this.taxRegime,
      taxResponsibilities: taxResponsibilities ?? this.taxResponsibilities,
      economicActivity: economicActivity ?? this.economicActivity,
      qrName: qrName ?? this.qrName,
      isValid: isValid ?? this.isValid,
      isPersonalInfoValid: isPersonalInfoValid ?? this.isPersonalInfoValid,
      isAddressInfoValid: isAddressInfoValid ?? this.isAddressInfoValid,
      errors: errors ?? this.errors,
    );
  }

  ColombianTaxInfoData get taxData {
    return ColombianTaxInfoData(
      documentType: documentType,
      documentNumber: documentNumber,
      fullName: fullName,
      businessName: businessName,
      address: address,
      city: city,
      cityCode: cityCode,
      department: department,
      departmentCode: departmentCode,
      postalCode: postalCode,
      phone: phone,
      email: email,
      taxRegime: taxRegime,
      taxResponsibilities: taxResponsibilities,
      economicActivity: economicActivity,
      verificationDigit: verificationDigit,
    );
  }
}

class ColombianTaxFormController extends StateNotifier<ColombianTaxFormState> {
  ColombianTaxFormController() : super(const ColombianTaxFormState());

  // Document type options for Colombia
  static const documentTypes = [
    'CC',   // Cédula de Ciudadanía
    'NIT',  // Número de Identificación Tributaria
    'TI',   // Tarjeta de Identidad
    'CE',   // Cédula de Extranjería
    'PP',   // Pasaporte
    'RC',   // Registro Civil
  ];

  // Tax regimes in Colombia
  static const taxRegimes = [
    'Común',
    'Simplificado',
    'Gran Contribuyente',
    'Autoretenedor',
    'Régimen Simple de Tributación',
  ];

  // Common tax responsibilities
  static const commonTaxResponsibilities = [
    'IVA',
    'Retención en la fuente',
    'Impuesto sobre las ventas - IVA',
    'Agente retenedor de IVA',
    'Gravamen a los movimientos financieros',
    'Impuesto nacional al consumo',
    'Retención de impuesto sobre las ventas',
    'CREE',
    'Impuesto de industria y comercio',
  ];

  // Colombian departments with codes
  static const departments = {
    'Amazonas': '91',
    'Antioquia': '05',
    'Arauca': '81',
    'Atlántico': '08',
    'Bolívar': '13',
    'Boyacá': '15',
    'Caldas': '17',
    'Caquetá': '18',
    'Casanare': '85',
    'Cauca': '19',
    'Cesar': '20',
    'Chocó': '27',
    'Córdoba': '23',
    'Cundinamarca': '25',
    'Guainía': '94',
    'Guaviare': '95',
    'Huila': '41',
    'La Guajira': '44',
    'Magdalena': '47',
    'Meta': '50',
    'Nariño': '52',
    'Norte de Santander': '54',
    'Putumayo': '86',
    'Quindío': '63',
    'Risaralda': '66',
    'San Andrés y Providencia': '88',
    'Santander': '68',
    'Sucre': '70',
    'Tolima': '73',
    'Valle del Cauca': '76',
    'Vaupés': '97',
    'Vichada': '99',
    'Bogotá D.C.': '11',
  };

  void updateDocumentType(String type) {
    final newErrors = Map<String, String?>.from(state.errors);
    newErrors.remove('documentType');
    
    state = state.copyWith(
      documentType: type,
      errors: newErrors,
    );
    
    _updateValidationState();
  }

  void updateDocumentNumber(String number) {
    final newErrors = Map<String, String?>.from(state.errors);
    final error = _validateDocumentNumber(number);
    if (error != null) {
      newErrors['documentNumber'] = error;
    } else {
      newErrors.remove('documentNumber');
    }
    
    // Calculate validation with new values
    final tempState = state.copyWith(
      documentNumber: number,
      errors: newErrors,
    );
    
    final personalValid = _validatePersonalInfoForState(tempState);
    final addressValid = _validateAddressInfoForState(tempState);
    
    state = state.copyWith(
      documentNumber: number,
      errors: newErrors,
      isPersonalInfoValid: personalValid,
      isAddressInfoValid: addressValid,
      isValid: personalValid && addressValid,
    );
  }

  void updateVerificationDigit(String digit) {
    final newErrors = Map<String, String?>.from(state.errors);
    final error = _validateVerificationDigit(digit);
    if (error != null) {
      newErrors['verificationDigit'] = error;
    } else {
      newErrors.remove('verificationDigit');
    }
    
    // Calculate validation with new values
    final tempState = state.copyWith(
      verificationDigit: digit,
      errors: newErrors,
    );
    
    final personalValid = _validatePersonalInfoForState(tempState);
    final addressValid = _validateAddressInfoForState(tempState);
    
    state = state.copyWith(
      verificationDigit: digit,
      errors: newErrors,
      isPersonalInfoValid: personalValid,
      isAddressInfoValid: addressValid,
      isValid: personalValid && addressValid,
    );
  }

  void updateFullName(String name) {
    final newErrors = Map<String, String?>.from(state.errors);
    final error = _validateName(name);
    if (error != null) {
      newErrors['fullName'] = error;
    } else {
      newErrors.remove('fullName');
    }
    
    // Calculate validation with new values
    final tempState = state.copyWith(
      fullName: name,
      errors: newErrors,
    );
    
    final personalValid = _validatePersonalInfoForState(tempState);
    final addressValid = _validateAddressInfoForState(tempState);
    
    state = state.copyWith(
      fullName: name,
      errors: newErrors,
      isPersonalInfoValid: personalValid,
      isAddressInfoValid: addressValid,
      isValid: personalValid && addressValid,
    );
  }

  void updateBusinessName(String name) {
    state = state.copyWith(
      businessName: name,
      isValid: _validateForm(),
    );
  }

  void updateAddress(String address) {
    final newErrors = Map<String, String?>.from(state.errors);
    final error = _validateAddress(address);
    if (error != null) {
      newErrors['address'] = error;
    } else {
      newErrors.remove('address');
    }
    
    // Calculate validation with new values
    final tempState = state.copyWith(
      address: address,
      errors: newErrors,
    );
    
    final personalValid = _validatePersonalInfoForState(tempState);
    final addressValid = _validateAddressInfoForState(tempState);
    
    state = state.copyWith(
      address: address,
      errors: newErrors,
      isPersonalInfoValid: personalValid,
      isAddressInfoValid: addressValid,
      isValid: personalValid && addressValid,
    );
  }

  void updateCity(String city) {
    final newErrors = Map<String, String?>.from(state.errors);
    final error = _validateCity(city);
    if (error != null) {
      newErrors['city'] = error;
    } else {
      newErrors.remove('city');
    }
    
    // Calculate validation with new values
    final tempState = state.copyWith(
      city: city,
      errors: newErrors,
    );
    
    final personalValid = _validatePersonalInfoForState(tempState);
    final addressValid = _validateAddressInfoForState(tempState);
    
    state = state.copyWith(
      city: city,
      errors: newErrors,
      isPersonalInfoValid: personalValid,
      isAddressInfoValid: addressValid,
      isValid: personalValid && addressValid,
    );
  }

  void updateDepartment(String department) {
    final newErrors = Map<String, String?>.from(state.errors);
    final error = _validateDepartment(department);
    if (error != null) {
      newErrors['department'] = error;
    } else {
      newErrors.remove('department');
    }
    
    // Auto-fill department code
    final departmentCode = departments[department] ?? '';
    
    // Calculate validation with new values
    final tempState = state.copyWith(
      department: department,
      departmentCode: departmentCode,
      errors: newErrors,
    );
    
    final personalValid = _validatePersonalInfoForState(tempState);
    final addressValid = _validateAddressInfoForState(tempState);
    
    state = state.copyWith(
      department: department,
      departmentCode: departmentCode,
      errors: newErrors,
      isPersonalInfoValid: personalValid,
      isAddressInfoValid: addressValid,
      isValid: personalValid && addressValid,
    );
  }

  void updatePhone(String phone) {
    final newErrors = Map<String, String?>.from(state.errors);
    final error = _validatePhone(phone);
    if (error != null) {
      newErrors['phone'] = error;
    } else {
      newErrors.remove('phone');
    }
    
    // Calculate validation with new values
    final tempState = state.copyWith(
      phone: phone,
      errors: newErrors,
    );
    
    final personalValid = _validatePersonalInfoForState(tempState);
    final addressValid = _validateAddressInfoForState(tempState);
    
    state = state.copyWith(
      phone: phone,
      errors: newErrors,
      isPersonalInfoValid: personalValid,
      isAddressInfoValid: addressValid,
      isValid: personalValid && addressValid,
    );
  }

  void updateEmail(String email) {
    final newErrors = Map<String, String?>.from(state.errors);
    final error = _validateEmail(email);
    if (error != null) {
      newErrors['email'] = error;
    } else {
      newErrors.remove('email');
    }
    
    // Calculate validation with new values
    final tempState = state.copyWith(
      email: email,
      errors: newErrors,
    );
    
    final personalValid = _validatePersonalInfoForState(tempState);
    final addressValid = _validateAddressInfoForState(tempState);
    
    state = state.copyWith(
      email: email,
      errors: newErrors,
      isPersonalInfoValid: personalValid,
      isAddressInfoValid: addressValid,
      isValid: personalValid && addressValid,
    );
  }

  void updateQRName(String name) {
    final newErrors = Map<String, String?>.from(state.errors);
    final error = _validateQRName(name);
    if (error != null) {
      newErrors['qrName'] = error;
    } else {
      newErrors.remove('qrName');
    }
    
    // Calculate validation with new values
    final tempState = state.copyWith(
      qrName: name,
      errors: newErrors,
    );
    
    final personalValid = _validatePersonalInfoForState(tempState);
    final addressValid = _validateAddressInfoForState(tempState);
    
    state = state.copyWith(
      qrName: name,
      errors: newErrors,
      isPersonalInfoValid: personalValid,
      isAddressInfoValid: addressValid,
      isValid: personalValid && addressValid,
    );
  }

  void updateTaxRegime(String regime) {
    state = state.copyWith(
      taxRegime: regime,
      isValid: _validateForm(),
    );
  }

  void updateEconomicActivity(String activity) {
    state = state.copyWith(
      economicActivity: activity,
      isValid: _validateForm(),
    );
  }

  void updatePostalCode(String code) {
    state = state.copyWith(
      postalCode: code,
      isValid: _validateForm(),
    );
  }

  void toggleTaxResponsibility(String responsibility) {
    final current = List<String>.from(state.taxResponsibilities);
    if (current.contains(responsibility)) {
      current.remove(responsibility);
    } else {
      current.add(responsibility);
    }
    
    state = state.copyWith(
      taxResponsibilities: current,
      isValid: _validateForm(),
    );
  }

  // Validation methods
  String? _validateDocumentNumber(String number) {
    if (number.isEmpty) return 'Número de documento requerido';
    
    if (state.documentType == 'CC') {
      if (number.length < 7 || number.length > 10) {
        return 'CC debe tener entre 7 y 10 dígitos';
      }
    } else if (state.documentType == 'NIT') {
      if (number.length < 9 || number.length > 10) {
        return 'NIT debe tener entre 9 y 10 dígitos';
      }
    }
    
    // ignore: deprecated_member_use
    if (!RegExp(r'^\d+$').hasMatch(number)) {
      return 'Solo se permiten números';
    }
    
    return null;
  }

  String? _validateVerificationDigit(String digit) {
    if (state.documentType == 'NIT' && digit.isEmpty) {
      return 'Dígito de verificación requerido para NIT';
    }
    
    // ignore: deprecated_member_use
    if (digit.isNotEmpty && !RegExp(r'^[0-9K]$').hasMatch(digit)) {
      return 'Debe ser un dígito (0-9) o K';
    }
    
    return null;
  }

  String? _validateName(String name) {
    if (name.isEmpty) return 'Nombre completo requerido';
    if (name.length < 3) return 'Nombre muy corto';
    if (name.length > 100) return 'Nombre muy largo';
    return null;
  }

  String? _validateAddress(String address) {
    if (address.isEmpty) return 'Dirección requerida';
    if (address.length < 10) return 'Dirección muy corta';
    if (address.length > 200) return 'Dirección muy larga';
    return null;
  }

  String? _validateCity(String city) {
    if (city.isEmpty) return 'Ciudad requerida';
    if (city.length < 3) return 'Ciudad muy corta';
    if (city.length > 50) return 'Ciudad muy larga';
    return null;
  }

  String? _validateDepartment(String department) {
    if (department.isEmpty) return 'Departamento requerido';
    if (!departments.containsKey(department)) {
      return 'Departamento no válido';
    }
    return null;
  }

  String? _validatePhone(String phone) {
    if (phone.isEmpty) return 'Teléfono requerido';
    // ignore: deprecated_member_use
    if (!RegExp(r'^\+?[0-9\s\-\(\)]{7,15}$').hasMatch(phone)) {
      return 'Formato de teléfono inválido';
    }
    return null;
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Email requerido';
    // ignore: deprecated_member_use
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      return 'Email inválido';
    }
    return null;
  }

  String? _validateQRName(String name) {
    if (name.isEmpty) return 'Nombre del QR requerido';
    if (name.length < 3) return 'Nombre muy corto';
    if (name.length > 50) return 'Nombre muy largo';
    return null;
  }

  bool _validateForm() {
    return validatePersonalInfo() && validateAddressInfo();
  }
  
  // Helper method to update validation state
  void _updateValidationState() {
    final personalValid = validatePersonalInfo();
    final addressValid = validateAddressInfo();
    
    state = state.copyWith(
      isPersonalInfoValid: personalValid,
      isAddressInfoValid: addressValid,
      isValid: personalValid && addressValid,
    );
  }
  
  // Validate only personal information step
  bool validatePersonalInfo() {
    return _validatePersonalInfoForState(state);
  }
  
  // Validate only address information step
  bool validateAddressInfo() {
    return _validateAddressInfoForState(state);
  }
  
  // Helper methods for validation with specific state
  bool _validatePersonalInfoForState(ColombianTaxFormState checkState) {
    return checkState.documentNumber.isNotEmpty &&
           _validateDocumentNumber(checkState.documentNumber) == null &&
           checkState.fullName.isNotEmpty &&
           _validateName(checkState.fullName) == null &&
           checkState.qrName.isNotEmpty &&
           _validateQRName(checkState.qrName) == null &&
           (checkState.documentType != 'NIT' || 
            (checkState.verificationDigit.isNotEmpty && _validateVerificationDigit(checkState.verificationDigit) == null));
  }
  
  bool _validateAddressInfoForState(ColombianTaxFormState checkState) {
    return checkState.address.isNotEmpty &&
           _validateAddress(checkState.address) == null &&
           checkState.city.isNotEmpty &&
           _validateCity(checkState.city) == null &&
           checkState.department.isNotEmpty &&
           _validateDepartment(checkState.department) == null &&
           checkState.phone.isNotEmpty &&
           _validatePhone(checkState.phone) == null &&
           checkState.email.isNotEmpty &&
           _validateEmail(checkState.email) == null;
  }

  void reset() {
    state = const ColombianTaxFormState();
  }
}

class ColombianTaxForm extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const ColombianTaxForm({
    super.key,
    required this.onContinue,
  });

  @override
  ConsumerState<ColombianTaxForm> createState() => _ColombianTaxFormState();
}

class _ColombianTaxFormState extends ConsumerState<ColombianTaxForm> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _scrollController = ScrollController();

  // Text controllers for each field
  final _documentNumberController = TextEditingController();
  final _verificationDigitController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _economicActivityController = TextEditingController();
  final _qrNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = ref.read(colombianTaxFormProvider);
      
      _documentNumberController.text = currentState.documentNumber;
      _verificationDigitController.text = currentState.verificationDigit;
      _fullNameController.text = currentState.fullName;
      _businessNameController.text = currentState.businessName;
      _addressController.text = currentState.address;
      _cityController.text = currentState.city;
      _postalCodeController.text = currentState.postalCode;
      _phoneController.text = currentState.phone;
      _emailController.text = currentState.email;
      _economicActivityController.text = currentState.economicActivity;
      _qrNameController.text = currentState.qrName;
      
      // Trigger validation if we have existing values
      if (currentState.documentNumber.isNotEmpty) {
        _setupListeners();
      }
    });
    
    _setupListeners();
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
    
    _economicActivityController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updateEconomicActivity(_economicActivityController.text);
    });
    
    _qrNameController.addListener(() {
      ref.read(colombianTaxFormProvider.notifier).updateQRName(_qrNameController.text);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _documentNumberController.dispose();
    _verificationDigitController.dispose();
    _fullNameController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _economicActivityController.dispose();
    _qrNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(colombianTaxFormProvider);

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Padding(
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
              'Información Fiscal Colombia',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ).animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: -0.3, duration: 600.ms),
            
            const SizedBox(height: 8),
            
            Text(
              'Información para facturación electrónica',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ).animate()
              .fadeIn(duration: 600.ms, delay: 100.ms),
            
            const SizedBox(height: 32),
            
            // Multi-page form
            SizedBox(
              height: 600, // Fixed height for the form
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildPersonalInfoPage(formState),
                  _buildAddressPage(formState),
                  _buildTaxInfoPage(formState),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF1A73E8) : Colors.grey[600],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 24),
            
            // Navigation buttons
            Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Anterior'),
                    ),
                  ),
                
                if (_currentPage > 0) const SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentPage < 2 
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : formState.isValid 
                            ? widget.onContinue 
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentPage < 2 ? 'Siguiente' : 'Continuar',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoPage(ColombianTaxFormState formState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información Personal'),
          
          const SizedBox(height: 16),
          
          // Document type dropdown
          _buildDropdownField(
            label: 'Tipo de Documento',
            value: formState.documentType,
            items: ColombianTaxFormController.documentTypes,
            onChanged: (value) {
              ref.read(colombianTaxFormProvider.notifier).updateDocumentType(value!);
            },
            hint: 'Selecciona el tipo de documento',
          ),
          
          const SizedBox(height: 16),
          
          // Document number
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  controller: _documentNumberController,
                  label: 'Número de Documento',
                  hint: formState.documentType == 'CC' ? '12345678' : '900123456',
                  errorText: formState.errors['documentNumber'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              if (formState.documentType == 'NIT') ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    controller: _verificationDigitController,
                    label: 'DV',
                    hint: '1',
                    errorText: formState.errors['verificationDigit'],
                    maxLength: 1,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Full name
          _buildTextField(
            controller: _fullNameController,
            label: 'Nombre Completo',
            hint: 'Juan Pérez García',
            errorText: formState.errors['fullName'],
            textCapitalization: TextCapitalization.words,
          ),
          
          const SizedBox(height: 16),
          
          // Business name (optional)
          _buildTextField(
            controller: _businessNameController,
            label: 'Razón Social (Opcional)',
            hint: 'Empresa ABC S.A.S.',
            textCapitalization: TextCapitalization.words,
          ),
          
          const SizedBox(height: 16),
          
          // QR Name
          _buildTextField(
            controller: _qrNameController,
            label: 'Nombre del QR',
            hint: 'Mi Info Fiscal',
            errorText: formState.errors['qrName'],
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPage(ColombianTaxFormState formState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información de Domicilio'),
          
          const SizedBox(height: 16),
          
          // Address
          _buildTextField(
            controller: _addressController,
            label: 'Dirección Completa',
            hint: 'Calle 123 # 45-67, Barrio Centro',
            errorText: formState.errors['address'],
            maxLines: 2,
          ),
          
          const SizedBox(height: 16),
          
          // Department dropdown
          _buildDropdownField(
            label: 'Departamento',
            value: formState.department.isEmpty ? null : formState.department,
            items: ColombianTaxFormController.departments.keys.toList(),
            onChanged: (value) {
              ref.read(colombianTaxFormProvider.notifier).updateDepartment(value!);
            },
            errorText: formState.errors['department'],
            hint: 'Selecciona el departamento',
          ),
          
          const SizedBox(height: 16),
          
          // City and postal code
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _cityController,
                  label: 'Ciudad/Municipio',
                  hint: 'Bogotá',
                  errorText: formState.errors['city'],
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildTextField(
                  controller: _postalCodeController,
                  label: 'Código Postal',
                  hint: '110111',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Phone
          _buildTextField(
            controller: _phoneController,
            label: 'Teléfono',
            hint: '+57 300 123 4567',
            errorText: formState.errors['phone'],
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: 16),
          
          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Correo Electrónico',
            hint: 'correo@ejemplo.com',
            errorText: formState.errors['email'],
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildTaxInfoPage(ColombianTaxFormState formState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información Tributaria'),
          
          const SizedBox(height: 16),
          
          // Tax regime
          _buildDropdownField(
            label: 'Régimen Tributario',
            value: formState.taxRegime,
            items: ColombianTaxFormController.taxRegimes,
            onChanged: (value) {
              ref.read(colombianTaxFormProvider.notifier).updateTaxRegime(value!);
            },
            hint: 'Selecciona el régimen',
          ),
          
          const SizedBox(height: 16),
          
          // Economic activity
          _buildTextField(
            controller: _economicActivityController,
            label: 'Actividad Económica (Opcional)',
            hint: 'Código CIIU principal',
            maxLines: 2,
          ),
          
          const SizedBox(height: 16),
          
          // Tax responsibilities
          _buildSectionTitle('Responsabilidades Fiscales'),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ColombianTaxFormController.commonTaxResponsibilities.map((responsibility) {
              final isSelected = formState.taxResponsibilities.contains(responsibility);
              return FilterChip(
                label: Text(
                  responsibility,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[300],
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(colombianTaxFormProvider.notifier).toggleTaxResponsibility(responsibility);
                },
                backgroundColor: const Color(0xFF2E2E2E),
                selectedColor: const Color(0xFF1A73E8),
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[600]!,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int? maxLength,
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
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            maxLength: maxLength,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '', // Hide character counter
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
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }
}