import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/supabase_auth_provider.dart';
import '../widgets/auth_header.dart';

/// Shown after the user opens a password-recovery link (QRAFT-3). The recovery link
/// creates a temporary session; the user must choose a new password before reaching the app.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _confirmFocus = FocusNode();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFFE5E5E5),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  InputDecoration _decoration({
    required String hint,
    String? helper,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8A8A8A)),
      helperText: helper,
      helperMaxLines: 2,
      helperStyle: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 13),
      errorMaxLines: 2,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF242424),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: border(const Color(0xFF3D3D3D)),
      focusedBorder: border(const Color(0xFF00FF88), 2),
      errorBorder: border(const Color(0xFFFF6B6B)),
      focusedErrorBorder: border(const Color(0xFFFF6B6B), 2),
    );
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final auth = ref.read(supabaseAuthProvider);
    final ok = await auth.completePasswordRecovery(_passwordController.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'es'
                ? 'Contraseña actualizada.'
                : 'Password updated.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final error = ref.watch(supabaseAuthProvider).errorMessage;
    return PopScope(
      canPop: false,
      child: Semantics(
        identifier: 'reset_password_screen_root',
        child: Scaffold(
          key: const Key('reset_password_screen_root'),
          backgroundColor: const Color(0xFF1A1A1A),
          body: SafeArea(
            child: Column(
              children: [
                AuthHeader(
                  title: es ? 'Nueva contraseña' : 'New password',
                  subtitle:
                      es
                          ? 'Elige cómo entrarás desde ahora'
                          : 'Choose how you will sign in from now on',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            es
                                ? 'Escribe y confirma la contraseña con la que entrarás de ahora en adelante.'
                                : 'Enter and confirm the password you will use from now on.',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          // Failures (same password, weak, offline, cancel sign-out) are shown
                          // inline: this screen replaces the auth flow, so no snackbar reaches it.
                          if (error != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                key: const Key('reset_password_error'),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A1C1C),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF6B2B2B),
                                  ),
                                ),
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Color(0xFFFFD6D6),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _label(es ? 'Nueva contraseña' : 'New password'),
                          Semantics(
                            identifier: 'reset_password_new_field',
                            textField: true,
                            child: TextFormField(
                              key: const Key('reset_password_new_field'),
                              controller: _passwordController,
                              obscureText: _obscure,
                              autofocus: true,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted:
                                  (_) => _confirmFocus.requestFocus(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: _decoration(
                                hint:
                                    es
                                        ? 'Crea una contraseña'
                                        : 'Create a password',
                                helper:
                                    es
                                        ? '8 o más caracteres, con mayúscula, minúscula y número.'
                                        : '8+ characters with upper, lower case and a number.',
                                suffix: IconButton(
                                  tooltip:
                                      es
                                          ? 'Mostrar u ocultar contraseña'
                                          : 'Show or hide password',
                                  onPressed:
                                      () =>
                                          setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                              validator: (v) {
                                final p = v ?? '';
                                // Same rule as sign-up (8+, upper, lower, digit).
                                if (p.length < 8 ||
                                    !p.contains(RegExp(r'[A-Z]')) ||
                                    !p.contains(RegExp(r'[a-z]')) ||
                                    !p.contains(RegExp(r'[0-9]'))) {
                                  return es
                                      ? '8 o más caracteres, con mayúscula, minúscula y número.'
                                      : '8+ characters with upper, lower case and a number.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          _label(
                            es ? 'Repite la contraseña' : 'Repeat the password',
                          ),
                          Semantics(
                            identifier: 'reset_password_confirm_field',
                            textField: true,
                            child: TextFormField(
                              key: const Key('reset_password_confirm_field'),
                              controller: _confirmController,
                              focusNode: _confirmFocus,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: _decoration(
                                hint:
                                    es ? 'Escríbela otra vez' : 'Type it again',
                              ),
                              validator:
                                  (v) =>
                                      v != _passwordController.text
                                          ? (es
                                              ? 'Las contraseñas no coinciden.'
                                              : 'Passwords do not match.')
                                          : null,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Semantics(
                            identifier: 'reset_password_submit_button',
                            button: true,
                            child: SizedBox(
                              height: 54,
                              child: FilledButton(
                                key: const Key('reset_password_submit_button'),
                                onPressed: _submitting ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF00FF88),
                                  foregroundColor: const Color(0xFF04210F),
                                  disabledBackgroundColor: const Color(
                                    0x8000FF88,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child:
                                    _submitting
                                        ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Color(0xFF04210F),
                                          ),
                                        )
                                        : Text(
                                          es
                                              ? 'Guardar contraseña'
                                              : 'Save password',
                                        ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            identifier: 'reset_password_cancel_button',
                            button: true,
                            child: TextButton(
                              key: const Key('reset_password_cancel_button'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFCFCFCF),
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed:
                                  _submitting
                                      ? null
                                      : () =>
                                          ref
                                              .read(supabaseAuthProvider)
                                              .cancelPasswordRecovery(),
                              child: Text(
                                es
                                    ? 'Cancelar y cerrar sesión'
                                    : 'Cancel and sign out',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
