// Screen 3 of the QR creation flow: tap-to-edit canvas with tool rail.
// TypePicker → TemplatesPicker → [this screen]
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/utils/inline_l10n.dart';
import '../../../profile/data/providers/profile_stats_providers.dart' show userProfileProvider;
import '../../../../core/utils/friendly_error.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/qr_code_entity.dart';
import '../../domain/entities/qr_data_models.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/services/qr_decoration_builder.dart';
import '../../domain/value_objects/qr_profile.dart';
import '../controllers/qr_customization_controller.dart';
import '../providers/qr_providers.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';
import '../../../qr_library/presentation/providers/qr_library_providers.dart';
import '../../../subscription/presentation/providers/feature_gate_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../subscription/presentation/widgets/upgrade_bottom_sheet.dart';
import '../../../dynamic_qr/presentation/checkout_screen.dart';
import '../../../dynamic_qr/presentation/save_kind_sheet.dart';
import '../../../dynamic_qr/data/dynamic_qr_repository.dart' show DynamicQrException;
import '../../../dynamic_qr/presentation/dq_ui.dart' show dynamicUrlProblem, dynamicQrErrorText;

// ── Design Tokens ──────────────────────────────────────────────────────────────
const _kBg = Color(0xFF1A1A1A);
const _kSurface = Color(0xFF2E2E2E);
const _kNeon = Color(0xFF00FF88);
const _kLine = Color(0xFF3A3A3A);
const _kAmber = Color(0xFFF59E0B);
const _kBlue = Color(0xFF1A73E8);
const _kError = Color(0xFFEF4444);

// ── Preset Data ────────────────────────────────────────────────────────────────
final _kSolidColors = [
  const Color(0xFF000000),
  const Color(0xFF1A73E8),
  const Color(0xFF00FF88),
  const Color(0xFF6366F1),
  const Color(0xFFEF4444),
  const Color(0xFFF59E0B),
  const Color(0xFF10B981),
  const Color(0xFFEC4899),
  const Color(0xFF8B5CF6),
  const Color(0xFFF97316),
  const Color(0xFF06B6D4),
  const Color(0xFF2E2E2E),
];

final _kGradients = <(String, Color, Color)>[
  ('Neon', const Color(0xFF00FF88), const Color(0xFF1A73E8)),
  ('Sunset', const Color(0xFFFF7E5F), const Color(0xFFFEB47B)),
  ('Ocean', const Color(0xFF1A73E8), const Color(0xFF0D47A1)),
  ('Forest', const Color(0xFF00B09B), const Color(0xFF096B3B)),
  ('Fire', const Color(0xFFFF416C), const Color(0xFFFF4B2B)),
  ('Candy', const Color(0xFF8B5CF6), const Color(0xFFEC4899)),
];

// modulePreset 0=Squares(rounding:0)  2=Squares(rounding:0.8,density:0.9)
//              3=SmoothSymbol(bezier merged) 5=DotsSymbol(circles)
const _kDotOptions = <(String, int)>[
  ('Square', 0),
  ('Rounded', 2),
  ('Smooth', 3),
  ('Dots', 5),
];

// All 4 eye options use unified finder pattern for a clean independent ring:
// 0=Squares(rounding:0)  1=Squares(rounding:0.5,unified)
// 3=Squares(rounding:0.8,unified)       2=DotsSymbol(unified)
const _kEyeOptions = <(String, int)>[
  ('Square', 0),
  ('Rounded', 1),
  ('Smooth', 3),
  ('Circle', 2),
];

int _colorToArgb(Color c) =>
    ((c.a * 255).round() << 24) |
    ((c.r * 255).round() << 16) |
    ((c.g * 255).round() << 8) |
    (c.b * 255).round();

// ── Screen ─────────────────────────────────────────────────────────────────────

/// What the editor returns in [QRCanvasEditorScreen.contentOnly] mode: the payload a
/// static QR of [type] would encode, without saving anything.
class QrContentResult {
  const QrContentResult({required this.type, required this.payload, required this.display});
  final QRType type;
  final String payload;
  final String display;
}

class QRCanvasEditorScreen extends ConsumerStatefulWidget {
  final QRType qrType;
  final QrFullTemplate template;
  final QRCodeEntity? editingQR;

  /// Dynamic QR "Cambiar lo que muestra": the data sheet opens right away and Save
  /// pops a [QrContentResult] instead of writing a QR.
  final bool contentOnly;

  /// Save sheet opens with "Dinámico" selected (user picked dynamic mode).
  final bool preferDynamic;

  const QRCanvasEditorScreen({
    super.key,
    required this.qrType,
    required this.template,
    this.editingQR,
    this.contentOnly = false,
    this.preferDynamic = false,
  });

  @override
  ConsumerState<QRCanvasEditorScreen> createState() =>
      _QRCanvasEditorScreenState();
}

class _QRCanvasEditorScreenState extends ConsumerState<QRCanvasEditorScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  String? _openTool;
  bool _dirty = false;
  bool _saving = false;
  bool _checkingLimit = false;
  Map<String, dynamic>? _originalFormData;

  /// Event date typed in the data sheet ("YYYY-MM-DD HH:MM", local), if valid.
  DateTime? get _typedEventDate {
    final raw = (_formData['eventDate'] as String? ?? '').trim();
    final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[ T](\d{1,2}):(\d{2}))?$').firstMatch(raw);
    if (m == null) return null;
    final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), d = int.parse(m.group(3)!);
    final h = int.parse(m.group(4) ?? '0'), mi = int.parse(m.group(5) ?? '0');
    final dt = DateTime(y, mo, d, h, mi);
    // Reject impossible dates/times instead of letting DateTime roll them over.
    if (dt.year != y || dt.month != mo || dt.day != d || dt.hour != h || dt.minute != mi) {
      return null;
    }
    return dt;
  }

  /// A typed date that is present but not valid blocks saving (the sheet reopens).
  bool get _eventDateInvalid =>
      (_formData['eventDate'] as String? ?? '').trim().isNotEmpty && _typedEventDate == null;

  /// True when the user only changed style, not the QR's data fields.
  bool get _dataUnchanged {
    final original = _originalFormData;
    if (original == null) return false;
    final keys = {...original.keys, ..._formData.keys}..remove('name');
    return keys.every((k) => '${original[k] ?? ''}' == '${_formData[k] ?? ''}');
  }
  bool _saved = false;
  bool _showExit = false;
  bool _sharing = false;
  Map<String, dynamic> _formData = {};
  String _frameKind = 'none';
  String _labelText = 'SCAN ME';
  int _sizeStep = 2; // 0..4 → S / M / L / XL / XX

  /// Default start for a new event, fixed once so preview, share and save agree.
  late final DateTime _defaultEventStart = () {
    final d = DateTime.now().add(const Duration(days: 7));
    return DateTime(d.year, d.month, d.day, 10);
  }();

  static const _kDisplaySizes = [150.0, 180.0, 210.0, 240.0, 270.0];
  static const _kExportSizes = [300.0, 500.0, 750.0, 1000.0, 1500.0];

  double get _displaySize => _kDisplaySizes[_sizeStep];

  bool get _isDataFilled => switch (widget.qrType) {
    QRType.url => _dataUnchanged || isPlausibleUrl(_formData['url'] as String? ?? ''),
    QRType.text => (_formData['text'] as String? ?? '').isNotEmpty,
    QRType.wifi => (_formData['ssid'] as String? ?? '').isNotEmpty,
    QRType.email => (_formData['email'] as String? ?? '').isNotEmpty,
    // Coordinates must be real numbers in range (comma or dot decimals), never 0,0 by accident.
    QRType.location => _dataUnchanged || () {
      final lat = double.tryParse((_formData['lat'] as String? ?? '').replaceAll(',', '.'));
      final lng = double.tryParse((_formData['lng'] as String? ?? '').replaceAll(',', '.'));
      return lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180;
    }(),
    QRType.event => _dataUnchanged ||
      (_formData['title'] as String? ?? '').isNotEmpty &&
          !_eventDateInvalid &&
          // A new event needs a real date: never silently "a week from now".
          (_typedEventDate != null ||
              _formData['dateTime'] != null ||
              (_formData['rawDtLines'] as String? ?? '').isNotEmpty),
    QRType.personalInfo =>
      _dataUnchanged || (_formData['firstName'] as String? ?? '').isNotEmpty,
  };

  String get _previewQrData {
    // A dynamic QR prints its scanqraft.app link whatever it shows.
    final dyn = widget.editingQR;
    if (!widget.contentOnly && dyn != null && dyn.isDynamic) return 'https://scanqraft.app/${dyn.slug}';
    if (!_isDataFilled) {
      return switch (widget.qrType) {
        QRType.url => 'https://scanqraft.app',
        QRType.text => tr('Hello, world!'),
        QRType.wifi => 'WIFI:T:WPA;S:QRaft;P:demo1234;H:false;;',
        QRType.email => 'mailto:you@example.com',
        QRType.location => 'geo:40.7128,-74.0060',
        QRType.event =>
          'BEGIN:VCALENDAR\nBEGIN:VEVENT\nSUMMARY:My Event\nEND:VEVENT\nEND:VCALENDAR',
        QRType.personalInfo =>
          'BEGIN:VCARD\nVERSION:3.0\nFN:Jane Doe\nEND:VCARD',
      };
    }
    // Preview/share must encode exactly what will be saved: same model, and for a
    // style-only edit the original payload.
    if (_dataUnchanged) return widget.editingQR!.data;
    final model = _buildDataModel();
    return model == null ? '' : _finalQrData(model);
  }


  /// Final payload for [model]: an event that originally carried TZID / all-day dates
  /// keeps its exact DTSTART/DTEND lines instead of a reinterpreted local time.
  String _finalQrData(QRDataModel model) {
    final raw = _formData['rawDtLines'] as String?;
    // A date typed by the user replaces the original lines.
    if (widget.qrType != QRType.event || raw == null || raw.isEmpty) return model.qrData;
    // New start typed: the original end can't be shifted safely across formats (TZID,
    // all-day, UTC), so it is dropped — an event without an end is valid, end < start isn't.
    if (_typedEventDate != null) return model.qrData;
    final stripped = model.qrData
        .split('\n')
        .where((l) => !l.startsWith('DTSTART') && !l.startsWith('DTEND'))
        .toList();
    final at = stripped.indexWhere((l) => l.startsWith('SUMMARY'));
    stripped.insertAll(at < 0 ? stripped.length : at + 1, raw.split('\n'));
    return stripped.join('\n');
  }

  QRDataModel? _buildDataModel() {
    if (!_isDataFilled) return null;
    return switch (widget.qrType) {
      QRType.url => URLData(url: (_formData['url'] as String? ?? '').trim()),
      QRType.text => TextData(text: _formData['text'] as String? ?? ''),
      QRType.wifi => WiFiData(
        networkName: _formData['ssid'] as String? ?? '',
        hidden: _formData['hidden'] as bool? ?? false, // keep hidden networks hidden
        password: _formData['password'] as String? ?? '',
        // No password = open network: phones must not try WPA with an empty key.
        security: (_formData['password'] as String? ?? '').isEmpty
            ? 'nopass'
            // A password on a network previously saved as open means it is secured now.
            : (() {
                final sec = _formData['security'] as String? ?? 'WPA';
                return sec == 'nopass' ? 'WPA' : sec;
              })(),
      ),
      QRType.email => EmailData(
        email: _formData['email'] as String? ?? '',
        subject: _formData['subject'] as String? ?? '',
        body: _formData['body'] as String? ?? '',
      ),
      QRType.location => () {
        // Accept a decimal comma (Spanish keypads) instead of silently saving 0,0.
        final lat = double.tryParse((_formData['lat'] as String? ?? '').replaceAll(',', '.')) ?? 0.0;
        final lng = double.tryParse((_formData['lng'] as String? ?? '').replaceAll(',', '.')) ?? 0.0;
        return LocationData(
          latitude: lat,
          longitude: lng,
          name: (_formData['locName'] as String?)?.trim().isEmpty ?? true ? null : (_formData['locName'] as String).trim(),
        );
      }(),
      QRType.event => EventData(
        title: _formData['title'] as String? ?? '',
        location: _formData['location'] as String? ?? '',
startDateTime: _typedEventDate ??
            (_formData['dateTime'] as DateTime?) ??
            _defaultEventStart,
        // Preserved from the original QR when editing.
        // Moving the start moves the original end by the same amount (never end < start).
        endDateTime: (() {
          final end = _formData['endDateTime'] as DateTime?;
          final origStart = _formData['dateTime'] as DateTime?;
          final typed = _typedEventDate;
          if (end == null || typed == null) return end;
          if (origStart == null) return null; // can't shift safely: drop rather than end < start
          final origMinute = DateTime(origStart.year, origStart.month, origStart.day,
              origStart.hour, origStart.minute);
          if (typed == origMinute) return end; // start not really changed
          return end.add(typed.difference(origStart));
        })(),
        description: _formData['description'] as String?,
      ),
      QRType.personalInfo => PersonalInfoData(
        firstName: _formData['firstName'] as String? ?? '',
        lastName: _formData['lastName'] as String? ?? '',
        phone: _formData['phone'] as String? ?? '',
        email: _formData['email2'] as String? ?? '',
        organization: _formData['org'] as String? ?? '',
        jobTitle: _formData['jobTitle'] as String? ?? '',
        website: _formData['website'] as String? ?? '',
        address: _formData['address'] as String? ?? '',
        note: _formData['note'] as String? ?? '',
      ),
    };
  }

  String _dataChipLabel() {
    if (!_isDataFilled) return tr('Add data');
    return switch (widget.qrType) {
      QRType.url => _formData['url'] as String? ?? 'URL',
      QRType.text => () {
        final t = _formData['text'] as String? ?? '';
        return t.length > 24 ? '${t.substring(0, 24)}…' : t;
      }(),
      QRType.wifi => _formData['ssid'] as String? ?? 'WiFi',
      QRType.email => _formData['email'] as String? ?? 'Email',
      QRType.location => '${_formData['lat']}, ${_formData['lng']}',
      QRType.event => _formData['title'] as String? ?? tr('Event'),
      QRType.personalInfo =>
        '${_formData['firstName'] ?? ''} ${_formData['lastName'] ?? ''}'.trim(),
    };
  }

  @override
  void initState() {
    super.initState();
    // Sync non-provider state synchronously to avoid first-frame race conditions
    if (widget.editingQR != null) {
      _formData = _parseEntityData(widget.editingQR!);
      _originalFormData = Map<String, dynamic>.from(_formData);
      _restoreFrameAndSize(widget.editingQR!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(qrCustomizationControllerProvider.notifier);
      if (widget.contentOnly && mounted) _openDataSheet();
      if (widget.editingQR != null) {
        notifier.loadFromEntity(widget.editingQR!);
      } else {
        notifier.applyFullTemplate(widget.template);
        // Save the size the Size tool shows as selected (L), not the model default.
        notifier.updateSize(_kExportSizes[_sizeStep]);
      }
    });
  }

  void _restoreFrameAndSize(QRCodeEntity entity) {
    // Restore frame: null→none, 'box'/'rounded'→frame kind, else→label text
    final ft = entity.customization.frameText;
    if (ft == null) {
      _frameKind = 'none';
    } else if (ft == 'box' || ft == 'rounded') {
      _frameKind = ft;
    } else {
      _frameKind = 'label';
      _labelText = ft;
    }
    // Restore size step to closest saved export size
    _sizeStep = _sizeToStep(entity.customization.size);
  }

  int _sizeToStep(double size) {
    int closest = 0;
    double minDiff = (size - _kExportSizes[0]).abs();
    for (var i = 1; i < _kExportSizes.length; i++) {
      final diff = (size - _kExportSizes[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    return closest;
  }

  Map<String, dynamic> _parseEntityData(QRCodeEntity entity) {
    final data = entity.data;
    final name = entity.name;
    return switch (entity.type) {
      QRType.url => {'name': name, 'url': data},
      QRType.text => {'name': name, 'text': data},
      QRType.wifi => () {
        // Values may contain escaped \; \, \: \\ \" — read them whole and unescape.
        String field(String k) =>
            (RegExp('(?:^WIFI:|(?<!\\\\);)$k:((?:\\\\.|[^;\\\\])*)').firstMatch(data)?.group(1) ?? '')
                .replaceAllMapped(RegExp(r'\\([\\;,:"])'), (m) => m[1]!); // keep lone legacy '\'
        final ssid = field('S');
        final pw = field('P');
        final sec = field('T').isEmpty ? 'WPA' : field('T');
        final hidden = field('H') == 'true';
        return {'name': name, 'ssid': ssid, 'password': pw, 'security': sec, 'hidden': hidden};
      }(),
      QRType.email => () {
        final withoutScheme = data.replaceFirst('mailto:', '');
        final qIdx = withoutScheme.indexOf('?');
        final email =
            qIdx == -1 ? withoutScheme : withoutScheme.substring(0, qIdx);
        final subject =
            RegExp(r'[?&]subject=([^&]*)').firstMatch(data)?.group(1) ?? '';
        final body = RegExp(r'[?&]body=([^&]*)').firstMatch(data)?.group(1) ?? '';
        return {
          'name': name,
          'email': email,
          // Not editable here, but preserved so a data edit doesn't drop it.
          'body': (() {
            try {
              return Uri.decodeComponent(body);
            } catch (_) {
              return body;
            }
          })(),
          // A bare '%' in a legacy subject must not crash the editor on open.
          'subject': (() {
            try {
              return Uri.decodeComponent(subject);
            } catch (_) {
              return subject;
            }
          })(),
        };
      }(),
      QRType.location => () {
        final coords = data.replaceFirst('geo:', '').split('?').first;
        final parts = coords.split(',');
        // geo:lat,lng?q=lat,lng(<place name>) — keep the place name on edit.
        final placeName = RegExp(r'[?&]q=[^(]*\((.*)\)\s*$').firstMatch(data)?.group(1);
        return {
          'name': name,
          'lat': parts.isNotEmpty ? parts[0] : '',
          'lng': parts.length > 1 ? parts[1] : '',
          if (placeName != null && placeName.isNotEmpty)
            'locName': (() {
              try {
                return Uri.decodeComponent(placeName.replaceAll('+', ' '));
              } catch (_) {
                return placeName;
              }
            })(),
        };
      }(),
      QRType.event => () {
        // Anchor keys to line starts so e.g. 'N:' never matches inside 'BEGIN:VCALENDAR'.
        String line(String key) =>
            RegExp('^$key(?:;[^:]*)?:(.+)', multiLine: true).firstMatch(data)?.group(1)?.trim() ?? '';
        // Keep the event date on edit (DTSTART:YYYYMMDDTHHMMSS, local time).
        DateTime? when(String key) {
          // Allow parameters (DTSTART;TZID=…: / ;VALUE=DATE:) and all-day dates.
          final m = RegExp('^$key(?:;[^:]*)?:(\\d{8})(?:T(\\d{4,6})(Z)?)?', multiLine: true)
              .firstMatch(data);
          if (m == null) return null;
          final d = m.group(1)!, t = m.group(2) ?? '0000';
          final isUtc = m.group(3) != null;
          final parts = [int.parse(d.substring(0, 4)), int.parse(d.substring(4, 6)),
              int.parse(d.substring(6, 8)), int.parse(t.substring(0, 2)),
              int.parse(t.substring(2, 4)), t.length >= 6 ? int.parse(t.substring(4, 6)) : 0];
          // 'Z' = UTC: convert to local so it is not shifted when written back.
          return isUtc
              ? DateTime.utc(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]).toLocal()
              : DateTime(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]);
        }
        // DTSTART/DTEND with parameters (TZID, VALUE=DATE) can't be represented by the
        // editor's local date: keep those exact lines and reuse them on save.
        final allDtLines = RegExp(r'^DT(?:START|END)[;:][^\n]*', multiLine: true)
            .allMatches(data)
            .map((m) => m[0]!.trim())
            .toList();
        // If ANY date line has parameters, keep ALL date lines verbatim (start and end).
        // Parameters (TZID, VALUE=DATE) or a UTC 'Z' time: keep them exactly as written.
        final rawDtLines = allDtLines.any((l) =>
                RegExp(r'^DT(?:START|END);').hasMatch(l) || RegExp(r'Z\s*$').hasMatch(l))
            ? allDtLines
            : <String>[];
        final start = rawDtLines.isNotEmpty ? null : when('DTSTART');
        final end = rawDtLines.isNotEmpty ? null : when('DTEND');
        final description = line('DESCRIPTION');
        return {
          'name': name,
          'title': line('SUMMARY'),
          'location': line('LOCATION'),
          if (rawDtLines.isNotEmpty) 'rawDtLines': rawDtLines.join('\n'),
          if (start != null) 'dateTime': start,
          if (start != null)
            'eventDate': '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-'
                '${start.day.toString().padLeft(2, '0')} ${start.hour.toString().padLeft(2, '0')}:'
                '${start.minute.toString().padLeft(2, '0')}',
          if (end != null) 'endDateTime': end,
          if (description.isNotEmpty) 'description': description,
        };
      }(),
      QRType.personalInfo => () {
        // Anchored: unanchored 'N:' matched inside 'BEGIN:VCARD' and saved 'VCARD' as surname.
        String line(String key) =>
            RegExp('^$key(?:;[^:]*)?:(.+)', multiLine: true).firstMatch(data)?.group(1)?.trim() ?? '';
        final nLine = line('N');
        final parts = nLine.split(';');
        return {
          'name': name,
          'firstName': parts.length > 1 && parts[1].isNotEmpty
              ? parts[1]
              : line('FN').split(' ').first,
          // No N line: take the surname from the rest of FN instead of dropping it.
          'lastName': nLine.isNotEmpty
              ? (parts.isNotEmpty ? parts[0] : '')
              : line('FN').split(' ').skip(1).join(' '),
          'phone': line('TEL'),
          'email2': line('EMAIL'),
          'org': line('ORG'),
          // Not editable here, but preserved so a data edit doesn't drop them.
          'jobTitle': line('TITLE'),
          'website': line('URL'),
          'address': line('ADR'), // raw structured value, written back unchanged
          'note': line('NOTE'),
        };
      }(),
    };
  }

  void _markDirty() {
    if (!_dirty || _saved)
      setState(() {
        _dirty = true;
        _saved = false;
      });
  }

  Future<void> _handleSave() async {
    // Also guard the pre-save limit check, so repeated taps can't start parallel saves.
    if (_saving || _checkingLimit) return;
    if (!_isDataFilled) {
      if (widget.qrType == QRType.event &&
          (_formData['title'] as String? ?? '').isNotEmpty) {
        // The only missing piece is the date: say how to write it instead of looping.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'es'
              ? 'Escribe la fecha y hora así: 2026-12-24 18:00'
              : 'Enter the date and time like: 2026-12-24 18:00'),
        ));
      }
      _openDataSheet();
      return;
    }
    // Never save a payload that can't be encoded as a QR (the preview already says so).
    try {
      QrDecorationBuilder.buildQrImage(
        _previewQrData,
        ref.read(qrCustomizationControllerProvider).customization,
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          Localizations.localeOf(context).languageCode == 'es'
              ? 'El contenido es demasiado largo para un QR. Acórtalo e inténtalo de nuevo.'
              : 'This content is too long for a QR code. Shorten it and try again.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _kError,
      ));
      return;
    }

    final auth = ref.read(supabaseAuthProvider);
    if (auth.currentUser == null) return;

    if (widget.contentOnly) {
      final model = _buildDataModel()!;
      Navigator.of(context).pop(QrContentResult(
        type: widget.qrType,
        payload: _finalQrData(model),
        display: model.displayText,
      ));
      return;
    }

    final isEdit = widget.editingQR != null;
    if (!isEdit) {
      // Static (free, counts toward the plan limit) or dynamic (paid, its own checkout).
      final kind = await showSaveKindSheet(
        context,
        qrType: widget.qrType,
        // Static is only "free" while the plan still has room (Pro: always).
        freeQuotaLeft: ref.read(canCreateQRProvider),
        freeLimit: ref.read(qrLimitProvider),
        preselectDynamic: widget.preferDynamic,
      );
      if (kind == null || !mounted) return;
      if (kind == SaveKind.dynamic) {
        await _saveAsDynamic();
        return;
      }
    }
    if (!isEdit) {
      // Make the limit check accurate even right after a cold start. Only an unknown
      // PLAN fails closed; an unknown QR count is left to canCreateQRProvider's rule.
      setState(() => _checkingLimit = true); // show the busy state on Save
      Future<List<dynamic>>? qrsFuture;
      try {
        try {
          // The profile is what decides the plan (subscriptionPlanProvider derives from it).
          // Profile first (it decides the plan), then the plan derived from it, so the
          // limits read below are never a "still loading -> free" placeholder. A missing
          // profile simply means free limits.
          // Always refetch: the limit check must use the current plan and QR count,
          // never a cached value from earlier in the session.
          ref.invalidate(userProfileProvider);
          ref.invalidate(userQRCodesProvider);
          // Start the QR-list fetch now so it runs in parallel with the plan lookup.
          qrsFuture = ref.read(userQRCodesProvider.future);
          // If we return early (plan lookup failed), its error must not go unhandled.
          qrsFuture?.ignore();
          final profile = await ref
              .read(userProfileProvider.future)
              .timeout(const Duration(seconds: 8));
          // The row always exists (sign-up trigger + ensure at sign-in), so null means the
          // fetch failed. Only proceed if this user's last known plan is available;
          // otherwise fail closed (never guess "free" and paywall a Pro user).
          if (profile == null && !hasKnownPlanFor(auth.currentUser?.id)) {
            throw StateError('plan unknown');
          }
          await ref.read(subscriptionPlanProvider.future).timeout(const Duration(seconds: 8));
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'es'
                  ? 'No pudimos verificar tu plan. Revisa tu conexión e inténtalo de nuevo.'
                  : "We couldn't verify your plan. Check your connection and try again.",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: _kError,
          ));
          return;
        }
        try {
          await Future<Object?>.value(qrsFuture ?? ref.read(userQRCodesProvider.future)).timeout(const Duration(seconds: 8));
        } catch (_) {
          // Count unknown: plans with a limit fail closed (unlimited plans pass).
          if (!mounted) return;
          if (ref.read(planLimitsProvider).maxQRCodes >= 0) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'es'
                    ? 'No pudimos verificar tus códigos. Revisa tu conexión e inténtalo de nuevo.'
                    : "We couldn't verify your codes. Check your connection and try again.",
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: _kError,
            ));
            return;
          }
        }
      } finally {
        if (mounted) setState(() => _checkingLimit = false);
      }
      if (!mounted) return;
      final canCreate = ref.read(canCreateQRProvider);
      if (!canCreate) {
        UpgradeBottomSheet.show(context, freeLimit: ref.read(qrLimitProvider));
        return;
      }
    }

    setState(() {
      _saving = true;
      _saved = false;
    });

    try {
      final dataModel = _buildDataModel()!;
      // Sync frame local state → QRCustomization.frameText before reading
      final ctrl = ref.read(qrCustomizationControllerProvider.notifier);
      ctrl.updateFrameText(switch (_frameKind) {
        'none' => null,
        'label' => _labelText.isNotEmpty ? _labelText : 'SCAN ME',
        final k => k, // 'box' or 'rounded'
      });
      final customization =
          ref.read(qrCustomizationControllerProvider).customization;
      final name =
          ((_formData['name'] as String?) ?? '').isNotEmpty
              ? _formData['name'] as String
              : '${widget.qrType.getDisplayName(context)} QR';

      QRCodeEntity result;
      if (isEdit && widget.editingQR!.isDynamic) {
        // Dynamic: only name and design change here; the printed link never does and
        // what it shows is changed from "Cambiar lo que muestra".
        final updated = widget.editingQR!.copyWith(
          name: name,
          data: 'https://scanqraft.app/${widget.editingQR!.slug}',
          customization: customization,
          updatedAt: DateTime.now(),
        );
        result = await ref.read(updateQRCodeUseCaseProvider).execute(updated);
      } else if (isEdit) {
        final updated = widget.editingQR!.copyWith(
          name: name,
          // Style-only edit: keep the original payload byte-for-byte, so fields this
          // editor does not model (vCard title/URL/address/note, email body…) survive.
          data: _dataUnchanged ? widget.editingQR!.data : _finalQrData(dataModel),
          // Original date lines kept (TZID/all-day) -> keep the original label too.
          displayData: _dataUnchanged
              ? widget.editingQR!.displayData
              : ((_formData['rawDtLines'] as String? ?? '').isNotEmpty && _typedEventDate == null)
                  // Original date kept: label from the NEW title/location, no placeholder date.
                  ? [
                      _formData['title'] as String? ?? '',
                      _formData['location'] as String? ?? '',
                    ].where((p) => p.trim().isNotEmpty).join(' — ')
                  : dataModel.displayText,
          customization: customization,
          updatedAt: DateTime.now(),
        );
        result = await ref.read(updateQRCodeUseCaseProvider).execute(updated);
      } else {
        result = await ref
            .read(generateQRUseCaseProvider)
            .execute(
              name: name,
              type: widget.qrType,
              data: dataModel,
              userId: auth.currentUser!.id,
              customization: customization,
            );
      }

      ref.invalidate(userQRCodesProvider);

      if (mounted) {
        setState(() {
          _dirty = false;
          _saving = false;
          _saved = true;
        });
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(Localizations.localeOf(context).languageCode == 'es'
                ? (isEdit ? '¡Código QR actualizado!' : '¡Código QR guardado!')
                : (isEdit ? 'QR code updated!' : 'QR code saved!')),
              ],
            ),
            backgroundColor: _kNeon,
            duration: const Duration(seconds: 2),
          ),
        );
        // Only if this editor is still the visible route (no double pop after Discard).
        if (ModalRoute.of(context)?.isCurrent ?? false) Navigator.of(context).pop(result);
      }
    } catch (e) {
      debugPrint('QR save failed: $e');
      // The server enforces the free limit too (enforce_qr_code_limit trigger): if the
      // client's view was stale, show the upgrade sheet instead of a generic error.
      if (mounted && e.toString().contains('qr_limit_reached')) {
        setState(() => _saving = false);
        ref.invalidate(userQRCodesProvider);
        UpgradeBottomSheet.show(context, freeLimit: ref.read(qrLimitProvider) ?? 5);
        return;
      }
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Never show raw server errors (QRAFT-1).
            content: Text(
              friendlyErrorMessage(e, spanish: Localizations.localeOf(context).languageCode == 'es'),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: _kError,
          ),
        );
      }
    }
  }

  void _handleBack() {
    if (_dirty) {
      setState(() => _showExit = true);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final ctx = _repaintKey.currentContext;
      if (ctx == null) throw Exception('QR preview not ready');
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw Exception('Failed to encode image');
      final name = ((_formData['name'] as String?) ?? 'QR Code').replaceAll(
        RegExp(r'[^a-zA-Z0-9_\-]'),
        '_',
      );
      final file = File('${Directory.systemTemp.path}/qraft_$name.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'QR: $name'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e, spanish: Localizations.localeOf(context).languageCode == 'es')), backgroundColor: _kError),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// New dynamic QR: same name/design/content as a static save, paid in its own checkout.
  Future<void> _saveAsDynamic() async {
    final dataModel = _buildDataModel()!;
    if (dataModel is URLData) {
      final problem = dynamicUrlProblem(dataModel.url);
      if (problem != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(dynamicQrErrorText(context, DynamicQrException(problem))),
          duration: const Duration(seconds: 6),
        ));
        _openDataSheet();
        return;
      }
    }
    final ctrl = ref.read(qrCustomizationControllerProvider.notifier);
    ctrl.updateFrameText(switch (_frameKind) {
      'none' => null,
      'label' => _labelText.isNotEmpty ? _labelText : 'SCAN ME',
      final k => k,
    });
    final customization = ref.read(qrCustomizationControllerProvider).customization;
    final name = ((_formData['name'] as String?) ?? '').isNotEmpty
        ? _formData['name'] as String
        : '${widget.qrType.getDisplayName(context)} QR';
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => DynamicQrCheckoutScreen(
        name: name,
        type: widget.qrType,
        payload: _finalQrData(dataModel),
        display: dataModel.displayText,
        customization: customization,
      ),
    ));
    ref.invalidate(userQRCodesProvider);
    if (created == true && mounted) {
      setState(() {
        _dirty = false;
        _saved = true;
      });
      if (ModalRoute.of(context)?.isCurrent ?? false) Navigator.of(context).pop();
    }
  }

  void _openDataSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _DataSheet(
            qrType: widget.qrType,
            initialData: Map.from(_formData),
            onSave: (data) {
              setState(() => _formData = data);
              _markDirty();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customization =
        ref.watch(qrCustomizationControllerProvider).customization;
    final controller = ref.read(qrCustomizationControllerProvider.notifier);
    final logoAccess = ref.watch(logoInsertionAccessProvider);

    return PopScope(
      // System back / swipe-back must go through the same unsaved-changes prompt.
      canPop: !_dirty || _saved,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildCanvas(customization)),
                if (_openTool != null)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxHeight: 280,
                      minHeight: 140,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    decoration: const BoxDecoration(
                      color: _kSurface,
                      border: Border(top: BorderSide(color: _kLine)),
                    ),
                    child: _buildToolSheetContent(
                      _openTool!,
                      customization,
                      controller,
                      logoAccess.isAllowed,
                    ),
                  ),
                _buildToolRail(customization),
                const SizedBox(height: 8),
              ],
            ),
            if (_showExit) _buildExitOverlay(),
          ],
        ),
      ),
    ));
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final accent = Color(widget.qrType.gradientColors.first);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kSurface,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: accent.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    _iconForType(widget.qrType),
                    size: 12,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.qrType.getDisplayName(context),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (_dirty) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kAmber,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          // Share icon — only active when data is filled
          if (_isDataFilled) ...[
            GestureDetector(
              onTap: _handleShare,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kSurface,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child:
                    _sharing
                        ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _kNeon,
                          ),
                        )
                        : const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Semantics(
            identifier: 'qr_editor_save_button',
            button: true,
            child: GestureDetector(
            onTap: _handleSave,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient:
                    (_dirty && !_saving)
                        ? const LinearGradient(
                          colors: [_kNeon, Color(0xFF00CC6A)],
                        )
                        : null,
                color: (!_dirty || _saving) ? _kSurface : null,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      _saved
                          ? _kNeon
                          : (_dirty && !_saving
                              ? Colors.transparent
                              : Colors.white.withValues(alpha: 0.12)),
                ),
                boxShadow:
                    (_dirty && !_saving)
                        ? [
                          BoxShadow(
                            color: _kNeon.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ]
                        : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_saving || _checkingLimit)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kNeon,
                      ),
                    )
                  else if (_saved)
                    const Icon(Icons.check_rounded, size: 14, color: _kNeon)
                  else if (_dirty)
                    const Icon(
                      Icons.save_rounded,
                      size: 14,
                      color: Color(0xFF0A1810),
                    )
                  else
                    Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  const SizedBox(width: 5),
                  Text(
                    tr(_saving ? 'Saving' : (_saved ? 'Saved' : 'Save')),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          _saving
                              ? Colors.white.withValues(alpha: 0.4)
                              : (_saved
                                  ? _kNeon
                                  : (_dirty
                                      ? const Color(0xFF0A1810)
                                      : Colors.white.withValues(alpha: 0.4))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  // ── Canvas ──────────────────────────────────────────────────────────────────

  Widget _buildCanvas(QRCustomization customization) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

        // Data chip
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _openDataSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        _isDataFilled
                            ? _kNeon.withValues(alpha: 0.5)
                            : _kAmber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Color(
                          widget.qrType.gradientColors.first,
                        ).withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        _iconForType(widget.qrType),
                        size: 12,
                        color: Color(widget.qrType.gradientColors.first),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        _dataChipLabel(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.edit_rounded,
                      size: 12,
                      color: Color(0xFF888888),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // QR card
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap:
                    () => setState(
                      () => _openTool = _openTool == 'color' ? null : 'color',
                    ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _kNeon.withValues(alpha: 0.18),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: _buildQrWithFrame(customization),
                ),
              ).animate().scale(
                begin: const Offset(0.85, 0.85),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    size: 11,
                    color: Color(0xFF555555),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tr('Tap QR to edit color'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrWithFrame(QRCustomization customization) {
    final qr = _LiveQRPreview(
      customization: customization,
      qrData: _previewQrData,
      size: _displaySize,
    );
    // The boundary wraps the framed result, so a shared image includes the frame/label.
    return RepaintBoundary(key: _repaintKey, child: _framed(qr));
  }

  Widget _framed(Widget qr) {
    return switch (_frameKind) {
      'box' => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        padding: const EdgeInsets.all(10),
        child: qr,
      ),
      'rounded' => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(10),
        clipBehavior: Clip.antiAlias,
        child: qr,
      ),
      'label' => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          qr,
          Container(
            width: _displaySize,
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(
              _labelText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      _ => qr,
    };
  }

  // ── Tool Rail ───────────────────────────────────────────────────────────────

  Widget _buildToolRail(QRCustomization customization) {
    final tools = [
      (id: 'color', icon: Icons.palette_outlined, label: 'Color'),
      (id: 'dots', icon: Icons.apps_rounded, label: 'Dots'),
      (id: 'eyes', icon: Icons.remove_red_eye_outlined, label: 'Eyes'),
      (id: 'logo', icon: Icons.image_outlined, label: 'Logo'),
      (id: 'frame', icon: Icons.crop_square_rounded, label: 'Frame'),
      (id: 'size', icon: Icons.photo_size_select_large_outlined, label: 'Size'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: _kLine)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            tools.map((tool) {
              final active = _openTool == tool.id;
              final hasGrad =
                  customization.hasGradient &&
                  customization.gradientStart != null &&
                  customization.gradientEnd != null;

              return GestureDetector(
                onTap:
                    () => setState(() => _openTool = active ? null : tool.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  height: 54,
                  decoration: BoxDecoration(
                    color:
                        active
                            ? _kNeon.withValues(alpha: 0.12)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: active ? Border.all(color: _kNeon) : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tool.icon,
                            size: 20,
                            color: active ? _kNeon : const Color(0xFFAAAAAA),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tr(tool.label),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  active ? FontWeight.w600 : FontWeight.w500,
                              color: active ? _kNeon : const Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                      if (tool.id == 'color')
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient:
                                  hasGrad
                                      ? LinearGradient(
                                        colors: [
                                          Color(customization.gradientStart!),
                                          Color(customization.gradientEnd!),
                                        ],
                                      )
                                      : null,
                              color:
                                  hasGrad
                                      ? null
                                      : Color(customization.foregroundColor),
                              border: Border.all(color: _kBg, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // ── Tool Sheet Content ──────────────────────────────────────────────────────

  Widget _buildToolSheetContent(
    String toolId,
    QRCustomization c,
    QRCustomizationController ctrl,
    bool hasLogoAccess,
  ) {
    return switch (toolId) {
      'color' => _ColorSheet(
        customization: c,
        controller: ctrl,
        onChanged: _markDirty,
      ),
      'dots' => _ShapeSheet(
        label: 'Dot shape',
        options: _kDotOptions,
        activePreset: c.modulePreset,
        onSelect: (p) {
          ctrl.updateModulePreset(p);
          _markDirty();
        },
        previewBuilder: (p) => _DotPreview(preset: p),
      ),
      'eyes' => _ShapeSheet(
        label: 'Eye shape',
        options: _kEyeOptions,
        activePreset: c.eyePreset,
        onSelect: (p) {
          ctrl.updateEyePreset(p);
          _markDirty();
        },
        previewBuilder: (p) => _EyePreview(preset: p),
      ),
      'logo' => _LogoSheet(
        customization: c,
        hasAccess: hasLogoAccess,
        onUpgrade: () => UpgradeBottomSheet.show(context),
        onPickLogo: () async {
          if (!hasLogoAccess) {
            UpgradeBottomSheet.show(context);
            return;
          }
          final file = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            maxWidth: 400,
            maxHeight: 400,
            imageQuality: 85,
          );
          if (file != null && mounted) {
            ctrl.updateLogo(file.path, 40);
            _markDirty();
          }
        },
        onRemoveLogo: () {
          ctrl.removeLogo();
          _markDirty();
        },
      ),
      'frame' => _FrameSheet(
        frameKind: _frameKind,
        labelText: _labelText,
        onFrameChange:
            (k) => setState(() {
              _frameKind = k;
              _markDirty();
            }),
        onLabelChange: (t) {
          setState(() => _labelText = t);
          _markDirty(); // a label edit is an unsaved change too
        },
      ),
      'size' => _SizeSheet(
        step: _sizeStep,
        onChange: (s) {
          setState(() => _sizeStep = s);
          ctrl.updateSize(_QRCanvasEditorScreenState._kExportSizes[s]);
          _markDirty();
        },
      ),
      _ => const SizedBox.shrink(),
    };
  }

  // ── Exit Overlay ────────────────────────────────────────────────────────────

  Widget _buildExitOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAmber.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: _kAmber,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr('Discard changes?'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('Your QR has unsaved edits. Save before leaving?'),
                style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _ActionBtn(
                label: 'Save & exit',
                icon: Icons.save_rounded,
                color: _kNeon,
                onTap: () {
                  setState(() => _showExit = false);
                  _handleSave();
                },
              ),
              const SizedBox(height: 10),
              _ActionBtn(
                label: 'Discard',
                color: _kError,
                onTap: () {
                  setState(() => _showExit = false);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _showExit = false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    tr('Keep editing'),
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  IconData _iconForType(QRType t) => switch (t) {
    QRType.personalInfo => Icons.person_rounded,
    QRType.url => Icons.link_rounded,
    QRType.wifi => Icons.wifi_rounded,
    QRType.text => Icons.text_fields_rounded,
    QRType.email => Icons.email_rounded,
    QRType.location => Icons.location_on_rounded,
    QRType.event => Icons.event_rounded,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Live QR Preview
// ─────────────────────────────────────────────────────────────────────────────

class _LiveQRPreview extends StatefulWidget {
  final QRCustomization customization;
  final String qrData;
  final double size;

  const _LiveQRPreview({
    required this.customization,
    required this.qrData,
    required this.size,
  });

  @override
  State<_LiveQRPreview> createState() => _LiveQRPreviewState();
}

class _LiveQRPreviewState extends State<_LiveQRPreview> {
  // Null when the payload does not fit in a QR (shown as an explicit error, never a stale code).
  QrImage? _qrImage;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(_LiveQRPreview old) {
    super.didUpdateWidget(old);
    if (widget.customization != old.customization ||
        widget.qrData != old.qrData)
      _rebuild();
  }

  void _rebuild() {
    try {
      _qrImage = QrDecorationBuilder.buildQrImage(
        widget.qrData.isEmpty ? 'QRaft' : widget.qrData,
        widget.customization,
      );
      if (mounted) setState(() {});
    } catch (_) {
      _qrImage = null;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: _qrImage == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  Localizations.localeOf(context).languageCode == 'es'
                      ? 'El contenido es demasiado largo para un QR.'
                      : 'This content is too long for a QR code.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ),
            )
          : PrettyQrView(
              qrImage: _qrImage!,
              decoration: QrDecorationBuilder.buildDecoration(widget.customization),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tool sheet widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ColorSheet extends StatelessWidget {
  final QRCustomization customization;
  final QRCustomizationController controller;
  final VoidCallback onChanged;

  const _ColorSheet({
    required this.customization,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasGrad =
        customization.hasGradient &&
        customization.gradientStart != null &&
        customization.gradientEnd != null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr('SOLID'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888888),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                _kSolidColors.map((c) {
                  final active =
                      !hasGrad &&
                      customization.foregroundColor == _colorToArgb(c);
                  return GestureDetector(
                    onTap: () {
                      controller.updateGradient(
                        hasGradient: false,
                        type: GradientType.solid,
                      );
                      controller.updateForegroundColor(c);
                      onChanged();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              active
                                  ? _kNeon
                                  : Colors.white.withValues(alpha: 0.08),
                          width: active ? 2.5 : 1,
                        ),
                        boxShadow:
                            active
                                ? [
                                  BoxShadow(
                                    color: _kNeon.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ]
                                : null,
                      ),
                      child:
                          active
                              ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                              : null,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            tr('GRADIENT'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888888),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _kGradients.length,
              itemBuilder: (_, i) {
                final g = _kGradients[i];
                final active =
                    hasGrad &&
                    customization.gradientStart == _colorToArgb(g.$2) &&
                    customization.gradientEnd == _colorToArgb(g.$3);
                return GestureDetector(
                  onTap: () {
                    controller.updateGradient(
                      hasGradient: true,
                      gradientStart: _colorToArgb(g.$2),
                      gradientEnd: _colorToArgb(g.$3),
                      type: GradientType.linear,
                    );
                    onChanged();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 80,
                    height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [g.$2, g.$3],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? Colors.white : Colors.transparent,
                        width: active ? 2 : 0,
                      ),
                      boxShadow:
                          active
                              ? [
                                BoxShadow(
                                  color: g.$2.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        tr(g.$1),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(blurRadius: 2, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeSheet extends StatelessWidget {
  final String label;
  final List<(String, int)> options;
  final int activePreset;
  final ValueChanged<int> onSelect;
  final Widget Function(int) previewBuilder;

  const _ShapeSheet({
    required this.label,
    required this.options,
    required this.activePreset,
    required this.onSelect,
    required this.previewBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tr(label),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children:
              options.map((o) {
                final active = activePreset == o.$2;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelect(o.$2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            active
                                ? _kNeon.withValues(alpha: 0.1)
                                : const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? _kNeon : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          previewBuilder(o.$2),
                          const SizedBox(height: 8),
                          Text(
                            tr(o.$1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: active ? _kNeon : const Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _DotPreview extends StatelessWidget {
  final int preset;
  const _DotPreview({required this.preset});

  @override
  Widget build(BuildContext context) {
    // Smooth (3) — PrettyQrSmoothSymbol: adjacent modules merge into one blob.
    // Show as a single solid shape (no individual cells) to convey fusion.
    if (preset == 3) {
      return Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
        ),
      );
    }

    // Square/Rounded/Dots — 3×3 grid using Column+Row (not Wrap, which overflows)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (_) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (_) {
            final decoration = switch (preset) {
              0 => const BoxDecoration(color: Colors.white), // Square: sharp
              2 => BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ), // Rounded
              _ => const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ), // Dots (5)
            };
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.all(1),
              decoration: decoration,
            );
          }),
        ),
      ),
    );
  }
}

class _EyePreview extends StatelessWidget {
  final int preset;
  const _EyePreview({required this.preset});

  @override
  Widget build(BuildContext context) {
    return switch (preset) {
      // Square — PrettyQrSquaresSymbol(rounding:0, unified): sharp ring + sharp inner dot
      0 => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Center(
          child: Container(width: 10, height: 10, color: Colors.white),
        ),
      ),
      // Rounded — PrettyQrSquaresSymbol(rounding:0.5, unified): rounded ring + rounded dot
      1 => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
      // Circle — PrettyQrDotsSymbol(unified): concentric circular ring + dot
      2 => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
      // Smooth (3) — Squares(rounding:0.8, unified): very rounded squircle ring + dot
      3 => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
      // Circle (2) — DotsSymbol(unified): concentric circular ring + dot
      _ => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    };
  }
}

class _LogoSheet extends StatelessWidget {
  final QRCustomization customization;
  final bool hasAccess;
  final VoidCallback onUpgrade;
  final Future<void> Function() onPickLogo;
  final VoidCallback onRemoveLogo;

  const _LogoSheet({
    required this.customization,
    required this.hasAccess,
    required this.onUpgrade,
    required this.onPickLogo,
    required this.onRemoveLogo,
  });

  @override
  Widget build(BuildContext context) {
    if (customization.hasLogo && customization.logoPath != null) {
      return Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(customization.logoPath!),
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Color(0xFF888888),
                    size: 28,
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('Logo added'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customization.logoPath!.split('/').last,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemoveLogo,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kError.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.close, size: 16, color: _kError),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPickLogo,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kLine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kNeon.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.upload_rounded, color: _kNeon, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              tr('Upload logo'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'PNG or SVG · max 1 MB',
              style: TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameSheet extends StatefulWidget {
  final String frameKind;
  final String labelText;
  final ValueChanged<String> onFrameChange;
  final ValueChanged<String> onLabelChange;

  const _FrameSheet({
    required this.frameKind,
    required this.labelText,
    required this.onFrameChange,
    required this.onLabelChange,
  });

  @override
  State<_FrameSheet> createState() => _FrameSheetState();
}

class _FrameSheetState extends State<_FrameSheet> {
  late final TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.labelText);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const opts = [
      (id: 'none', label: 'None'),
      (id: 'box', label: 'Box'),
      (id: 'rounded', label: 'Rounded'),
      (id: 'label', label: 'Label'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Frame',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children:
              opts.map((o) {
                final active = widget.frameKind == o.id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onFrameChange(o.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            active
                                ? _kNeon.withValues(alpha: 0.1)
                                : const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? _kNeon : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FramePreviewIcon(kind: o.id),
                          const SizedBox(height: 6),
                          Text(
                            tr(o.label),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: active ? _kNeon : const Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        if (widget.frameKind == 'label') ...[
          const SizedBox(height: 14),
          TextField(
            controller: _labelCtrl,
            onChanged: (v) => widget.onLabelChange(v.toUpperCase()),
            maxLength: 18,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              letterSpacing: 1,
            ),
            decoration: InputDecoration(
              counterText: '',
              labelText: tr('Label text'),
              labelStyle: const TextStyle(color: Color(0xFF888888)),
              filled: true,
              fillColor: const Color(0xFF222222),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kLine),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kLine),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kNeon),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FramePreviewIcon extends StatelessWidget {
  final String kind;
  const _FramePreviewIcon({required this.kind});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: switch (kind) {
        'none' => Container(color: const Color(0xFF555555)),
        'box' => Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            color: const Color(0xFF555555),
          ),
        ),
        'rounded' => Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF555555),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        'label' => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: Container(color: const Color(0xFF555555))),
            Container(height: 8, color: Colors.white),
          ],
        ),
        _ => const SizedBox(),
      },
    );
  }
}

class _SizeSheet extends StatelessWidget {
  final int step;
  final ValueChanged<int> onChange;
  const _SizeSheet({required this.step, required this.onChange});

  static const _labels = ['S', 'M', 'L', 'XL', 'XX'];
  static const _cm = [2.5, 4.2, 6.4, 8.5, 12.7];
  static const _px = [300, 500, 750, 1000, 1500];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tamaño',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              '${_cm[step]}cm · ${_px[step]}px',
              style: const TextStyle(
                fontSize: 13,
                color: _kNeon,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_labels.length, (i) {
            final active = step == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChange(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        active
                            ? _kNeon.withValues(alpha: 0.1)
                            : const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? _kNeon : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _labels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: active ? _kNeon : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_cm[i]}cm',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              active
                                  ? _kNeon.withValues(alpha: 0.8)
                                  : const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        const Text(
          'Medidas equivalentes a impresión 300 DPI',
          style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Sheet (modal bottom sheet for entering QR content)
// ─────────────────────────────────────────────────────────────────────────────

class _DataSheet extends StatefulWidget {
  final QRType qrType;
  final Map<String, dynamic> initialData;
  final void Function(Map<String, dynamic>) onSave;

  const _DataSheet({
    required this.qrType,
    required this.initialData,
    required this.onSave,
  });

  @override
  State<_DataSheet> createState() => _DataSheetState();
}

class _DataSheetState extends State<_DataSheet> {
  late final Map<String, TextEditingController> _ctrls;
  late final Map<String, FocusNode> _focus;

  @override
  void initState() {
    super.initState();
    _ctrls = {};
    _focus = {};
    for (final f in _fields) {
      _ctrls[f.key] = TextEditingController(
        text: widget.initialData[f.key] as String? ?? '',
      );
      _focus[f.key] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    for (final n in _focus.values) {
      n.dispose();
    }
    super.dispose();
  }

  List<
    ({
      String key,
      String label,
      String hint,
      bool required,
      bool multi,
      TextInputType keyboard,
    })
  >
  get _fields => switch (widget.qrType) {
    QRType.url => [
      (
        key: 'name',
        label: 'QR Name',
        hint: 'e.g. My Website',
        required: false,
        multi: false,
        keyboard: TextInputType.text,
      ),
      (
        key: 'url',
        label: 'URL *',
        hint: 'https://example.com',
        required: true,
        multi: false,
        keyboard: TextInputType.url,
      ),
    ],
    QRType.text => [
      (
        key: 'name',
        label: 'QR Name',
        hint: 'e.g. My Note',
        required: false,
        multi: false,
        keyboard: TextInputType.text,
      ),
      (
        key: 'text',
        label: 'Text *',
        hint: 'Enter your message...',
        required: true,
        multi: true,
        keyboard: TextInputType.multiline,
      ),
    ],
    QRType.wifi => [
      (
        key: 'name',
        label: 'QR Name',
        hint: 'e.g. Home WiFi',
        required: false,
        multi: false,
        keyboard: TextInputType.text,
      ),
      (
        key: 'ssid',
        label: 'Network name *',
        hint: 'My WiFi',
        required: true,
        multi: false,
        keyboard: TextInputType.text,
      ),
      (
        key: 'password',
        label: 'Password',
        hint: '••••••••',
        required: false,
        multi: false,
        keyboard: TextInputType.visiblePassword,
      ),
    ],
    QRType.email => [
      (
        key: 'name',
        label: 'QR Name',
        hint: 'e.g. Contact Email',
        required: false,
        multi: false,
        keyboard: TextInputType.text,
      ),
      (
        key: 'email',
        label: 'Email *',
        hint: 'recipient@example.com',
        required: true,
        multi: false,
        keyboard: TextInputType.emailAddress,
      ),
      (
        key: 'subject',
        label: 'Subject',
        hint: 'Hello!',
        required: false,
        multi: false,
        keyboard: TextInputType.text,
      ),
    ],
    QRType.location => [
      (
        key: 'name',
        label: 'QR Name',
        hint: 'e.g. Office',
        required: false,
        multi: false,
        keyboard: TextInputType.text,
      ),
      (
        key: 'locName',
        label: 'Place name',
        hint: 'Coffee Shop',
        required: false,
        multi: false,
        keyboard: TextInputType.text,
      ),
      (
        key: 'lat',
        label: 'Latitude *',
        hint: '40.7128',
        required: true,
        multi: false,
        keyboard: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
      ),
      (
        key: 'lng',
        label: 'Longitude *',
        hint: '-74.0060',
        required: true,
        multi: false,
        keyboard: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
      ),
    ],
    QRType.event => [
      (
        key: 'name',
        label: 'QR Name',
        hint: 'e.g. Team Meeting',
        required: false,
        multi: false,
        keyboard: TextInputType.text,
      ),
      (
        key: 'title',
        label: 'Event title *',
        hint: 'Q3 Review',
        required: true,
        multi: false,
        keyboard: TextInputType.text,
      ),
          (
            key: 'eventDate',
            label: 'Date & time',
            hint: '2026-12-24 18:00',
            required: false, // required for new events via _isDataFilled (not when editing)
            multi: false,
            keyboard: TextInputType.datetime,
          ),
      (
        key: 'location',
        label: 'Location',
        hint: 'Conference Room B',
        required: false,
        multi: false,
        keyboard: TextInputType.text,
      ),
    ],
    QRType.personalInfo => [
      (
        key: 'name',
        label: 'QR Name',
        hint: 'e.g. My vCard',
        required: false,
        multi: false,
        keyboard: TextInputType.text,
      ),
      (
        key: 'firstName',
        label: 'First name *',
        hint: 'Jane',
        required: true,
        multi: false,
        keyboard: TextInputType.name,
      ),
      (
        key: 'lastName',
        label: 'Last name',
        hint: 'Doe',
        required: false,
        multi: false,
        keyboard: TextInputType.name,
      ),
      (
        key: 'phone',
        label: 'Phone',
        hint: '+1 555 0100',
        required: false,
        multi: false,
        keyboard: TextInputType.phone,
      ),
      (
        key: 'email2',
        label: 'Email',
        hint: 'jane@example.com',
        required: false,
        multi: false,
        keyboard: TextInputType.emailAddress,
      ),
      (
        key: 'org',
        label: 'Organization',
        hint: 'Acme Corp',
        required: false,
        multi: false,
        keyboard: TextInputType.text,
      ),
    ],
  };

  bool get _canSave =>
      _fields
          .where((f) => f.required)
          .every((f) => (_ctrls[f.key]?.text ?? '').isNotEmpty) &&
      _urlError == null;

  /// QRAFT-18: a URL with spaces or without a domain is rejected here, not shown as valid.
  String? get _urlError {
    if (widget.qrType != QRType.url) return null;
    final v = _ctrls['url']?.text ?? '';
    if (v.trim().isEmpty || isPlausibleUrl(v)) return null;
    return deviceIsSpanish()
        ? 'Escribe una dirección web válida, sin espacios (ej. tunegocio.com)'
        : 'Enter a valid web address, without spaces (e.g. yourbusiness.com)';
  }

  void _save() {
    final data = Map<String, dynamic>.from(widget.initialData);
    for (final e in _ctrls.entries) {
      data[e.key] = e.value.text;
    }
    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final typeName = switch (widget.qrType) {
      QRType.personalInfo => 'Contact',
      QRType.url => 'URL',
      QRType.wifi => 'WiFi',
      QRType.text => 'Text',
      QRType.email => 'Email',
      QRType.location => 'Location',
      QRType.event => 'Event',
    };

    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF555555),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Text(
                  deviceIsSpanish() ? 'Contenido: ${tr(typeName)}' : '$typeName content',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF888888),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                children: [
                  // Keyboard-first: the action key moves to the next field and the last
                  // one saves, so the sheet can be filled without leaving the keyboard.
                  ..._fields.indexed.map((entry) {
                    final (i, f) = entry;
                    final isLast = i == _fields.length - 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        identifier: 'qr_data_${f.key}_field',
                        textField: true,
                        child: TextField(
                          controller: _ctrls[f.key],
                          focusNode: _focus[f.key],
                          autofocus: i == 0,
                          keyboardType: f.keyboard,
                          textInputAction:
                              f.multi
                                  ? TextInputAction.newline
                                  : (isLast
                                      ? TextInputAction.done
                                      : TextInputAction.next),
                          onSubmitted:
                              f.multi
                                  ? null
                                  : (_) {
                                    if (!isLast) {
                                      _focus[_fields[i + 1].key]
                                          ?.requestFocus();
                                    } else if (_canSave) {
                                      _save();
                                    }
                                  },
                          maxLines: f.multi ? 4 : 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: _trField(f.label),
                            hintText: _trField(f.hint),
                            errorText: f.key == 'url' ? _urlError : null,
                            errorMaxLines: 2,
                            labelStyle: const TextStyle(
                              color: Color(0xFF888888),
                            ),
                            hintStyle: const TextStyle(
                              color: Color(0xFF555555),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF222222),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _kLine),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _kLine),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _kNeon),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Semantics(
              identifier: 'qr_data_done_button',
              button: true,
              enabled: _canSave,
              child: GestureDetector(
                onTap: _canSave ? _save : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  decoration: BoxDecoration(
                    gradient:
                        _canSave
                            ? const LinearGradient(colors: [_kNeon, _kBlue])
                            : null,
                    color: _canSave ? null : const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      tr('Done'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            _canSave
                                ? const Color(0xFF0A1810)
                                : const Color(0xFF666666),
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              tr(label),
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..style = PaintingStyle.fill;
    const spacing = 22.0;
    for (var x = spacing; x < size.width; x += spacing) {
      for (var y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter _) => false;
}

/// Translates a data-sheet label or hint, keeping a trailing " *" and an "e.g. " prefix.
String _trField(String v) {
  if (v.endsWith(' *')) return '${_trField(v.substring(0, v.length - 2))} *';
  if (v.startsWith('e.g. ')) {
    final rest = v.substring(5);
    return deviceIsSpanish() ? 'p. ej. ${tr(rest)}' : v;
  }
  return tr(v);
}

/// A web address worth encoding: no inner whitespace and a host with a dot (or localhost).
@visibleForTesting
bool isPlausibleUrl(String raw) {
  final v = raw.trim();
  if (v.isEmpty || RegExp(r'\s').hasMatch(v)) return false;
  final uri = Uri.tryParse(v.contains('://') ? v : 'https://$v');
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return false;
  final host = uri.host;
  return host == 'localhost' || (host.contains('.') && !host.startsWith('.') && !host.endsWith('.'));
}
