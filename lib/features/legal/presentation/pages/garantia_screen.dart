import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';

/// Garantía 3-month claim screen.
///
/// Covers the warranty claim flow for manufacturing defects per
/// Ley 1480 de 2011 Art. 7-11. This is SEPARATE from the retracto path.
/// Accessible from the profile legal section.
class GarantiaScreen extends ConsumerStatefulWidget {
  const GarantiaScreen({super.key});

  @override
  ConsumerState<GarantiaScreen> createState() => _GarantiaScreenState();
}

class _GarantiaScreenState extends ConsumerState<GarantiaScreen> {
  final _orderIdController = TextEditingController();
  final _defectController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _orderIdController.dispose();
    _defectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Garantía 3 meses',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Semantics(
        identifier: 'garantia_screen',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Información de garantía ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF88)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.verified_outlined,
                            color: Color(0xFF00FF88),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Información de garantía',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Todos los productos QRaft tienen garantía de 3 meses contra '
                      'defectos de fabricación y problemas de escaneabilidad. '
                      'Esta garantía aplica desde la fecha de entrega.\n\n'
                      'Esta garantía NO cubre:\n'
                      '• Daño por uso inadecuado o accidentes\n'
                      '• Pérdida del objeto\n'
                      '• Desgaste normal por uso\n\n'
                      'Para ejercer la garantía, tu pedido debe estar en estado '
                      '"Entregado" y la reclamación debe hacerse dentro de los '
                      '90 días desde la entrega.\n\n'
                      'Base legal: Ley 1480 de 2011 (Estatuto del Consumidor), '
                      'Art. 7-11.',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ─── Claim form ───────────────────────────────────────────────
              const Text(
                'Reclamar garantía',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Completa el formulario y nos contactaremos contigo en 5 días hábiles.',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),

              const SizedBox(height: 20),

              // Order ID field
              _buildLabel('Número de orden *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _orderIdController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('QRA-2026-000123'),
              ),

              const SizedBox(height: 20),

              // Defect description
              _buildLabel('Descripción del defecto *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _defectController,
                minLines: 3,
                maxLines: 8,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  'Describe el defecto de fabricación o problema de escaneabilidad. '
                  'Incluye cuándo fue detectado y en qué condiciones.',
                ),
              ),

              const SizedBox(height: 20),

              // Photo upload placeholder
              SecondaryGlassButton(
                text: 'Adjuntar foto (próximamente)',
                width: double.infinity,
                isLoading: false,
                onPressed: null, // Phase 10+ will add Storage upload
              ),

              const SizedBox(height: 8),
              Text(
                'La carga de fotos estará disponible próximamente.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Submit button
              PrimaryGlassButton(
                text: 'Enviar reclamo de garantía',
                width: double.infinity,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submitClaim,
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
            const BorderSide(color: Color(0xFF00FF88), width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Future<void> _submitClaim() async {
    final orderId = _orderIdController.text.trim();
    final defect = _defectController.text.trim();

    if (orderId.isEmpty || defect.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Por favor completa todos los campos obligatorios.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final currentUser = ref.read(supabaseAuthProvider).currentUser;
    setState(() => _isSubmitting = true);

    try {
      await Supabase.instance.client.from('pqrs_submissions').insert({
        'kind': 'reclamo',
        'subject': 'Reclamación de garantía — Orden $orderId',
        'body': defect,
        'email': currentUser?.email ?? '',
        'user_id': currentUser?.id,
        // order_id FK is UUID; we store the display number in the subject/body
        // Phase 10 will add a proper order lookup to resolve UUID from order_number
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Reclamo enviado. Nos contactaremos en 5 días hábiles.',
            ),
            backgroundColor: const Color(0xFF1E7E34),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        _orderIdController.clear();
        _defectController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar reclamo: $e'),
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
