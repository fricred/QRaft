import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../providers/consent_providers.dart';

/// Thin wrapper that triggers Google's UMP form on first frame. Google's UMP
/// SDK renders the actual consent UI as a system overlay — this Scaffold is
/// the fallback CTA shown if the form fails to load (per D-04).
///
/// Uses Carden Pro design tokens (#1A1A1A scaffold + #2E2E2E card + 24-radius)
/// and PrimaryGlassButton from lib/shared/widgets/glass_button.dart for visual
/// consistency with the auth screens (PATTERNS.md "Glassmorphism UI for
/// Auth/Consent Screens").
///
/// Stable Maestro Keys per .maestro/CONVENTIONS.md selector convention
/// `<feature>_<element>_<role>`:
///   - `ump_consent_screen_root` — Scaffold root
///   - `ump_continue_button` — primary CTA (re-trigger form on failure)
class UmpConsentScreen extends ConsumerStatefulWidget {
  const UmpConsentScreen({super.key});

  @override
  ConsumerState<UmpConsentScreen> createState() => _UmpConsentScreenState();
}

class _UmpConsentScreenState extends ConsumerState<UmpConsentScreen> {
  bool _showingForm = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerForm());
  }

  Future<void> _triggerForm() async {
    setState(() {
      _showingForm = true;
      _errorMessage = null;
    });
    try {
      final service = ref.read(umpServiceProvider);
      await service.loadAndShowConsentFormIfRequired();
      // Invalidate dependent providers so consumers re-evaluate.
      ref.invalidate(consentStateProvider);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _showingForm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('ump_consent_screen_root'),
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Privacy & Ads',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We use ads to keep QRaft free. Choose how your data is used.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryGlassButton(
                    key: const Key('ump_continue_button'),
                    text: 'Continue',
                    onPressed: _showingForm ? null : _triggerForm,
                    isLoading: _showingForm,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
