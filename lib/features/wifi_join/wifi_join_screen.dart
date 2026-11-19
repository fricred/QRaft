import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dynamic_qr/presentation/dq_ui.dart';

/// A network handed over by a scanned dynamic WiFi code:
/// `qraft://wifi?ssid=&pw=&sec=&hidden=` (built by supabase/functions/redirect/render.ts).
class WifiLink {
  const WifiLink({required this.ssid, required this.password, required this.security, required this.hidden});
  final String ssid;
  final String password;
  final String security;
  final bool hidden;

  bool get isOpen => password.isEmpty || security.toUpperCase() == 'NOPASS';

  static WifiLink? tryParse(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null || uri.scheme != 'qraft' || uri.host != 'wifi') return null;
    final ssid = uri.queryParameters['ssid'] ?? '';
    if (ssid.isEmpty) return null;
    return WifiLink(
      ssid: ssid,
      password: uri.queryParameters['pw'] ?? '',
      security: uri.queryParameters['sec'] ?? 'WPA',
      hidden: uri.queryParameters['hidden'] == 'true',
    );
  }
}

/// Works without a session: anyone who scanned the code can join in one tap.
class WifiJoinScreen extends StatefulWidget {
  const WifiJoinScreen({super.key, required this.wifi});
  final WifiLink wifi;

  @override
  State<WifiJoinScreen> createState() => _WifiJoinScreenState();
}

class _WifiJoinScreenState extends State<WifiJoinScreen> {
  static const _channel = MethodChannel('qraft/wifi');
  bool _busy = false;

  Future<void> _copyPassword({bool quiet = false}) async {
    await Clipboard.setData(ClipboardData(text: widget.wifi.password));
    if (!quiet && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dqT(context, 'Contraseña copiada', 'Password copied'))));
    }
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    try {
      final w = widget.wifi;
      final result = await _channel.invokeMethod<String>('addNetwork', {
        'ssid': w.ssid,
        'password': w.isOpen ? '' : w.password,
        'security': w.security,
        'hidden': w.hidden,
      });
      if (!mounted) return;
      if (result == 'settings' && !w.isOpen) {
        // No system dialog on this phone: settings opened, the password is ready to paste.
        await _copyPassword(quiet: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(dqT(context, 'Contraseña copiada. Elige “${w.ssid}” y pégala.', 'Password copied. Pick “${w.ssid}” and paste it.')),
        ));
      }
    } on PlatformException {
      await _copyPassword();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.wifi;
    return Scaffold(
      backgroundColor: kDqBg,
      appBar: AppBar(backgroundColor: kDqBg, foregroundColor: Colors.white, title: Text(dqT(context, 'Conectarse al WiFi', 'Join WiFi'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.wifi_rounded, color: Colors.white, size: 34),
              ),
            ),
            const SizedBox(height: 16),
            Text(w.ssid, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(w.isOpen ? dqT(context, 'Red abierta, sin contraseña', 'Open network, no password') : dqT(context, 'Red protegida', 'Secured network'),
                style: const TextStyle(color: kDqMuted, fontSize: 15)),
            if (!w.isOpen) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: BoxDecoration(color: kDqSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kDqLine)),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(dqT(context, 'Contraseña', 'Password'), style: const TextStyle(color: kDqMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      SelectableText(w.password, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                    ]),
                  ),
                  TextButton.icon(
                    key: const Key('wifi_join_copy_button'),
                    onPressed: _copyPassword,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(dqT(context, 'Copiar', 'Copy')),
                    style: TextButton.styleFrom(foregroundColor: kDqNeon, minimumSize: const Size(48, 48)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                key: const Key('wifi_join_connect_button'),
                onPressed: _busy ? null : _connect,
                icon: const Icon(Icons.wifi_rounded),
                label: Text(dqT(context, 'Conectar', 'Connect')),
                style: FilledButton.styleFrom(
                  backgroundColor: kDqNeon,
                  foregroundColor: kDqOnNeon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              dqT(context, 'Tu teléfono te pedirá confirmar “Guardar red”. Con eso queda conectado.',
                  'Your phone will ask you to confirm “Save network”. That connects you.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: kDqMuted, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
