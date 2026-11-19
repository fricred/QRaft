import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/qr_generator/presentation/pages/qr_canvas_editor_screen.dart';

// QRAFT-18: invalid URLs must not be accepted (or previewed as valid).
void main() {
  test('accepts real addresses', () {
    for (final u in ['qraft.app', 'https://qraft.app', 'http://a.b/c?d=1', ' qraft.app/x ', 'http://localhost:3000']) {
      expect(isPlausibleUrl(u), isTrue, reason: u);
    }
  });

  test('rejects text with spaces, no domain or other schemes', () {
    for (final u in ['esto no es una url', 'https://esto no es una url', 'hola', '', 'ftp://x.com', 'https://.com', 'qraft.']) {
      expect(isPlausibleUrl(u), isFalse, reason: u);
    }
  });
}
