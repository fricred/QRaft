import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../qr_generator/domain/entities/qr_type.dart';
import '../../qr_generator/domain/services/qr_decoration_builder.dart';
import '../data/dynamic_qr_repository.dart';

// Shared look for the dynamic QR screens (same palette as the QR editor).
const kDqBg = Color(0xFF1A1A1A);
const kDqSurface = Color(0xFF2E2E2E);
const kDqLine = Color(0xFF6B7480); // ≥3:1 on the surfaces, for borders of controls
const kDqNeon = Color(0xFF00FF88);
const kDqOnNeon = Color(0xFF04140D);
const kDqMuted = Color(0xFFB4BCC6);
const kDqAmber = Color(0xFFFACC15);
const kDqError = Color(0xFFF87171);

/// Inline Spanish/English copy, like the rest of the QR editor.
String dqT(BuildContext context, String es, String en) =>
    Localizations.localeOf(context).languageCode == 'es' ? es : en;

final dynamicQrRepositoryProvider = Provider<DynamicQrRepository>(
  (ref) => DynamicQrRepository(Supabase.instance.client),
);

final myDynamicQrsProvider = FutureProvider.autoDispose<List<DynamicQr>>(
  (ref) => ref.watch(dynamicQrRepositoryProvider).listMine(),
);

final dynamicQrProvider = FutureProvider.autoDispose.family<DynamicQr?, String>(
  (ref, id) => ref.watch(dynamicQrRepositoryProvider).get(id),
);

final dynamicQrScansProvider = FutureProvider.autoDispose.family<List<int>, (String, int)>(
  (ref, key) => ref.watch(dynamicQrRepositoryProvider).dailyScans(key.$1, days: key.$2),
);

final dynamicQrHistoryProvider = FutureProvider.autoDispose.family<List<DynamicQrHistoryEntry>, String>(
  (ref, id) => ref.watch(dynamicQrRepositoryProvider).history(id),
);

final dynamicQrCreditsProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(dynamicQrRepositoryProvider).unusedCredits(),
);

/// Short "what it shows" line for a payload: "Link · menu.cafe.co", "Contacto · Ana Ruiz"…
String describeContent(BuildContext context, QRType? type, String payload) {
  String line(String key) {
    final m = RegExp('^$key(?:;[^:\\n]*)?:(.*)\$', multiLine: true, caseSensitive: false).firstMatch(payload);
    return (m?.group(1) ?? '').replaceAll(r'\,', ',').replaceAll(r'\;', ';').trim();
  }

  String clip(String s, [int n = 40]) => s.length > n ? '${s.substring(0, n - 1)}…' : s;
  final label = type == null ? '—' : typeLabel(context, type);
  final summary = switch (type) {
    QRType.url => Uri.tryParse(payload)?.let((u) => '${u.host}${u.path == '/' ? '' : u.path}') ?? payload,
    QRType.text => payload.replaceAll('\n', ' '),
    QRType.personalInfo => line('FN'),
    QRType.event => line('SUMMARY'),
    QRType.location => payload.replaceFirst(RegExp('^geo:', caseSensitive: false), '').split('?').first,
    QRType.wifi => RegExp(r'S:((?:\\.|[^;])*)').firstMatch(payload)?.group(1)?.replaceAll(r'\', '') ?? '',
    QRType.email => payload.replaceFirst(RegExp('^mailto:', caseSensitive: false), '').split('?').first,
    null => '',
  };
  return summary.isEmpty ? label : '$label · ${clip(summary)}';
}

String typeLabel(BuildContext context, QRType type) => switch (type) {
      QRType.url => 'Link',
      QRType.text => dqT(context, 'Texto', 'Text'),
      QRType.personalInfo => dqT(context, 'Contacto', 'Contact'),
      QRType.event => dqT(context, 'Evento', 'Event'),
      QRType.location => dqT(context, 'Ubicación', 'Location'),
      QRType.wifi => 'WiFi',
      QRType.email => 'Email',
    };

IconData typeIcon(QRType? type) => switch (type) {
      QRType.url => Icons.link_rounded,
      QRType.text => Icons.notes_rounded,
      QRType.personalInfo => Icons.person_rounded,
      QRType.event => Icons.event_rounded,
      QRType.location => Icons.place_rounded,
      QRType.wifi => Icons.wifi_rounded,
      QRType.email => Icons.mail_rounded,
      null => Icons.qr_code_2_rounded,
    };

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

/// The printed code with its real design.
class DynamicQrImage extends StatelessWidget {
  const DynamicQrImage({super.key, required this.data, required this.customization, this.size = 160, this.dimmed = false});

  final String data;
  final QRCustomization customization;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    Widget qr;
    try {
      qr = PrettyQrView(
        qrImage: QrDecorationBuilder.buildQrImage(data, customization),
        decoration: QrDecorationBuilder.buildDecoration(customization),
      );
    } catch (_) {
      qr = const Icon(Icons.qr_code_2_rounded, size: 64, color: Colors.black54);
    }
    return Semantics(
      image: true,
      label: dqT(context, 'Código QR de $data', 'QR code for $data'),
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.06),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Opacity(opacity: dimmed ? 0.35 : 1, child: qr),
      ),
    );
  }
}

class DynamicStatusChip extends StatelessWidget {
  const DynamicStatusChip(this.status, {super.key});
  final DynamicQrStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      DynamicQrStatus.active => (dqT(context, 'Activo', 'Active'), kDqNeon.withValues(alpha: 0.14), const Color(0xFF5CF0B4)),
      DynamicQrStatus.paused => (dqT(context, 'Pausado', 'Paused'), const Color(0xFF3A424E), const Color(0xFFD5DAE0)),
      DynamicQrStatus.pendingPayment => (dqT(context, 'Pago pendiente', 'Payment pending'), kDqAmber.withValues(alpha: 0.14), const Color(0xFFFDE68A)),
      DynamicQrStatus.blocked => (dqT(context, 'Bloqueado', 'Blocked'), kDqError.withValues(alpha: 0.14), const Color(0xFFFCA5A5)),
      DynamicQrStatus.revoked => (dqT(context, 'Eliminado', 'Deleted'), const Color(0xFF3A424E), const Color(0xFFD5DAE0)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

const _kShortenerHosts = {
  'bit.ly', 'bitly.com', 'tinyurl.com', 't.co', 'goo.gl', 'ow.ly', 'is.gd', 'buff.ly', 'cutt.ly',
  'rebrand.ly', 'shorturl.at', 'tiny.cc', 'rb.gy', 's.id', 't.ly', 'v.gd', 'shorte.st', 'adf.ly',
};

/// Same host rules as the server's `validateContent` (supabase/functions/_shared/dynamic_qr.ts),
/// checked before checkout so the owner fixes the link in the editor instead of a failed payment.
/// Returns the server error code, or null when the URL is acceptable.
String? dynamicUrlProblem(String url) {
  final raw = url.trim();
  final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
  if (uri == null || uri.host.isEmpty) return null; // the form validator handles malformed URLs
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  if (host == 'scanqraft.app' || host.endsWith('.scanqraft.app')) return 'own_domain_not_allowed';
  if (_kShortenerHosts.contains(host)) return 'shortener_not_allowed';
  return null;
}

/// Error codes caused by what the code shows (fixable in the editor), not by the payment.
bool isDynamicContentError(Object error) =>
    error is DynamicQrException &&
    const {
      'invalid_url', 'shortener_not_allowed', 'own_domain_not_allowed', 'unsafe_url', 'content_too_long', 'empty_content',
      'invalid_vcard', 'invalid_event', 'invalid_wifi', 'invalid_email', 'invalid_location', 'invalid_type',
    }.contains(error.code);

/// Content rejected by a safety rule (hidden or dangerous destination), as opposed to a typo.
bool isDynamicSecurityError(Object error) =>
    error is DynamicQrException && const {'shortener_not_allowed', 'unsafe_url'}.contains(error.code);

/// User-facing message for a `dynamic-qr` function error code.
String dynamicQrErrorText(BuildContext context, Object error) {
  final code = error is DynamicQrException ? error.code : 'server_error';
  return switch (code) {
    'invalid_url' => dqT(context, 'Escribe una dirección web válida, sin espacios.', 'Enter a valid web address, without spaces.'),
    'shortener_not_allowed' => dqT(context,
        'Por seguridad no aceptamos links acortados (bit.ly, tinyurl…): esconden a dónde lleva el código. Pega el link final de la página.',
        "For safety we don't accept shortened links (bit.ly, tinyurl…): they hide where the code leads. Paste the page's final link."),
    'own_domain_not_allowed' => dqT(context,
        'Ese link es de QRaft (scanqraft.app): el código se apuntaría a sí mismo. Pon la web a la que quieres llevar a la gente, por ejemplo la de tu negocio.',
        "That's a QRaft link (scanqraft.app): the code would point to itself. Enter the website you want people to land on, e.g. your business site."),
    'unsafe_url' => dqT(context,
        'Por seguridad bloqueamos este link: Google lo tiene marcado como peligroso (phishing o malware). Usa otro.',
        'For safety we blocked this link: Google flags it as dangerous (phishing or malware). Use another one.'),
    'content_too_long' => dqT(context, 'El contenido es demasiado largo.', 'The content is too long.'),
    'empty_content' || 'invalid_vcard' || 'invalid_event' || 'invalid_wifi' || 'invalid_email' || 'invalid_location' =>
      dqT(context, 'Revisa los datos: falta algo o no es válido.', 'Check the details: something is missing or invalid.'),
    'too_many_pending' => dqT(context, 'Tienes 3 códigos sin pagar. Completa o elimina uno en Mis QR dinámicos.', 'You have 3 unpaid codes. Finish or delete one in My dynamic QRs.'),
    'redirect_not_editable' => dqT(context, 'Este código ya no se puede editar.', 'This code can no longer be edited.'),
    'redirect_not_pausable' => dqT(context, 'Este código no se puede pausar ahora.', "This code can't be paused right now."),
    _ => dqT(context, 'No pudimos completar la acción. Revisa tu conexión e inténtalo de nuevo.', "We couldn't finish that. Check your connection and try again."),
  };
}
