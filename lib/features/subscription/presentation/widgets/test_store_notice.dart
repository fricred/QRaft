import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shown on every paywall when the build uses a RevenueCat Test Store key (QRAFT-2).
///
/// Debug/profile: purchases are simulated and nothing is charged.
/// Release: payments are unavailable (the SDK is deliberately left unconfigured).
class TestStoreNotice extends StatelessWidget {
  const TestStoreNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final text = kReleaseMode
        ? (es
            ? 'Los pagos no están disponibles por ahora. Vuelve a intentarlo más tarde.'
            : 'Payments are not available right now. Please try again later.')
        : (es
            ? 'Modo de prueba: las compras son simuladas y no se cobra nada.'
            : 'Test mode: purchases are simulated and nothing is charged.');
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF3A2E12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8A6A1F)),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFFFFE3A3), fontSize: 14, height: 1.4)),
      ),
    );
  }
}
