// Screen 3 of the QR creation flow: tap-to-edit canvas with tool rail.
// TypePicker → TemplatesPicker → [this screen]
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

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
  const Color(0xFF000000), const Color(0xFF1A73E8), const Color(0xFF00FF88),
  const Color(0xFF6366F1), const Color(0xFFEF4444), const Color(0xFFF59E0B),
  const Color(0xFF10B981), const Color(0xFFEC4899), const Color(0xFF8B5CF6),
  const Color(0xFFF97316), const Color(0xFF06B6D4), const Color(0xFF2E2E2E),
];

final _kGradients = <(String, Color, Color)>[
  ('Neon',   const Color(0xFF00FF88), const Color(0xFF1A73E8)),
  ('Sunset', const Color(0xFFFF7E5F), const Color(0xFFFEB47B)),
  ('Ocean',  const Color(0xFF1A73E8), const Color(0xFF0D47A1)),
  ('Forest', const Color(0xFF00B09B), const Color(0xFF096B3B)),
  ('Fire',   const Color(0xFFFF416C), const Color(0xFFFF4B2B)),
  ('Candy',  const Color(0xFF8B5CF6), const Color(0xFFEC4899)),
];

// modulePreset 0=Squares(rounding:0)  2=Squares(rounding:0.8,density:0.9)
//              3=SmoothSymbol(bezier merged) 5=DotsSymbol(circles)
const _kDotOptions = <(String, int)>[
  ('Square', 0), ('Rounded', 2), ('Smooth', 3), ('Dots', 5),
];

// Eye options using what pretty_qr_code actually supports:
// 0=PrettyQrSquaresSymbol(rounding:0)  1=PrettyQrSquaresSymbol(rounding:0.5, unified)
// 2=PrettyQrDotsSymbol(unified)         4=PrettyQrSmoothSymbol(roundFactor:1)
const _kEyeOptions = <(String, int)>[
  ('Square', 0), ('Rounded', 1), ('Circle', 2), ('Smooth', 4),
];

int _colorToArgb(Color c) =>
    ((c.a * 255).round() << 24) |
    ((c.r * 255).round() << 16) |
    ((c.g * 255).round() << 8) |
    (c.b * 255).round();

// ── Screen ─────────────────────────────────────────────────────────────────────

class QRCanvasEditorScreen extends ConsumerStatefulWidget {
  final QRType qrType;
  final QrFullTemplate template;

  const QRCanvasEditorScreen({
    super.key,
    required this.qrType,
    required this.template,
  });

  @override
  ConsumerState<QRCanvasEditorScreen> createState() => _QRCanvasEditorScreenState();
}

class _QRCanvasEditorScreenState extends ConsumerState<QRCanvasEditorScreen> {
  String? _openTool;
  bool _dirty = false;
  bool _saving = false;
  bool _saved = false;
  bool _showExit = false;
  Map<String, dynamic> _formData = {};
  String _frameKind = 'none';
  String _labelText = 'SCAN ME';
  double _sizeSlider = 0.5;

  double get _displaySize => 180 + _sizeSlider * 100;

  bool get _isDataFilled => switch (widget.qrType) {
        QRType.url => (_formData['url'] as String? ?? '').isNotEmpty,
        QRType.text => (_formData['text'] as String? ?? '').isNotEmpty,
        QRType.wifi => (_formData['ssid'] as String? ?? '').isNotEmpty,
        QRType.email => (_formData['email'] as String? ?? '').isNotEmpty,
        QRType.location => (_formData['lat'] as String? ?? '').isNotEmpty &&
            (_formData['lng'] as String? ?? '').isNotEmpty,
        QRType.event => (_formData['title'] as String? ?? '').isNotEmpty,
        QRType.personalInfo => (_formData['firstName'] as String? ?? '').isNotEmpty,
      };

  String get _previewQrData {
    if (!_isDataFilled) {
      return switch (widget.qrType) {
        QRType.url => 'https://qraft.app',
        QRType.text => 'Hello, world!',
        QRType.wifi => 'WIFI:T:WPA;S:QRaft;P:demo1234;H:false;;',
        QRType.email => 'mailto:hello@qraft.app',
        QRType.location => 'geo:40.7128,-74.0060',
        QRType.event => 'BEGIN:VCALENDAR\nBEGIN:VEVENT\nSUMMARY:My Event\nEND:VEVENT\nEND:VCALENDAR',
        QRType.personalInfo => 'BEGIN:VCARD\nVERSION:3.0\nFN:Jane Doe\nEND:VCARD',
      };
    }
    return _buildQrString();
  }

  String _buildQrString() => switch (widget.qrType) {
        QRType.url => () {
            final url = _formData['url'] as String? ?? '';
            return url.startsWith('http') ? url : 'https://$url';
          }(),
        QRType.text => _formData['text'] as String? ?? '',
        QRType.wifi => () {
            final ssid = _formData['ssid'] as String? ?? '';
            final pw = _formData['password'] as String? ?? '';
            final sec = _formData['security'] as String? ?? 'WPA';
            return 'WIFI:T:$sec;S:$ssid;P:$pw;H:false;;';
          }(),
        QRType.email => () {
            final to = _formData['email'] as String? ?? '';
            final subj = _formData['subject'] as String? ?? '';
            return subj.isEmpty ? 'mailto:$to' : 'mailto:$to?subject=${Uri.encodeComponent(subj)}';
          }(),
        QRType.location => () {
            final lat = _formData['lat'] as String? ?? '0';
            final lng = _formData['lng'] as String? ?? '0';
            return 'geo:$lat,$lng';
          }(),
        QRType.event => EventData(
            title: _formData['title'] as String? ?? '',
            location: _formData['location'] as String? ?? '',
            startDateTime: (_formData['dateTime'] as DateTime?) ??
                DateTime.now().add(const Duration(days: 7)),
          ).qrData,
        QRType.personalInfo => PersonalInfoData(
            firstName: _formData['firstName'] as String? ?? '',
            lastName: _formData['lastName'] as String? ?? '',
            phone: _formData['phone'] as String? ?? '',
            email: _formData['email2'] as String? ?? '',
            organization: _formData['org'] as String? ?? '',
          ).qrData,
      };

  QRDataModel? _buildDataModel() {
    if (!_isDataFilled) return null;
    return switch (widget.qrType) {
      QRType.url => URLData(url: _formData['url'] as String? ?? ''),
      QRType.text => TextData(text: _formData['text'] as String? ?? ''),
      QRType.wifi => WiFiData(
          networkName: _formData['ssid'] as String? ?? '',
          password: _formData['password'] as String? ?? '',
          security: _formData['security'] as String? ?? 'WPA',
        ),
      QRType.email => EmailData(
          email: _formData['email'] as String? ?? '',
          subject: _formData['subject'] as String? ?? '',
        ),
      QRType.location => () {
          final lat = double.tryParse(_formData['lat'] as String? ?? '') ?? 0.0;
          final lng = double.tryParse(_formData['lng'] as String? ?? '') ?? 0.0;
          return LocationData(latitude: lat, longitude: lng, name: _formData['locName'] as String?);
        }(),
      QRType.event => EventData(
          title: _formData['title'] as String? ?? '',
          location: _formData['location'] as String? ?? '',
          startDateTime: (_formData['dateTime'] as DateTime?) ??
              DateTime.now().add(const Duration(days: 7)),
        ),
      QRType.personalInfo => PersonalInfoData(
          firstName: _formData['firstName'] as String? ?? '',
          lastName: _formData['lastName'] as String? ?? '',
          phone: _formData['phone'] as String? ?? '',
          email: _formData['email2'] as String? ?? '',
          organization: _formData['org'] as String? ?? '',
        ),
    };
  }

  String _dataChipLabel() {
    if (!_isDataFilled) return 'Add data';
    return switch (widget.qrType) {
      QRType.url => _formData['url'] as String? ?? 'URL',
      QRType.text => () {
          final t = _formData['text'] as String? ?? '';
          return t.length > 24 ? '${t.substring(0, 24)}…' : t;
        }(),
      QRType.wifi => _formData['ssid'] as String? ?? 'WiFi',
      QRType.email => _formData['email'] as String? ?? 'Email',
      QRType.location => '${_formData['lat']}, ${_formData['lng']}',
      QRType.event => _formData['title'] as String? ?? 'Event',
      QRType.personalInfo => '${_formData['firstName'] ?? ''} ${_formData['lastName'] ?? ''}'.trim(),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qrCustomizationControllerProvider.notifier).applyFullTemplate(widget.template);
    });
  }

  void _markDirty() {
    if (!_dirty || _saved) setState(() { _dirty = true; _saved = false; });
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    if (!_isDataFilled) { _openDataSheet(); return; }

    final canCreate = ref.read(canCreateQRProvider);
    if (!canCreate) { UpgradeBottomSheet.show(context); return; }

    final auth = ref.read(supabaseAuthProvider);
    if (auth.currentUser == null) return;

    setState(() { _saving = true; _saved = false; });

    try {
      final dataModel = _buildDataModel()!;
      final customization = ref.read(qrCustomizationControllerProvider).customization;
      final useCase = ref.read(generateQRUseCaseProvider);
      final name = ((_formData['name'] as String?) ?? '').isNotEmpty
          ? _formData['name'] as String
          : '${widget.qrType.getDisplayName(context)} QR';

      await useCase.execute(
        name: name,
        type: widget.qrType,
        data: dataModel,
        userId: auth.currentUser!.id,
        customization: customization,
      );

      ref.invalidate(userQRCodesProvider);

      if (mounted) {
        setState(() { _dirty = false; _saving = false; _saved = true; });
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('QR code saved!'),
          ]),
          backgroundColor: _kNeon,
          duration: Duration(seconds: 2),
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: _kError,
        ));
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

  void _openDataSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DataSheet(
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
    final customization = ref.watch(qrCustomizationControllerProvider).customization;
    final controller = ref.read(qrCustomizationControllerProvider.notifier);
    final logoAccess = ref.watch(logoInsertionAccessProvider);

    return Scaffold(
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
                    constraints: const BoxConstraints(maxHeight: 280, minHeight: 140),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    decoration: const BoxDecoration(
                      color: _kSurface,
                      border: Border(top: BorderSide(color: _kLine)),
                    ),
                    child: _buildToolSheetContent(_openTool!, customization, controller, logoAccess.isAllowed),
                  ),
                _buildToolRail(customization),
                const SizedBox(height: 8),
              ],
            ),
            if (_showExit) _buildExitOverlay(),
          ],
        ),
      ),
    );
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
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: _kSurface,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kSurface, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: accent.withValues(alpha: 0.15),
                  ),
                  child: Icon(_iconForType(widget.qrType), size: 12, color: accent),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.qrType.getDisplayName(context),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                if (_dirty) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: _kAmber),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _handleSave,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: (_dirty && !_saving) ? const LinearGradient(colors: [_kNeon, Color(0xFF00CC6A)]) : null,
                color: (!_dirty || _saving) ? _kSurface : null,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _saved ? _kNeon : (_dirty && !_saving ? Colors.transparent : Colors.white.withValues(alpha: 0.12)),
                ),
                boxShadow: (_dirty && !_saving) ? [BoxShadow(color: _kNeon.withValues(alpha: 0.3), blurRadius: 8)] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_saving)
                    const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kNeon),
                    )
                  else if (_saved)
                    const Icon(Icons.check_rounded, size: 14, color: _kNeon)
                  else if (_dirty)
                    const Icon(Icons.save_rounded, size: 14, color: Color(0xFF0A1810))
                  else
                    Icon(Icons.check_rounded, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                  const SizedBox(width: 5),
                  Text(
                    _saving ? 'Saving' : (_saved ? 'Saved' : 'Save'),
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: _saving ? Colors.white.withValues(alpha: 0.4)
                          : (_saved ? _kNeon
                          : (_dirty ? const Color(0xFF0A1810) : Colors.white.withValues(alpha: 0.4))),
                    ),
                  ),
                ],
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
          top: 12, left: 0, right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _openDataSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _kSurface, borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isDataFilled
                        ? _kNeon.withValues(alpha: 0.5)
                        : _kAmber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Color(widget.qrType.gradientColors.first).withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        _iconForType(widget.qrType), size: 12,
                        color: Color(widget.qrType.gradientColors.first),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        _dataChipLabel(),
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF888888)),
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
                onTap: () => setState(() => _openTool = _openTool == 'color' ? null : 'color'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: _kNeon.withValues(alpha: 0.18), blurRadius: 20, spreadRadius: 2),
                      BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _buildQrWithFrame(customization),
                ),
              ).animate().scale(begin: const Offset(0.85, 0.85), duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app_rounded, size: 11, color: Color(0xFF555555)),
                  const SizedBox(width: 4),
                  const Text('Tap QR to edit color', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
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
    return switch (_frameKind) {
      'box' => Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2),
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
      (id: 'color',  icon: Icons.palette_outlined,                     label: 'Color'),
      (id: 'dots',   icon: Icons.apps_rounded,                         label: 'Dots'),
      (id: 'eyes',   icon: Icons.remove_red_eye_outlined,              label: 'Eyes'),
      (id: 'logo',   icon: Icons.image_outlined,                       label: 'Logo'),
      (id: 'frame',  icon: Icons.crop_square_rounded,                  label: 'Frame'),
      (id: 'size',   icon: Icons.photo_size_select_large_outlined,     label: 'Size'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: _kLine)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: tools.map((tool) {
          final active = _openTool == tool.id;
          final hasGrad = customization.hasGradient &&
              customization.gradientStart != null &&
              customization.gradientEnd != null;

          return GestureDetector(
            onTap: () => setState(() => _openTool = active ? null : tool.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52, height: 54,
              decoration: BoxDecoration(
                color: active ? _kNeon.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: active ? Border.all(color: _kNeon) : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tool.icon, size: 20, color: active ? _kNeon : const Color(0xFFAAAAAA)),
                      const SizedBox(height: 3),
                      Text(
                        tool.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                          color: active ? _kNeon : const Color(0xFFAAAAAA),
                        ),
                      ),
                    ],
                  ),
                  if (tool.id == 'color')
                    Positioned(
                      top: 4, right: 4,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: hasGrad
                              ? LinearGradient(colors: [
                                  Color(customization.gradientStart!),
                                  Color(customization.gradientEnd!),
                                ])
                              : null,
                          color: hasGrad ? null : Color(customization.foregroundColor),
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
      String toolId, QRCustomization c, QRCustomizationController ctrl, bool hasLogoAccess) {
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
          onSelect: (p) { ctrl.updateModulePreset(p); _markDirty(); },
          previewBuilder: (p) => _DotPreview(preset: p),
        ),
      'eyes' => _ShapeSheet(
          label: 'Eye shape',
          options: _kEyeOptions,
          activePreset: c.eyePreset,
          onSelect: (p) { ctrl.updateEyePreset(p); _markDirty(); },
          previewBuilder: (p) => _EyePreview(preset: p),
        ),
      'logo' => _LogoSheet(
          customization: c,
          hasAccess: hasLogoAccess,
          onUpgrade: () => UpgradeBottomSheet.show(context),
          onPickLogo: () async {
            if (!hasLogoAccess) { UpgradeBottomSheet.show(context); return; }
            final file = await ImagePicker().pickImage(
              source: ImageSource.gallery, maxWidth: 400, maxHeight: 400, imageQuality: 85,
            );
            if (file != null && mounted) { ctrl.updateLogo(file.path, 40); _markDirty(); }
          },
          onRemoveLogo: () { ctrl.removeLogo(); _markDirty(); },
        ),
      'frame' => _FrameSheet(
          frameKind: _frameKind,
          labelText: _labelText,
          onFrameChange: (k) => setState(() { _frameKind = k; _markDirty(); }),
          onLabelChange: (t) => setState(() => _labelText = t),
        ),
      'size' => _SizeSheet(
          value: _sizeSlider,
          onChange: (v) {
            setState(() => _sizeSlider = v);
            ctrl.updateSize(200 + v * 200);
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
          width: 300, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _kAmber.withValues(alpha: 0.12)),
                child: const Icon(Icons.warning_rounded, color: _kAmber, size: 24),
              ),
              const SizedBox(height: 16),
              const Text('Discard changes?', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Your QR has unsaved edits. Save before leaving?',
                style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _ActionBtn(label: 'Save & exit', icon: Icons.save_rounded, color: _kNeon,
                  onTap: () { setState(() => _showExit = false); _handleSave(); }),
              const SizedBox(height: 10),
              _ActionBtn(label: 'Discard', color: _kError,
                  onTap: () { setState(() => _showExit = false); Navigator.of(context).pop(); }),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _showExit = false),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Keep editing', style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
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

  const _LiveQRPreview({required this.customization, required this.qrData, required this.size});

  @override
  State<_LiveQRPreview> createState() => _LiveQRPreviewState();
}

class _LiveQRPreviewState extends State<_LiveQRPreview> {
  late QrImage _qrImage;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(_LiveQRPreview old) {
    super.didUpdateWidget(old);
    if (widget.customization != old.customization || widget.qrData != old.qrData) _rebuild();
  }

  void _rebuild() {
    try {
      _qrImage = QrDecorationBuilder.buildQrImage(
        widget.qrData.isEmpty ? 'QRaft' : widget.qrData,
        widget.customization,
      );
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: PrettyQrView(
        qrImage: _qrImage,
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

  const _ColorSheet({required this.customization, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hasGrad = customization.hasGradient &&
        customization.gradientStart != null &&
        customization.gradientEnd != null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('SOLID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF888888), letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _kSolidColors.map((c) {
              final active = !hasGrad && customization.foregroundColor == _colorToArgb(c);
              return GestureDetector(
                onTap: () {
                  controller.updateGradient(hasGradient: false, type: GradientType.solid);
                  controller.updateForegroundColor(c);
                  onChanged();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? _kNeon : Colors.white.withValues(alpha: 0.08),
                      width: active ? 2.5 : 1,
                    ),
                    boxShadow: active ? [BoxShadow(color: _kNeon.withValues(alpha: 0.3), blurRadius: 8)] : null,
                  ),
                  child: active ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text('GRADIENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF888888), letterSpacing: 1)),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _kGradients.length,
              itemBuilder: (_, i) {
                final g = _kGradients[i];
                final active = hasGrad &&
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
                    width: 80, height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [g.$2, g.$3]),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: active ? Colors.white : Colors.transparent, width: active ? 2 : 0),
                      boxShadow: active ? [BoxShadow(color: g.$2.withValues(alpha: 0.5), blurRadius: 8)] : null,
                    ),
                    child: Center(
                      child: Text(
                        g.$1,
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600,
                            shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
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
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          children: options.map((o) {
            final active = activePreset == o.$2;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(o.$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? _kNeon.withValues(alpha: 0.1) : const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? _kNeon : Colors.transparent, width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      previewBuilder(o.$2),
                      const SizedBox(height: 8),
                      Text(o.$1,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: active ? _kNeon : const Color(0xFFAAAAAA),
                          )),
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
        width: 27, height: 27,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
        ),
      );
    }

    // Square/Rounded/Dots — 3×3 grid using Column+Row (not Wrap, which overflows)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (_) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (_) {
          final decoration = switch (preset) {
            0 => const BoxDecoration(color: Colors.white),                        // Square: sharp
            2 => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)), // Rounded
            _ => const BoxDecoration(color: Colors.white, shape: BoxShape.circle), // Dots (5)
          };
          return Container(
            width: 7, height: 7,
            margin: const EdgeInsets.all(1),
            decoration: decoration,
          );
        }),
      )),
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
          width: 28, height: 28,
          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3)),
          child: Center(child: Container(width: 10, height: 10, color: Colors.white)),
        ),
      // Rounded — PrettyQrSquaresSymbol(rounding:0.5, unified): rounded ring + rounded dot
      1 => Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      // Circle — PrettyQrDotsSymbol(unified): concentric circular ring + dot
      2 => Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Center(
            child: Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            ),
          ),
        ),
      // Smooth — PrettyQrSmoothSymbol: neighbor-aware bezier blobs, no hard ring
      _ => CustomPaint(
          size: const Size(28, 28),
          painter: _SmoothEyePainter(),
        ),
    };
  }
}

class _SmoothEyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    // Outer blob — rounded square that merges into smooth bezier curves
    final outer = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ));
    // Inner cutout — slightly rounded square, clipped from outer
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
        const Radius.circular(4),
      ));
    // Ring shape
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      paint,
    );
    // Center dot
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(9, 9, size.width - 18, size.height - 18),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SmoothEyePainter _) => false;
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
              width: 52, height: 52, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Color(0xFF888888), size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Logo added', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  customization.logoPath!.split('/').last,
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemoveLogo,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(shape: BoxShape.circle, color: _kError.withValues(alpha: 0.15)),
              child: const Icon(Icons.close, size: 16, color: _kError),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPickLogo,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF222222), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kLine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _kNeon.withValues(alpha: 0.1)),
              child: const Icon(Icons.upload_rounded, color: _kNeon, size: 22),
            ),
            const SizedBox(height: 8),
            const Text('Upload logo', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('PNG or SVG · max 1 MB', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
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
      (id: 'none', label: 'None'), (id: 'box', label: 'Box'),
      (id: 'rounded', label: 'Rounded'), (id: 'label', label: 'Label'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Frame', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          children: opts.map((o) {
            final active = widget.frameKind == o.id;
            return Expanded(
              child: GestureDetector(
                onTap: () => widget.onFrameChange(o.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: active ? _kNeon.withValues(alpha: 0.1) : const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? _kNeon : Colors.transparent, width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FramePreviewIcon(kind: o.id),
                      const SizedBox(height: 6),
                      Text(o.label,
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500,
                            color: active ? _kNeon : const Color(0xFFAAAAAA),
                          )),
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
            style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1),
            decoration: InputDecoration(
              counterText: '',
              labelText: 'Label text',
              labelStyle: const TextStyle(color: Color(0xFF888888)),
              filled: true, fillColor: const Color(0xFF222222),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kLine)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kLine)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kNeon)),
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
      width: 34, height: 34,
      child: switch (kind) {
        'none' => Container(color: const Color(0xFF555555)),
        'box' => Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
            child: Container(margin: const EdgeInsets.all(3), color: const Color(0xFF555555)),
          ),
        'rounded' => Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(8)),
            child: Container(margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: const Color(0xFF555555), borderRadius: BorderRadius.circular(4))),
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
  final double value;
  final ValueChanged<double> onChange;
  const _SizeSheet({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final label = value < 0.33 ? 'Small' : value < 0.66 ? 'Medium' : value < 0.88 ? 'Large' : 'X-Large';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Size', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 13, color: _kNeon, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('S', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                  activeTrackColor: _kNeon,
                  inactiveTrackColor: const Color(0xFF444444),
                  thumbColor: Colors.white,
                  overlayColor: _kNeon.withValues(alpha: 0.2),
                ),
                child: Slider(value: value, min: 0.0, max: 1.0, onChanged: onChange),
              ),
            ),
            const Text('XL', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
          ],
        ),
        const Text('Auto-fits canvas by default', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
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

  const _DataSheet({required this.qrType, required this.initialData, required this.onSave});

  @override
  State<_DataSheet> createState() => _DataSheetState();
}

class _DataSheetState extends State<_DataSheet> {
  late final Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = {};
    for (final f in _fields) {
      _ctrls[f.key] = TextEditingController(text: widget.initialData[f.key] as String? ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<({String key, String label, String hint, bool required, bool multi, TextInputType keyboard})> get _fields =>
      switch (widget.qrType) {
        QRType.url => [
            (key: 'name',    label: 'QR Name',  hint: 'e.g. My Website',      required: false, multi: false, keyboard: TextInputType.text),
            (key: 'url',     label: 'URL *',     hint: 'https://example.com',  required: true,  multi: false, keyboard: TextInputType.url),
          ],
        QRType.text => [
            (key: 'name',    label: 'QR Name',  hint: 'e.g. My Note',         required: false, multi: false, keyboard: TextInputType.text),
            (key: 'text',    label: 'Text *',   hint: 'Enter your message...', required: true,  multi: true,  keyboard: TextInputType.multiline),
          ],
        QRType.wifi => [
            (key: 'name',     label: 'QR Name',       hint: 'e.g. Home WiFi',  required: false, multi: false, keyboard: TextInputType.text),
            (key: 'ssid',     label: 'Network name *', hint: 'My WiFi',         required: true,  multi: false, keyboard: TextInputType.text),
            (key: 'password', label: 'Password',       hint: '••••••••',        required: false, multi: false, keyboard: TextInputType.visiblePassword),
          ],
        QRType.email => [
            (key: 'name',    label: 'QR Name', hint: 'e.g. Contact Email',       required: false, multi: false, keyboard: TextInputType.text),
            (key: 'email',   label: 'Email *', hint: 'recipient@example.com',    required: true,  multi: false, keyboard: TextInputType.emailAddress),
            (key: 'subject', label: 'Subject', hint: 'Hello!',                   required: false, multi: false, keyboard: TextInputType.text),
          ],
        QRType.location => [
            (key: 'name',    label: 'QR Name',    hint: 'e.g. Office',  required: false, multi: false, keyboard: TextInputType.text),
            (key: 'locName', label: 'Place name', hint: 'Coffee Shop',  required: false, multi: false, keyboard: TextInputType.text),
            (key: 'lat',     label: 'Latitude *', hint: '40.7128',      required: true,  multi: false, keyboard: const TextInputType.numberWithOptions(signed: true, decimal: true)),
            (key: 'lng',     label: 'Longitude *',hint: '-74.0060',     required: true,  multi: false, keyboard: const TextInputType.numberWithOptions(signed: true, decimal: true)),
          ],
        QRType.event => [
            (key: 'name',     label: 'QR Name',       hint: 'e.g. Team Meeting',    required: false, multi: false, keyboard: TextInputType.text),
            (key: 'title',    label: 'Event title *',  hint: 'Q3 Review',            required: true,  multi: false, keyboard: TextInputType.text),
            (key: 'location', label: 'Location',       hint: 'Conference Room B',    required: false, multi: false, keyboard: TextInputType.text),
          ],
        QRType.personalInfo => [
            (key: 'name',      label: 'QR Name',       hint: 'e.g. My vCard',          required: false, multi: false, keyboard: TextInputType.text),
            (key: 'firstName', label: 'First name *',  hint: 'Jane',                   required: true,  multi: false, keyboard: TextInputType.name),
            (key: 'lastName',  label: 'Last name',     hint: 'Doe',                    required: false, multi: false, keyboard: TextInputType.name),
            (key: 'phone',     label: 'Phone',         hint: '+1 555 0100',            required: false, multi: false, keyboard: TextInputType.phone),
            (key: 'email2',    label: 'Email',         hint: 'jane@example.com',       required: false, multi: false, keyboard: TextInputType.emailAddress),
            (key: 'org',       label: 'Organization',  hint: 'Acme Corp',              required: false, multi: false, keyboard: TextInputType.text),
          ],
      };

  bool get _canSave => _fields.where((f) => f.required).every((f) => (_ctrls[f.key]?.text ?? '').isNotEmpty);

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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 14),
            decoration: BoxDecoration(color: const Color(0xFF555555), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Text('$typeName content', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Color(0xFF888888), size: 22),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                children: [
                  ..._fields.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _ctrls[f.key],
                      keyboardType: f.keyboard,
                      maxLines: f.multi ? 4 : 1,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: f.label,
                        hintText: f.hint,
                        labelStyle: const TextStyle(color: Color(0xFF888888)),
                        hintStyle: const TextStyle(color: Color(0xFF555555)),
                        filled: true, fillColor: const Color(0xFF222222),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kLine)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kLine)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kNeon)),
                      ),
                    ),
                  )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: GestureDetector(
              onTap: _canSave ? _save : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  gradient: _canSave ? const LinearGradient(colors: [_kNeon, _kBlue]) : null,
                  color: _canSave ? null : const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: _canSave ? const Color(0xFF0A1810) : const Color(0xFF666666),
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

  const _ActionBtn({required this.label, required this.color, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 6)],
            Text(label, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
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
