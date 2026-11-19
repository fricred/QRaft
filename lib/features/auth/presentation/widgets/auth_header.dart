import 'package:flutter/material.dart';
import '../../../../shared/widgets/qraft_logo.dart';

/// One-row header shared by every auth screen (design "QRaft: encabezado del registro").
///
/// Back button, logo and title/subtitle sit in a single 72 pt row. While the keyboard is
/// open (the user is filling the form) it animates to a 52 pt row: the logo shrinks
/// 44 → 32, the title 22 → 18 and the subtitle fades out, so the form keeps the screen.
class AuthHeader extends StatefulWidget {
  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// Null hides the back button (e.g. a screen that must not be left, like reset password).
  final VoidCallback? onBack;

  /// Optional action at the end of the row.
  final Widget? trailing;

  @override
  State<AuthHeader> createState() => _AuthHeaderState();
}

/// Listens to the window metrics directly: a Scaffold with resizeToAvoidBottomInset
/// strips the keyboard inset from its body's MediaQuery, so MediaQuery.viewInsetsOf
/// would always read 0 inside the screen.
class _AuthHeaderState extends State<AuthHeader> with WidgetsBindingObserver {
  static const _duration = Duration(milliseconds: 260);
  static const _curve = Cubic(0.2, 0.8, 0.2, 1);

  bool _keyboardOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncKeyboard();
  }

  @override
  void didChangeMetrics() => _syncKeyboard();

  void _syncKeyboard() {
    if (!mounted) return;
    final open = View.of(context).viewInsets.bottom > 0;
    if (open != _keyboardOpen) setState(() => _keyboardOpen = open);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = _keyboardOpen;
    final onBack = widget.onBack;
    final subtitle = widget.subtitle;
    final trailing = widget.trailing;
    final title = widget.title;
    final logo = compact ? 32.0 : 44.0;

    return Semantics(
      container: true,
      header: true,
      child: AnimatedContainer(
        duration: _duration,
        curve: _curve,
        height: compact ? 52 : 72,
        padding: EdgeInsets.only(left: onBack != null ? 8 : 20, right: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: compact ? const Color(0xFF2A2A2A) : Colors.transparent),
          ),
        ),
        child: Row(
          children: [
            if (onBack != null) ...[
              IconButton(
                key: const Key('auth_header_back_button'),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2E2E2E),
                  fixedSize: const Size(44, 44),
                ),
              ),
              const SizedBox(width: 12),
            ],
            AnimatedContainer(
              duration: _duration,
              curve: _curve,
              width: logo,
              height: logo,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(compact ? 9 : 12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF00FF88)],
                ),
              ),
              alignment: Alignment.center,
              child: ExcludeSemantics(
                child: QRaftLogo(size: logo * 0.64, primaryColor: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: _duration,
                    curve: _curve,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 18 : 22,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                    child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (subtitle != null)
                    AnimatedSize(
                      duration: _duration,
                      curve: _curve,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: compact ? 0 : 1,
                        child: compact
                            ? const SizedBox(width: double.infinity)
                            : Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13, height: 1.4),
                              ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
