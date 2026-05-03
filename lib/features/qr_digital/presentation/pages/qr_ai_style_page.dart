import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../../features/redirect/presentation/providers/redirect_providers.dart';
import '../controllers/qr_digital_controller.dart';

/// AI Style QR screen.
///
/// Allows users to enter a text prompt and generate an AI-stylized version of
/// their QR code via the Replicate ControlNet model (proxied through the
/// Supabase Edge Function `ai-stylize`).
///
/// Only available for [QRCustomization.profile] == 1 (digitalOnly). An amber
/// banner is shown for other profiles and all interactive elements are disabled
/// (T-06-11 double-layer enforcement).
///
/// Flow:
///   1. User enters a text prompt (max 200 chars).
///   2. User taps "Generate AI Style" button.
///   3. [QrDigitalController.generateAiStyle] is called with the prompt,
///      [SupabaseClient], and the base QR storage URL.
///   4. A [LinearProgressIndicator] + "Generating… (~26s)" label shows during
///      the request.
///   5. On success: result image previewed with a scannability chip.
///   6. Save button enabled only when [QrAiStyleResult.scanOk] == true.
class QrAiStylePage extends ConsumerStatefulWidget {
  /// The QR code entity to stylize.
  final QRCodeEntity entity;

  /// Public Supabase Storage URL of the base QR PNG.
  ///
  /// The caller (typically a parent route) must supply this URL so the page
  /// does not need to perform a storage upload itself. The URL is forwarded
  /// to the Edge Function as `qr_url`.
  final String qrStorageUrl;

  const QrAiStylePage({
    super.key,
    required this.entity,
    required this.qrStorageUrl,
  });

  @override
  ConsumerState<QrAiStylePage> createState() => _QrAiStylePageState();
}

// ---------------------------------------------------------------------------
// Style presets (8 options as per plan spec)
// ---------------------------------------------------------------------------

class _StylePreset {
  final String label;
  final String promptSuffix;

  const _StylePreset(this.label, this.promptSuffix);
}

const _stylePresets = [
  _StylePreset('Woodblock', 'woodblock print style, bold lines, traditional'),
  _StylePreset('Art Nouveau', 'art nouveau style, ornate floral patterns'),
  _StylePreset('Cyberpunk', 'cyberpunk neon city night style, glowing colors'),
  _StylePreset('Watercolor', 'watercolor painting style, soft washes of color'),
  _StylePreset('Pencil Sketch', 'pencil sketch style, hand-drawn crosshatching'),
  _StylePreset('Oil Painting', 'oil painting style, thick impasto texture'),
  _StylePreset('Geometric', 'geometric abstract style, sharp shapes and angles'),
  _StylePreset('Minimal', 'minimal clean style, simple shapes, monochrome'),
];

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _QrAiStylePageState extends ConsumerState<QrAiStylePage> {
  final _promptController = TextEditingController();
  int _selectedPresetIndex = -1; // -1 = no preset selected
  bool _snackShown = false;
  String? _lastErrorShown;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  bool get _isDigitalOnly => widget.entity.customization.profile == 1;

  void _selectPreset(int index) {
    setState(() {
      _selectedPresetIndex = index;
      _promptController.text = _stylePresets[index].promptSuffix;
    });
  }

  Future<void> _onGenerate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final client = ref.read(supabaseClientProvider);
    await ref
        .read(qrDigitalControllerProvider(widget.entity).notifier)
        .generateAiStyle(prompt, client, widget.qrStorageUrl);
  }

  Future<void> _onSave(QrDigitalState state) async {
    final result = state.aiStyleResult;
    if (result == null || !result.scanOk) return;

    final xFile = XFile.fromData(
      result.imageBytes,
      name: 'ai_qr.png',
      mimeType: 'image/png',
    );
    await Share.shareXFiles([xFile]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrDigitalControllerProvider(widget.entity));

    // Show SnackBar for new errors (once per error value).
    ref.listen<QrDigitalState>(
      qrDigitalControllerProvider(widget.entity),
      (prev, next) {
        if (next.aiStyleError != null &&
            next.aiStyleError != _lastErrorShown) {
          _snackShown = false;
          _lastErrorShown = next.aiStyleError;
        }
        if (next.aiStyleError != null && !_snackShown) {
          _snackShown = true;
          final msg = next.aiStyleError == 'monthly_limit_reached'
              ? "You've used all 5 free AI styles this month. "
                  "Upgrade to Premium for unlimited styles."
              : 'AI style error: ${next.aiStyleError}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.red[800],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'AI Style QR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------------------------
              // Profile guard banner
              // ------------------------------------------------------------------
              if (!_isDigitalOnly)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[900]!.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber[600]!.withValues(alpha: 0.8),
                      ),
                    ),
                    child: const Text(
                      'AI Style requires Digital-Only profile. '
                      'Change profile in the QR editor.',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // ------------------------------------------------------------------
              // Usage counter
              // ------------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '5 free AI styles / month',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

              // ------------------------------------------------------------------
              // Prompt text field
              // ------------------------------------------------------------------
              Semantics(
                identifier: 'ai_style_prompt_field',
                label: 'AI style prompt input',
                child: TextField(
                  controller: _promptController,
                  enabled: _isDigitalOnly && !state.isStylizing,
                  maxLength: 200,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFF00FF88),
                  decoration: InputDecoration(
                    hintText:
                        "Describe the style (e.g., 'cyberpunk city at night')",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    counterStyle: TextStyle(color: Colors.grey[600]),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[700]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF00FF88),
                        width: 1.5,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[800]!, width: 1),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2E2E2E),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------------------------
              // Style preset chips
              // ------------------------------------------------------------------
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_stylePresets.length, (i) {
                  final preset = _stylePresets[i];
                  final isSelected = _selectedPresetIndex == i;
                  return GestureDetector(
                    onTap: _isDigitalOnly && !state.isStylizing
                        ? () => _selectPreset(i)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00FF88).withValues(alpha: 0.15)
                            : const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00FF88)
                              : Colors.grey[700]!,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        preset.label,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF00FF88)
                              : Colors.grey[300],
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------------------------
              // Generate button
              // ------------------------------------------------------------------
              Semantics(
                identifier: 'ai_style_generate_button',
                label: 'Generate AI Style',
                button: true,
                enabled: _isDigitalOnly && !state.isStylizing,
                child: GestureDetector(
                  onTap: _isDigitalOnly && !state.isStylizing
                      ? _onGenerate
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: _isDigitalOnly && !state.isStylizing
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF00FF88),
                                Color(0xFF00CC6A),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey[800]!.withValues(alpha: 0.4),
                                Colors.grey[900]!.withValues(alpha: 0.5),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: state.isStylizing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Generate AI Style',
                            style: TextStyle(
                              color: _isDigitalOnly
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),

              // ------------------------------------------------------------------
              // Generating progress indicator
              // ------------------------------------------------------------------
              if (state.isStylizing) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
                  backgroundColor: Color(0xFF2E2E2E),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generating… (~26s)',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // ------------------------------------------------------------------
              // Result preview
              // ------------------------------------------------------------------
              if (state.aiStyleResult != null) ...[
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 312,
                    height: 312,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        state.aiStyleResult!.imageBytes,
                        width: 280,
                        height: 280,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Scannability indicator
                Center(
                  child: state.aiStyleResult!.scanOk
                      ? _ScannabilityChip(
                          label: 'Scannable',
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF00FF88),
                          isSuccess: true,
                        )
                      : _ScannabilityChip(
                          label: 'Not scannable — try a different prompt',
                          icon: Icons.error_outline,
                          color: Colors.red[400]!,
                          isSuccess: false,
                        ),
                ),

                const SizedBox(height: 20),

                // Save / Share button
                Semantics(
                  identifier: 'ai_style_save_button',
                  label: 'Save AI style QR',
                  button: true,
                  enabled: state.aiStyleResult!.scanOk,
                  child: GestureDetector(
                    onTap: state.aiStyleResult!.scanOk
                        ? () => _onSave(state)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: state.aiStyleResult!.scanOk
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF1A73E8),
                                  Color(0xFF0D5BBF),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey[800]!.withValues(alpha: 0.4),
                                  Colors.grey[900]!.withValues(alpha: 0.5),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Save / Share',
                        style: TextStyle(
                          color: state.aiStyleResult!.scanOk
                              ? Colors.white
                              : Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scannability chip widget
// ---------------------------------------------------------------------------

class _ScannabilityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSuccess;

  const _ScannabilityChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
