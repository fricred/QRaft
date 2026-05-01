/// Mirrors google_mobile_ads `ConsentStatus` plus an `unknown` initial state and a
/// `denied` disambiguation state. `ConsentStatus` from google_mobile_ads itself uses
/// `obtained` for both accept and deny — we surface deny separately so AdRequest
/// can pass `nonPersonalizedAds: true` (D-06).
enum ConsentState {
  /// UMP has not yet evaluated. AdMob MUST NOT initialize. (D-04)
  unknown,

  /// GDPR region — user has not yet completed the consent form.
  required,

  /// Non-GDPR region — UMP determined consent is not needed; treat as granted (D-05).
  notRequired,

  /// User completed the form and accepted personalized ads.
  obtained,

  /// User completed the form and denied personalized ads. AdRequest must set npa=1 (D-06).
  denied,
}

extension ConsentStateX on ConsentState {
  /// Whether AdMob has finished its consent gate (form shown or skipped).
  /// `true` for notRequired/obtained/denied; `false` for unknown/required.
  bool get isResolved =>
      this == ConsentState.notRequired ||
      this == ConsentState.obtained ||
      this == ConsentState.denied;

  /// Whether personalized-ads tracking is allowed.
  /// `true` for notRequired/obtained; `false` for unknown/required/denied.
  /// Used to set AdRequest(nonPersonalizedAds: !this.isPersonalizedAllowed) (D-06).
  bool get isPersonalizedAllowed =>
      this == ConsentState.notRequired || this == ConsentState.obtained;
}
