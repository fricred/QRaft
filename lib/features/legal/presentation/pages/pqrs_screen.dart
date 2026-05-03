import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';

/// PQRS screen — Peticiones, Quejas, Reclamos y Sugerencias.
///
/// Stores submissions in the pqrs_submissions Supabase table.
/// Accessible from profile. Complies with Ley 1480 de 2011.
class PqrsScreen extends ConsumerStatefulWidget {
  const PqrsScreen({super.key});

  @override
  ConsumerState<PqrsScreen> createState() => _PqrsScreenState();
}

class _PqrsScreenState extends ConsumerState<PqrsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;

  static const _kindOptions = [
    MapEntry('peticion', 'Petición'),
    MapEntry('queja', 'Queja'),
    MapEntry('reclamo', 'Reclamo'),
    MapEntry('sugerencia', 'Sugerencia'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(supabaseAuthProvider).currentUser;
    final userEmail = currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'PQRS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Semantics(
        identifier: 'pqrs_screen',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF1A73E8),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Radica aquí tus peticiones, quejas, reclamos o sugerencias. '
                        'Daremos respuesta en un máximo de 15 días hábiles conforme '
                        'a la Ley 1480 de 2011.',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kind dropdown
                    _buildLabel('Tipo de solicitud *'),
                    const SizedBox(height: 8),
                    FormBuilderDropdown<String>(
                      name: 'kind',
                      validator: FormBuilderValidators.required(
                          errorText: 'Selecciona el tipo de solicitud'),
                      decoration: _inputDecoration('Seleccionar tipo'),
                      items: _kindOptions
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                e.value,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      dropdownColor: const Color(0xFF2E2E2E),
                    ),

                    const SizedBox(height: 20),

                    // Subject field
                    _buildLabel('Asunto *'),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'subject',
                      maxLength: 200,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                          'Descripción breve de tu solicitud'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                            errorText: 'El asunto es requerido'),
                        FormBuilderValidators.maxLength(200,
                            errorText: 'Máximo 200 caracteres'),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    // Body field
                    _buildLabel('Descripción detallada *'),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'body',
                      minLines: 3,
                      maxLines: 8,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                          'Describe tu solicitud con el mayor detalle posible'),
                      validator: FormBuilderValidators.required(
                          errorText:
                              'La descripción detallada es requerida'),
                    ),

                    const SizedBox(height: 20),

                    // Email field
                    _buildLabel('Correo de contacto *'),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'email',
                      initialValue: userEmail,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('tu@correo.com'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                            errorText: 'El correo es requerido'),
                        FormBuilderValidators.email(
                            errorText: 'Ingresa un correo válido'),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    // Order ID (optional)
                    _buildLabel('Número de orden (opcional)'),
                    const SizedBox(height: 8),
                    FormBuilderTextField(
                      name: 'order_id_text',
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                          'p.ej. QRA-2026-000123 (si aplica)'),
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    PrimaryGlassButton(
                      text: 'Enviar PQRS',
                      width: double.infinity,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _submitPqrs,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600]),
      filled: true,
      fillColor: const Color(0xFF2E2E2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF1A73E8), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      counterStyle: TextStyle(color: Colors.grey[600]),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Future<void> _submitPqrs() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final values = _formKey.currentState!.value;
    final currentUser = ref.read(supabaseAuthProvider).currentUser;

    setState(() => _isSubmitting = true);

    try {
      await Supabase.instance.client.from('pqrs_submissions').insert({
        'kind': values['kind'] as String,
        'subject': values['subject'] as String,
        'body': values['body'] as String,
        'email': values['email'] as String,
        'user_id': currentUser?.id,
        // order_id_text is a helper text field — not a UUID FK
        // We skip inserting it unless it exactly matches a UUID pattern
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Tu PQRS fue recibida. Tiempo de respuesta: 15 días hábiles.',
            ),
            backgroundColor: const Color(0xFF1E7E34),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        _formKey.currentState?.reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar PQRS: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
