import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// QRaft logo widget with configurable colors and size
/// Supports different color themes for various app states
class QRaftLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;
  final LogoTheme theme;

  const QRaftLogo({
    super.key,
    this.size = 80,
    this.primaryColor,
    this.secondaryColor,
    this.theme = LogoTheme.carden,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getThemeColors();
    
    return SizedBox(
      width: size,
      height: size,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          colors.primary,
          BlendMode.srcIn,
        ),
        child: SvgPicture.asset(
          'assets/images/qraft_logo.svg',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  _LogoColors _getThemeColors() {
    switch (theme) {
      case LogoTheme.carden:
        return _LogoColors(
          primary: primaryColor ?? const Color(0xFF00FF88), // Carden neon green
          secondary: secondaryColor ?? const Color(0xFF1A73E8), // Carden blue
        );
      case LogoTheme.dark:
        return _LogoColors(
          primary: primaryColor ?? const Color(0xFF2E2E2E), // Dark gray
          secondary: secondaryColor ?? Colors.white,
        );
      case LogoTheme.light:
        return _LogoColors(
          primary: primaryColor ?? const Color(0xFF1A73E8), // Blue
          secondary: secondaryColor ?? const Color(0xFF2E2E2E), // Dark gray
        );
      case LogoTheme.monochrome:
        return _LogoColors(
          primary: primaryColor ?? Colors.white,
          secondary: secondaryColor ?? Colors.grey,
        );
    }
  }
}

enum LogoTheme {
  carden,    // Neon green/blue theme
  dark,      // Dark theme
  light,     // Light theme  
  monochrome // Single color theme
}

class _LogoColors {
  final Color primary;
  final Color secondary;

  _LogoColors({
    required this.primary,
    required this.secondary,
  });
}