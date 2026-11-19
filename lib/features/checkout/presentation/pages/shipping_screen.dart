import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../domain/entities/shipping_address.dart';
import '../providers/checkout_providers.dart';
import 'wompi_webview_screen.dart';

/// Shipping address form that drives the checkout flow.
///
/// Loads the DANE departamento/municipio dataset from
/// `assets/data/colombia_dane.json` and populates two cascading dropdowns.
/// On form submission it invokes [createOrderProvider] which calls the
/// create-payment-intent Edge Function.  On success it pushes
/// [WompiWebViewScreen] with the returned [CheckoutSession].
class ShippingScreen extends ConsumerStatefulWidget {
  const ShippingScreen({super.key});

  @override
  ConsumerState<ShippingScreen> createState() => _ShippingScreenState();
}

class _ShippingScreenState extends ConsumerState<ShippingScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  List<Map<String, dynamic>> _departments = [];
  List<String> _cities = [];
  String? _selectedDepartment;
  bool _loadingDane = true;
  bool _submitting = false;

  static const _inputDecoration = InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF2E2E2E),
    labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
    hintStyle: TextStyle(color: Color(0xFF6B7280)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF4B5563)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF00FF88), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFEF4444)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  void initState() {
    super.initState();
    _loadDane();
  }

  Future<void> _loadDane() async {
    try {
      final raw = await rootBundle.loadString('assets/data/colombia_dane.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final departments = (data['departments'] as List)
          .cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _departments = departments;
          _loadingDane = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingDane = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos de Colombia: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _onDepartmentChanged(String? value) {
    if (value == null) return;
    final dept = _departments.firstWhere(
      (d) => d['name'] == value,
      orElse: () => <String, dynamic>{},
    );
    final cities = dept.isEmpty
        ? <String>[]
        : (dept['cities'] as List).cast<String>();

    setState(() {
      _selectedDepartment = value;
      _cities = cities;
    });

    // Reset city when department changes
    _formKey.currentState?.fields['city']?.didChange(null);
  }

  Future<void> _onConfirm() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final values = _formKey.currentState!.value;
    final address = ShippingAddress(
      recipientName: (values['recipientName'] as String).trim(),
      phone: (values['phone'] as String).trim(),
      department: values['department'] as String,
      city: values['city'] as String,
      address: (values['address'] as String).trim(),
      notes: (values['notes'] as String?)?.trim(),
    );

    setState(() => _submitting = true);

    try {
      final session = await ref.read(createOrderProvider(address).future);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WompiWebViewScreen(session: session),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al crear el pedido. Intenta de nuevo.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: _inputDecoration,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text(
            'Datos de envío',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _loadingDane
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00FF88),
                ),
              )
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return FormBuilder(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Destinatario'),
          const SizedBox(height: 12),

          // ---- Recipient name ----
          Semantics(
            identifier: 'shipping_recipient_name_field',
            child: FormBuilderTextField(
              name: 'recipientName',
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                hintText: 'Ej. María García López',
              ),
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                    errorText: 'Nombre requerido'),
                FormBuilderValidators.minLength(2,
                    errorText: 'Mínimo 2 caracteres'),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Phone ----
          Semantics(
            identifier: 'shipping_phone_field',
            child: FormBuilderTextField(
              name: 'phone',
              initialValue: '+57',
              decoration: const InputDecoration(
                labelText: 'Teléfono *',
                hintText: '+573001234567',
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                    errorText: 'Teléfono requerido'),
                FormBuilderValidators.match(
                  // Colombian mobile (+57)3XXXXXXXXX or local 3XXXXXXXXX
                  RegExp(r'^(\+57)?[3][0-9]{9}$'),
                  errorText:
                      'Ingresa un número colombiano válido, Ej: +573001234567',
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Dirección de entrega'),
          const SizedBox(height: 12),

          // ---- Department ----
          Semantics(
            identifier: 'shipping_department_dropdown',
            child: FormBuilderDropdown<String>(
              name: 'department',
              decoration: const InputDecoration(
                labelText: 'Departamento *',
              ),
              dropdownColor: const Color(0xFF2E2E2E),
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white70,
              items: _departments
                  .map((d) => DropdownMenuItem<String>(
                        value: d['name'] as String,
                        child: Text(
                          d['name'] as String,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ))
                  .toList(),
              onChanged: _onDepartmentChanged,
              validator: FormBuilderValidators.required(
                  errorText: 'Selecciona un departamento'),
            ),
          ),
          const SizedBox(height: 16),

          // ---- City ----
          Semantics(
            identifier: 'shipping_city_dropdown',
            child: FormBuilderDropdown<String>(
              name: 'city',
              enabled: _selectedDepartment != null,
              decoration: InputDecoration(
                labelText: 'Ciudad / Municipio *',
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF3A3A3A)),
                ),
              ),
              dropdownColor: const Color(0xFF2E2E2E),
              style: TextStyle(
                color: _selectedDepartment != null
                    ? Colors.white
                    : Colors.white38,
              ),
              iconEnabledColor: Colors.white70,
              iconDisabledColor: Colors.white24,
              items: _cities
                  .map((c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(
                          c,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ))
                  .toList(),
              validator: FormBuilderValidators.required(
                  errorText: 'Selecciona una ciudad'),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Street address ----
          Semantics(
            identifier: 'shipping_address_field',
            child: FormBuilderTextField(
              name: 'address',
              decoration: const InputDecoration(
                labelText: 'Dirección *',
                hintText: 'Calle 123 #45-67 Apto 8',
              ),
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.sentences,
              validator: FormBuilderValidators.required(
                  errorText: 'Dirección requerida'),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Notes (optional) ----
          FormBuilderTextField(
            name: 'notes',
            decoration: const InputDecoration(
              labelText: 'Indicaciones adicionales (opcional)',
              hintText: 'Apartamento, piso, indicaciones al portero...',
            ),
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          // ---- Confirm button ----
          Semantics(
            identifier: 'shipping_confirm_button',
            child: PrimaryGlassButton(
              text: 'Confirmar envío',
              width: double.infinity,
              isLoading: _submitting,
              onPressed: _submitting ? null : _onConfirm,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF00FF88),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
    );
  }
}
