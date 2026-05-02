/// QR code output profile — controls which constraints are enforced.
enum QrProfile {
  /// Print-safe: dark-on-light required, EC-H forced, logo cap 20%.
  printSafe,

  /// Digital-only: inverted colors allowed, EC level M minimum, logo cap 20%.
  digitalOnly,

  /// Tattoo-safe: dark-on-light required, EC-H forced, logo cap 15%.
  tattooSafe,
}

/// Gradient rendering type for QR module fill.
enum GradientType {
  /// Single flat color (no gradient).
  solid,

  /// Linear gradient from top-left to bottom-right.
  linear,

  /// Radial gradient from center outward.
  radial,
}

/// Per-profile constraint constants.
extension QrProfileConstraints on QrProfile {
  /// Maximum allowed logo coverage scale (linear fraction of QR width).
  double get maxLogoScale => switch (this) {
        QrProfile.printSafe => 0.20,
        QrProfile.digitalOnly => 0.20,
        QrProfile.tattooSafe => 0.15,
      };

  /// Whether the profile requires the foreground to be darker than background.
  bool get requiresDarkOnLight => switch (this) {
        QrProfile.printSafe => true,
        QrProfile.digitalOnly => false,
        QrProfile.tattooSafe => true,
      };

  /// Whether the profile forces error-correction level H (3).
  bool get requiresEcH => switch (this) {
        QrProfile.printSafe => true,
        QrProfile.digitalOnly => false,
        QrProfile.tattooSafe => true,
      };
}
