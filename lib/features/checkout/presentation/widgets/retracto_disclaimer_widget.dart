import 'package:flutter/material.dart';

/// Reusable Ley 1480 Art. 47 retracto exemption disclaimer widget.
///
/// Renders an amber-bordered warning card explaining that personalized
/// QR-engraved products are excluded from the 5-day retracto right.
///
/// Used in:
///  - PaymentResultScreen success state (LGL-02)
///  - TermsScreen (embedded)
///
/// Semantics identifier: `retracto_disclaimer`
class RetractoDisclaimerWidget extends StatelessWidget {
  const RetractoDisclaimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'retracto_disclaimer',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFFFB300), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Productos personalizados (QR grabado bajo tu diseño) están '
                'excluidos del derecho de retracto de 5 días conforme al '
                'Art. 47 num. 3 de la Ley 1480 de 2011. Las garantías por '
                'defectos de fabricación aplican por 3 meses.',
                style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
