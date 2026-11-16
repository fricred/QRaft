import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';

/// In-app Habeas Data screen (Ley 1581 de 2012).
///
/// Provides two flows:
///  1. Data export request (derecho de acceso)
///  2. Account and data deletion request (derecho al olvido)
///
/// Actual deletion is a manual operator process until Phase 12.
/// A pqrs_submissions row is inserted as audit trail for Ley 1581 compliance.
class HabeasDataScreen extends ConsumerWidget {
  const HabeasDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(supabaseAuthProvider).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mis datos personales',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Semantics(
        identifier: 'habeas_data_screen',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF00FF88),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tus derechos — Ley 1581 de 2012',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Como titular de tus datos personales tienes derecho a acceder, '
                      'rectificar, actualizar y solicitar la supresión de tus datos '
                      'conforme a la Ley 1581 de 2012 (Habeas Data) de Colombia.',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Action 1: Export data ────────────────────────────────────
              _ActionCard(
                icon: Icons.download_outlined,
                iconColor: const Color(0xFF1A73E8),
                title: 'Exportar mis datos',
                subtitle: 'Derecho de acceso — Ley 1581 Art. 8(a)',
                description:
                    'Recibirás un correo con tus datos (QRs generados, historial de '
                    'escaneos, órdenes) en formato JSON en los próximos 5 días hábiles.',
                child: SecondaryGlassButton(
                  text: 'Solicitar exportación',
                  width: double.infinity,
                  isLoading: false,
                  onPressed: currentUser == null
                      ? null
                      : () => _requestDataExport(context, currentUser),
                ),
              ),

              const SizedBox(height: 16),

              // ─── Action 2: Delete account ─────────────────────────────────
              _ActionCard(
                icon: Icons.delete_forever_outlined,
                iconColor: Colors.redAccent,
                title: 'Eliminar mi cuenta y datos',
                subtitle: 'Derecho al olvido — Ley 1581 Art. 8(e)',
                description: null,
                warningText:
                    'Esta acción elimina tu cuenta, QRs, historial y órdenes '
                    'completadas. Las órdenes en proceso no se verán afectadas '
                    'hasta su finalización. El proceso puede tardar hasta 30 días hábiles.',
                child: GlassButton(
                  text: 'Solicitar eliminación',
                  width: double.infinity,
                  isLoading: false,
                  gradientColors: [
                    const Color(0xFFFF4444),
                    const Color(0xFFCC0000),
                  ],
                  onPressed: currentUser == null
                      ? null
                      : () => _confirmDeletion(context, ref, currentUser),
                ),
              ),

              const SizedBox(height: 32),

              // Contact info
              Text(
                'Para consultas adicionales sobre tus datos personales, '
                'escríbenos a privacy@scanqraft.app',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestDataExport(
      BuildContext context, User currentUser) async {
    try {
      await Supabase.instance.client.from('pqrs_submissions').insert({
        'kind': 'peticion',
        'subject': 'Solicitud de exportación de datos (habeas data)',
        'body':
            'El titular solicita exportación de sus datos personales conforme a la Ley 1581 de 2012.',
        'email': currentUser.email ?? '',
        'user_id': currentUser.id,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Solicitud enviada. Te contactaremos en 5 días hábiles.',
            ),
            backgroundColor: const Color(0xFF1E7E34),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar solicitud: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeletion(
      BuildContext context, WidgetRef ref, User currentUser) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              '¿Eliminar tu cuenta?',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Esta acción es irreversible. Tu cuenta, QRs, historial y datos '
          'personales serán eliminados en un plazo de 30 días hábiles.\n\n'
          'Las órdenes activas serán atendidas antes de la eliminación.',
          style: TextStyle(color: Colors.grey[300], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancelar', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Confirmar eliminación',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Insert audit trail record for Ley 1581 compliance
      await Supabase.instance.client.from('pqrs_submissions').insert({
        'kind': 'peticion',
        'subject': 'Solicitud de eliminación de cuenta (derecho al olvido)',
        'body':
            'El titular solicita la eliminación de su cuenta y datos personales '
            'conforme al derecho al olvido establecido en la Ley 1581 de 2012.',
        'email': currentUser.email ?? '',
        'user_id': currentUser.id,
      });

      // Sign out the user
      await ref.read(supabaseAuthProvider).signOut();

      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Solicitud de eliminación registrada. Procesaremos tu solicitud en 30 días hábiles.',
            ),
            backgroundColor: const Color(0xFF1E7E34),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar solicitud: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}

// ─── Private helper widget ────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.child,
    this.warningText,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? description;
  final String? warningText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3A)),
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
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 12),
            Text(
              description!,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          if (warningText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Text(
                warningText!,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
