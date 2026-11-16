import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
// Both flutter_contacts and permission_handler export a PermissionStatus; the
// contacts permission check below uses the flutter_contacts one.
import 'package:permission_handler/permission_handler.dart'
    hide PermissionStatus;
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../../shared/widgets/glass_button.dart';
import 'models/scan_result.dart';

/// Full-page result of a scan, replacing the cramped dialog this used to be.
///
/// The extra room buys three things the modal could not show: the decoded QR
/// re-rendered (so the code can be shown to someone else without the original),
/// the parsed fields laid out as readable rows, and a primary action large
/// enough to be the obvious next step.
class ScanResultScreen extends StatelessWidget {
  final ScanResult scanResult;

  const ScanResultScreen({super.key, required this.scanResult});

  static const _bg = Color(0xFF1A1A1A);
  static const _card = Color(0xFF2E2E2E);
  static const _neon = Color(0xFF00FF88);

  /// Pushes the screen and returns once the user leaves it.
  static Future<void> push(BuildContext context, ScanResult scanResult) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanResultScreen(scanResult: scanResult),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = _typeColor;

    return Semantics(
      identifier: 'scan_result_screen_root',
      container: true,
      child: Scaffold(
        key: const Key('scan_result_screen_root'),
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, l10n),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(context, l10n, accent),
                      const SizedBox(height: 32),
                      _buildQrPreview(),
                      const SizedBox(height: 24),
                      _buildContentCard(context, l10n, accent),
                      if (_hasDetails) ...[
                        const SizedBox(height: 16),
                        _buildDetailsCard(l10n, accent),
                      ],
                      const SizedBox(height: 16),
                      _buildTimestamp(),
                    ],
                  ),
                ),
              ),
              _buildFooter(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_rounded,
            semanticsIdentifier: 'scan_result_back_button',
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              l10n.scanResultTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _CircleIconButton(
            icon: Icons.share_rounded,
            semanticsIdentifier: 'scan_result_share_button',
            tooltip: l10n.share,
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: scanResult.rawValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    AppLocalizations l10n,
    Color accent,
  ) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(_typeIcon, color: Colors.white, size: 44),
        )
            .animate()
            .scale(
              begin: const Offset(0.6, 0.6),
              duration: 420.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 260.ms),
        const SizedBox(height: 20),
        Text(
          l10n.scanResultSuccess,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 120.ms, duration: 320.ms).slideY(begin: 0.25),
        const SizedBox(height: 12),
        _TypePill(label: _typeLabel(l10n), icon: _typeIcon, color: accent)
            .animate()
            .fadeIn(delay: 200.ms, duration: 320.ms),
      ],
    );
  }

  /// Re-renders the scanned payload so the code itself is on screen — useful to
  /// pass it along without the original photo or object.
  Widget _buildQrPreview() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          width: 160,
          height: 160,
          child: PrettyQrView.data(
            data: scanResult.rawValue,
            decoration: const PrettyQrDecoration(
              shape: PrettyQrSmoothSymbol(color: Colors.black),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 280.ms, duration: 360.ms).slideY(begin: 0.15);
  }

  Widget _buildContentCard(
    BuildContext context,
    AppLocalizations l10n,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.scanResultContent,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              _CircleIconButton(
                icon: Icons.copy_rounded,
                size: 38,
                iconSize: 18,
                color: accent,
                semanticsIdentifier: 'scan_result_copy_button',
                tooltip: l10n.copy,
                onPressed: () => _copyToClipboard(context, l10n),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            scanResult.displayValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 340.ms, duration: 320.ms).slideY(begin: 0.12);
  }

  Widget _buildDetailsCard(AppLocalizations l10n, Color accent) {
    final entries = scanResult.parsedData!.entries
        .where((e) => e.value != null && '${e.value}'.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            l10n.scanResultDetails,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          for (final entry in entries) ...[
            const Divider(color: Colors.white12, height: 20),
            _DetailRow(
              label: _humanizeKey(entry.key),
              value: '${entry.value}',
              accent: accent,
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 320.ms).slideY(begin: 0.12);
  }

  Widget _buildTimestamp() {
    final t = scanResult.scannedAt;
    final stamp =
        '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year} · '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.schedule_rounded, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(stamp, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    ).animate().fadeIn(delay: 460.ms);
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            identifier: 'scan_result_primary_action',
            child: PrimaryGlassButton(
              key: const Key('scan_result_primary_action'),
              text: _actionLabel(l10n),
              icon: _actionIcon,
              width: double.infinity,
              onPressed: () => _performAction(context, l10n),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('scan_result_scan_again'),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.qr_code_scanner_rounded,
                size: 18, color: Colors.white70),
            label: Text(
              l10n.scanResultScanAgain,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 300.ms);
  }

  // ---------------------------------------------------------------------------
  // Type mapping
  // ---------------------------------------------------------------------------

  bool get _hasDetails =>
      scanResult.parsedData != null && scanResult.parsedData!.isNotEmpty;

  IconData get _typeIcon {
    switch (scanResult.type) {
      case QRCodeType.url:
        return Icons.link_rounded;
      case QRCodeType.wifi:
        return Icons.wifi_rounded;
      case QRCodeType.email:
        return Icons.email_rounded;
      case QRCodeType.phone:
        return Icons.phone_rounded;
      case QRCodeType.sms:
        return Icons.message_rounded;
      case QRCodeType.vcard:
        return Icons.contact_page_rounded;
      case QRCodeType.location:
        return Icons.location_on_rounded;
      default:
        return Icons.text_fields_rounded;
    }
  }

  Color get _typeColor {
    switch (scanResult.type) {
      case QRCodeType.url:
        return const Color(0xFF1A73E8);
      case QRCodeType.wifi:
        return _neon;
      case QRCodeType.email:
        return const Color(0xFFFF9800);
      case QRCodeType.phone:
        return const Color(0xFF34C759);
      case QRCodeType.sms:
        return const Color(0xFF2196F3);
      case QRCodeType.vcard:
        return const Color(0xFF9C4DFF);
      case QRCodeType.location:
        return const Color(0xFFFF5A5F);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  String _typeLabel(AppLocalizations l10n) {
    switch (scanResult.type) {
      case QRCodeType.url:
        return l10n.qrTypeUrl;
      case QRCodeType.wifi:
        return l10n.qrTypeWifi;
      case QRCodeType.email:
        return l10n.qrTypeEmail;
      case QRCodeType.phone:
        return l10n.qrTypePhone;
      case QRCodeType.sms:
        return l10n.qrTypeSms;
      case QRCodeType.vcard:
        return l10n.qrTypeVcard;
      case QRCodeType.location:
        return l10n.qrTypeLocation;
      default:
        return l10n.scanTypePlainText;
    }
  }

  String _actionLabel(AppLocalizations l10n) {
    switch (scanResult.type) {
      case QRCodeType.url:
        return l10n.qrActionOpen;
      case QRCodeType.wifi:
        return l10n.qrActionConnect;
      case QRCodeType.vcard:
        return l10n.qrActionSaveContact;
      case QRCodeType.email:
        return l10n.qrActionEmail;
      case QRCodeType.phone:
        return l10n.qrActionCall;
      case QRCodeType.sms:
        return l10n.qrActionMessage;
      case QRCodeType.location:
        return l10n.qrActionOpenMap;
      default:
        return l10n.qrActionShare;
    }
  }

  IconData get _actionIcon {
    switch (scanResult.type) {
      case QRCodeType.url:
        return Icons.open_in_new_rounded;
      case QRCodeType.wifi:
        return Icons.wifi_rounded;
      case QRCodeType.vcard:
        return Icons.contact_page_rounded;
      case QRCodeType.email:
        return Icons.email_rounded;
      case QRCodeType.phone:
        return Icons.call_rounded;
      case QRCodeType.sms:
        return Icons.message_rounded;
      case QRCodeType.location:
        return Icons.map_rounded;
      default:
        return Icons.share_rounded;
    }
  }

  String _humanizeKey(String key) {
    final spaced = key.replaceAll('_', ' ');
    if (spaced.isEmpty) return spaced;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _copyToClipboard(BuildContext context, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: scanResult.rawValue));
    HapticFeedback.lightImpact();
    _toast(context, l10n.copiedToClipboard, _neon);
  }

  Future<void> _performAction(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    try {
      switch (scanResult.type) {
        case QRCodeType.url:
          final rawUrl = scanResult.rawValue;
          final formattedUrl =
              rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
          final uri = Uri.parse(formattedUrl);
          // canLaunchUrl is occasionally over-restrictive, so a false result is
          // not treated as final — the launch is attempted regardless.
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          break;

        case QRCodeType.email:
          final email = scanResult.parsedData?['email'] ?? scanResult.rawValue;
          await launchUrl(Uri.parse('mailto:$email'));
          break;

        case QRCodeType.phone:
          final phone = scanResult.parsedData?['number'] ?? scanResult.rawValue;
          await launchUrl(Uri.parse('tel:$phone'));
          break;

        case QRCodeType.sms:
          final phone = scanResult.parsedData?['number'] ?? '';
          final body = scanResult.parsedData?['body'] ?? '';
          await launchUrl(
            Uri.parse('sms:$phone${body.isNotEmpty ? '?body=$body' : ''}'),
          );
          break;

        case QRCodeType.location:
          final lat = scanResult.parsedData?['latitude'];
          final lng = scanResult.parsedData?['longitude'];
          if (lat != null && lng != null) {
            await launchUrl(
              Uri.parse('https://maps.google.com/?q=$lat,$lng'),
              mode: LaunchMode.externalApplication,
            );
          }
          break;

        case QRCodeType.vcard:
          // flutter_contacts 2.x: the boolean requestPermission() became a
          // typed permissions API. Inserting a contact needs write access.
          final permission =
              await FlutterContacts.permissions.request(PermissionType.write);
          if (permission != PermissionStatus.granted) {
            if (context.mounted) {
              _toast(context, l10n.contactsPermissionRequired, Colors.orange);
            }
            return;
          }
          final fullName = scanResult.parsedData?['name'] as String? ?? '';
          final nameParts = fullName.split(' ');
          // Contact and its property lists are immutable in flutter_contacts
          // 2.x, so the whole graph is built through constructors.
          final contact = Contact(
            name: Name(
              first: nameParts.isNotEmpty ? nameParts.first : fullName,
              last: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
            ),
            phones: [
              if (scanResult.parsedData?['phone'] != null)
                Phone(number: scanResult.parsedData!['phone'] as String),
            ],
            emails: [
              if (scanResult.parsedData?['email'] != null)
                Email(address: scanResult.parsedData!['email'] as String),
            ],
            organizations: [
              if (scanResult.parsedData?['organization'] != null)
                Organization(
                  name: scanResult.parsedData!['organization'] as String,
                ),
            ],
          );
          await FlutterContacts.create(contact);
          if (context.mounted) {
            _toast(context, l10n.contactSaved, _neon);
          }
          return;

        case QRCodeType.wifi:
          if (context.mounted) {
            showModalBottomSheet(
              context: context,
              backgroundColor: _card,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => _WifiCredentialsSheet(
                ssid: scanResult.parsedData?['ssid'] as String? ?? '',
                password: scanResult.parsedData?['password'] as String? ?? '',
                security: scanResult.parsedData?['security'] as String? ?? 'WPA',
              ),
            );
          }
          return;

        default:
          await SharePlus.instance
              .share(ShareParams(text: scanResult.rawValue));
          break;
      }

      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('❌ Error performing action: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.unableToPerformAction),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: l10n.copy,
              textColor: Colors.white,
              onPressed: () => Clipboard.setData(
                ClipboardData(text: scanResult.rawValue),
              ),
            ),
          ),
        );
      }
    }
  }

  static void _toast(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pieces
// -----------------------------------------------------------------------------

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticsIdentifier;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color color;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticsIdentifier,
    this.tooltip,
    this.size = 44,
    this.iconSize = 22,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticsIdentifier,
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.07),
        shape: const CircleBorder(),
        child: InkWell(
          key: Key(semanticsIdentifier),
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TypePill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _WifiCredentialsSheet extends StatelessWidget {
  final String ssid;
  final String password;
  final String security;

  const _WifiCredentialsSheet({
    required this.ssid,
    required this.password,
    required this.security,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_rounded,
                  color: ScanResultScreen._neon, size: 24),
              const SizedBox(width: 12),
              Text(
                l10n.qrTypeWifi,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ScanResultScreen._neon.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  security,
                  style: const TextStyle(
                    color: ScanResultScreen._neon,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _CredentialRow(label: l10n.wifiSsidLabel, value: ssid),
          const SizedBox(height: 12),
          _CredentialRow(
            label: l10n.wifiPasswordLabel,
            value: password,
            obscure: true,
          ),
          const SizedBox(height: 24),
          Semantics(
            identifier: 'wifi_open_settings_button',
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('wifi_open_settings_button'),
                onPressed: () async {
                  // iOS: App-prefs:root=WIFI, Android: WIFI_SETTINGS.
                  // Fall back to openAppSettings() if neither launches.
                  final iosUri = Uri.parse('App-prefs:root=WIFI');
                  final androidUri = Uri.parse('android.settings.WIFI_SETTINGS');
                  bool launched = false;
                  if (await canLaunchUrl(iosUri)) {
                    launched = await launchUrl(iosUri);
                  } else if (await canLaunchUrl(androidUri)) {
                    launched = await launchUrl(androidUri);
                  }
                  if (!launched) {
                    await openAppSettings();
                  }
                },
                icon: const Icon(Icons.settings_rounded),
                label: Text(l10n.wifiOpenSettings),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScanResultScreen._neon,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;
  final bool obscure;

  const _CredentialRow({
    required this.label,
    required this.value,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  obscure && value.isNotEmpty
                      ? '•' * value.length.clamp(0, 16)
                      : value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.copy,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              HapticFeedback.lightImpact();
              ScanResultScreen._toast(
                context,
                AppLocalizations.of(context)!.copiedToClipboard,
                ScanResultScreen._neon,
              );
            },
            icon: const Icon(Icons.copy_rounded,
                color: ScanResultScreen._neon, size: 20),
          ),
        ],
      ),
    );
  }
}
