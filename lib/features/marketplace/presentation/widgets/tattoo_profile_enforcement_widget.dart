import 'package:flutter/material.dart';
import '../pages/tattoo_faq_screen.dart';

/// Banner displayed on [ProductDetailScreen] when the selected product variant
/// uses the `tattoo_transfer` material.
///
/// Informs the user that Tattoo-Safe QR profile constraints are in effect:
/// - Error correction level H (30% damage tolerance)
/// - Maximum logo coverage 15%
/// - Larger modules for skin distortion compensation
///
/// Provides a "¿Por qué?" TextButton that navigates to [TattooFaqScreen].
class TattooProfileEnforcementWidget extends StatelessWidget {
  const TattooProfileEnforcementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(
          color: const Color(0xFF00FF88),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF00FF88),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Perfil Tattoo-Safe activado',
                  style: TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TattooFaqScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '¿Por qué?',
                  style: TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Módulos grandes  •  EC-H  •  Logo máx 15%',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Optimizado para escaneo en piel con distorsión del 30%.',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
