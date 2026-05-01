---
phase: 01-foundation-hardening
plan: 05
type: execute
wave: 4
depends_on:
  - 03
  - 04
files_modified:
  - lib/features/consent/data/services/ump_service.dart
  - lib/features/consent/domain/entities/consent_state.dart
  - lib/features/consent/presentation/providers/consent_providers.dart
  - lib/features/consent/presentation/screens/ump_consent_screen.dart
  - lib/features/consent/presentation/widgets/ump_gate.dart
  - lib/features/ads/data/services/admob_service.dart
  - lib/features/ads/presentation/widgets/banner_ad_widget.dart
  - lib/features/ads/presentation/widgets/rewarded_ad_button.dart
  - lib/features/ads/presentation/providers/ad_providers.dart
  - lib/main.dart
autonomous: true
requirements: []
must_haves:
  truths:
    - "UMP form evaluation runs after splash completes and BEFORE `MobileAds.instance.initialize()` in `lib/main.dart` (D-04)"
    - "UMP scope is global — UMP SDK auto-detects GDPR/EU and shows form, non-GDPR regions skip automatically (D-05)"
    - "If user denies consent, every `AdRequest` is built with `nonPersonalizedAds: true` (npa=1) — banners still render (D-06)"
    - "UMP consent screen is AdMob-only and does NOT touch Habeas Data Ley 1581 (D-07 — Phase 9 LGL-03 remains separate)"
    - "`UmpService` follows the singleton + idempotent-init pattern from `lib/features/ads/data/services/admob_service.dart` lines 8–10 (PATTERNS.md `Singleton Service Pattern`)"
    - "`UmpService` uses `ConsentInformation.instance` and `ConsentForm` from `google_mobile_ads` (already in pubspec.yaml line 93 at ^5.1.0) — verified API per https://developers.google.com/admob/flutter/privacy on 2026-05-01"
    - "`ConsentState` is an enum with at least 5 values: `unknown`, `required`, `notRequired`, `obtained`, `denied` (mirrors UMP `ConsentStatus` plus our denied semantics)"
    - "`umpServiceProvider`, `umpInitProvider`, `consentStatusProvider`, `consentGrantedProvider`, `umpConsentReadyProvider` are all declared in `lib/features/consent/presentation/providers/consent_providers.dart` (PATTERNS.md `consent_providers.dart`)"
    - "`AdMobService.initialize()` no longer calls `MobileAds.instance.initialize()` from within `lib/main.dart`'s `initializeApp()` — that call is moved to a Riverpod-driven path that runs only after UMP completes"
    - "Every method in `lib/features/ads/data/services/admob_service.dart` that constructs `AdRequest()` (4 sites: `loadBannerAd` line 49, `showRewardedAd` line 84, `showInterstitialAd` line 147, `loadNativeAd` line 195) now accepts a `bool nonPersonalizedAds = false` parameter and passes it through. Callers `BannerAdWidget._loadAd()` and `rewarded_ad_button.dart:_showRewardedAd()` are updated to read `consentGrantedProvider` and forward `!consentGranted`."
    - "`BannerAdWidget._loadAd()` checks `umpConsentReadyProvider` and aborts if false; `_loadAd()` builds `AdRequest(nonPersonalizedAds: !consentGranted)` instead of `const AdRequest()`"
    - "`UmpConsentScreen` reuses `PrimaryGlassButton` from `lib/shared/widgets/glass_button.dart` and `Color(0xFF1A1A1A)` background to match Carden Pro design (PATTERNS.md `Glassmorphism UI for Auth/Consent Screens`)"
    - "All new widgets carry stable `Key`s for Maestro targetability: `ump_consent_screen_root`, `ump_continue_button`, `ump_settings_link` (PATTERNS.md `.maestro/launch/ump-accept.yaml` selectors)"
    - "`flutter analyze` reports zero new errors and `flutter build apk --debug` + `flutter build ios --debug --no-codesign` both succeed"
  artifacts:
    - path: "lib/features/consent/data/services/ump_service.dart"
      provides: "Singleton service wrapping ConsentInformation/ConsentForm from google_mobile_ads"
      min_lines: 60
      contains: "class UmpService"
    - path: "lib/features/consent/domain/entities/consent_state.dart"
      provides: "ConsentState enum (unknown/required/notRequired/obtained/denied)"
      contains: "enum ConsentState"
    - path: "lib/features/consent/presentation/providers/consent_providers.dart"
      provides: "Riverpod providers for UMP service + derived gating booleans"
      contains: "umpConsentReadyProvider"
    - path: "lib/features/consent/presentation/screens/ump_consent_screen.dart"
      provides: "Consent screen that triggers Google's UMP form via UmpService"
      contains: "ump_consent_screen_root"
    - path: "lib/features/consent/presentation/widgets/ump_gate.dart"
      provides: "Wrapper widget that renders UmpConsentScreen if consent unresolved else falls through to AuthWrapper"
      contains: "class UmpGate"
    - path: "lib/main.dart"
      provides: "Splash callback now wraps AuthWrapper in UmpGate; AdMob init removed from initializeApp()"
      contains: "UmpGate"
    - path: "lib/features/ads/data/services/admob_service.dart"
      provides: "Every AdRequest constructor reads npa flag passed by caller"
      contains: "nonPersonalizedAds"
    - path: "lib/features/ads/presentation/widgets/banner_ad_widget.dart"
      provides: "Banner gated by umpConsentReadyProvider; AdRequest carries npa flag"
      contains: "umpConsentReadyProvider"
    - path: "lib/features/ads/presentation/widgets/rewarded_ad_button.dart"
      provides: "Rewarded ad caller forwards npa flag from consentGrantedProvider"
      contains: "consentGrantedProvider"
  key_links:
    - from: "lib/main.dart splash onInitializationComplete callback"
      to: "lib/features/consent/presentation/widgets/ump_gate.dart"
      via: "Splash completion swaps in UmpGate widget; UmpGate consumes umpInitProvider then renders UmpConsentScreen if status==required else AuthWrapper"
      pattern: "UmpGate"
    - from: "lib/features/ads/presentation/widgets/banner_ad_widget.dart"
      to: "consentGrantedProvider"
      via: "BannerAdWidget reads consent state to set AdRequest(nonPersonalizedAds:) per D-06"
      pattern: "nonPersonalizedAds:\\s*!.*consentGranted"
    - from: "UmpConsentScreen continue button"
      to: "MobileAds.instance.initialize() (deferred)"
      via: "UMP completion triggers AdMob init via adMobInitProvider invalidation; banner widgets unblock once umpConsentReadyProvider flips true"
      pattern: "MobileAds\\.instance\\.initialize"
---

<objective>
Wire AdMob UMP consent end-to-end on top of the Firebase + google_mobile_ads foundation laid by plans 03 and 04. Per D-04, UMP runs AFTER splash completes and BEFORE `MobileAds.instance.initialize()`. Per D-05, scope is global (UMP SDK auto-detects GDPR/EU; non-GDPR users skip). Per D-06, denial → `npa=1` (banners render but tracking off). Per D-07, this is AdMob-only — Habeas Data Ley 1581 (LGL-03) is Phase 9 and stays separate.

**Critical correction from earlier draft:** the modern UMP API in Flutter is shipped INSIDE `google_mobile_ads` (already at pubspec.yaml line 93, version ^5.1.0). There is NO standalone UMP package install. Verified via Google's official AdMob Flutter privacy docs (https://developers.google.com/admob/flutter/privacy) on 2026-05-01:
- `ConsentInformation.instance.requestConsentInfoUpdate(params, onSuccess, onError)` — callback-based (NOT async/await)
- `ConsentForm.loadAndShowConsentFormIfRequired(callback)` — callback-based
- `ConsentInformation.instance.canRequestAds()` — async returns bool
- `ConsentRequestParameters()` — empty default constructor for production

Plan 04 explicitly does NOT install a separate UMP package. This plan imports `ConsentInformation`, `ConsentForm`, `ConsentRequestParameters`, `ConsentStatus`, `ConsentRequestParametersBuilder`, and `FormError` from `package:google_mobile_ads/google_mobile_ads.dart`.

Purpose: Closes ROADMAP success criterion #4 ("AdMob UMP consent SDK integrated and consent form shows on first launch before any ad request"). Closes the `Ad Consent & Privacy` gap in `.planning/codebase/CONCERNS.md`. Establishes the `lib/features/consent/` feature module that future privacy work (LGL-03 in Phase 9) will sit alongside but NOT couple to.

Output: New `lib/features/consent/` feature module (data/domain/presentation), refactored `AdMobService` (4 method signatures + 4 AdRequest construction sites), refactored `BannerAdWidget` and `rewarded_ad_button.dart` to forward npa flag, refactored `lib/main.dart` initialization order. All building cleanly on iOS+Android. Maestro selectors (Keys) added to the consent screen so plan 07 can author UMP flows.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/phases/01-foundation-hardening/01-CONTEXT.md
@.planning/phases/01-foundation-hardening/01-PATTERNS.md
@.planning/phases/01-foundation-hardening/01-03-SUMMARY.md
@.planning/phases/01-foundation-hardening/01-04-SUMMARY.md
@.planning/codebase/CONCERNS.md
@.planning/research/PITFALLS.md
@lib/main.dart
@lib/features/ads/data/services/admob_service.dart
@lib/features/ads/presentation/widgets/banner_ad_widget.dart
@lib/features/ads/presentation/widgets/rewarded_ad_button.dart
@lib/features/ads/presentation/providers/ad_providers.dart
@lib/features/splash/splash_screen.dart
@lib/shared/widgets/glass_button.dart

<external_docs>
- Google AdMob Flutter privacy (UMP) docs: https://developers.google.com/admob/flutter/privacy (verified 2026-05-01)
- google_mobile_ads pub.dev: https://pub.dev/packages/google_mobile_ads (current ^5.1.0)
- nonPersonalizedAds (npa) AdRequest field: https://pub.dev/documentation/google_mobile_ads/latest/google_mobile_ads/AdRequest-class.html
</external_docs>

<interfaces>
<!-- AdRequest construction call sites — enumerated per checker WARNING 3.
     Source: `grep -n 'AdRequest()' lib/features/ads/data/services/admob_service.dart` 2026-05-01:

     Line 49 — inside method `loadBannerAd`
       Signature: Future<BannerAd?> loadBannerAd({required String adUnitId, AdSize size = AdSize.banner, void Function(Ad)? onAdLoaded, void Function(Ad, LoadAdError)? onAdFailedToLoad})
       Callers (`grep -rn 'loadBannerAd' lib/`):
         - lib/features/ads/presentation/widgets/banner_ad_widget.dart:52
         - lib/features/ads/presentation/providers/ad_providers.dart:35
         - lib/features/ads/presentation/providers/ad_providers.dart:49

     Line 84 — inside method `showRewardedAd`
       Signature: Future<bool> showRewardedAd({required String adUnitId, required void Function(AdWithoutView, RewardItem) onUserEarnedReward, void Function()? onAdDismissed, void Function(AdError)? onAdFailedToShow})
       Callers (`grep -rn 'showRewardedAd' lib/`):
         - lib/features/ads/presentation/widgets/rewarded_ad_button.dart:45

     Line 147 — inside method `showInterstitialAd`
       Signature: Future<bool> showInterstitialAd({required String adUnitId, void Function()? onAdDismissed, void Function(AdError)? onAdFailedToShow})
       Callers (`grep -rn 'showInterstitialAd' lib/` excluding the definition itself):
         - (none yet — not called from any widget; method is library-ready for Phase 9 marketplace upsells)

     Line 195 — inside method `loadNativeAd`
       Signature: Future<NativeAd?> loadNativeAd({required String adUnitId, required String factoryId, void Function(Ad)? onAdLoaded, void Function(Ad, LoadAdError)? onAdFailedToLoad})
       Callers (`grep -rn 'loadNativeAd' lib/` excluding the definition itself):
         - (none yet — library-ready for future phases) -->

<!-- Patterns to follow, copied from PATTERNS.md / source files. -->

From lib/features/ads/data/services/admob_service.dart (singleton + idempotent init pattern, lines 8-30):
```dart
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AdMob: $e');
    }
  }
}
```

From lib/features/ads/presentation/providers/ad_providers.dart (provider declarations, lines 9-24):
```dart
final adMobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});

final adMobInitProvider = FutureProvider<void>((ref) async {
  final service = ref.read(adMobServiceProvider);
  await service.initialize();
});

final shouldShowAdsProvider = Provider<bool>((ref) {
  return ref.watch(isFreeUserProvider);
});
```

From lib/main.dart (current splash → home transition, lines 97-105):
```dart
home: _showSplash
    ? SplashScreen(
        onInitializationComplete: () {
          setState(() {
            _showSplash = false;
          });
        },
      )
    : const AuthWrapper(),
```

After this plan, that block becomes:
```dart
home: _showSplash
    ? SplashScreen(
        onInitializationComplete: () {
          setState(() {
            _showSplash = false;
          });
        },
      )
    : const UmpGate(child: AuthWrapper()),
```

From lib/shared/widgets/glass_button.dart (button shape used for the consent screen CTA):
```dart
PrimaryGlassButton(
  text: l10n.continueButton,
  onPressed: _handleContinue,
  isLoading: isLoading,
)
```

UMP API — exact shapes from google_mobile_ads ^5.1.0 (verified via Google AdMob privacy docs 2026-05-01):
```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Build params (empty constructor for production):
final params = ConsentRequestParameters();

// Trigger info update — CALLBACK-based (NOT async/await):
ConsentInformation.instance.requestConsentInfoUpdate(
  params,
  () async {
    // success — consent info updated
    if (await ConsentInformation.instance.isConsentFormAvailable()) {
      // load and show form if required
      ConsentForm.loadAndShowConsentFormIfRequired((FormError? loadAndShowError) {
        // form dismissed (or no error and not required)
      });
    }
  },
  (FormError formError) {
    // error path — fail open
  },
);

// Query current status — async:
final canRequestAds = await ConsentInformation.instance.canRequestAds();

// Query consent status enum:
final ConsentStatus status = await ConsentInformation.instance.getConsentStatus();
// ConsentStatus enum: unknown, required, notRequired, obtained
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Create consent domain + data + provider layer</name>
  <files>lib/features/consent/domain/entities/consent_state.dart, lib/features/consent/data/services/ump_service.dart, lib/features/consent/presentation/providers/consent_providers.dart</files>
  <read_first>
    - lib/features/ads/data/services/admob_service.dart (singleton + idempotent init pattern — replicate shape exactly)
    - lib/features/ads/presentation/providers/ad_providers.dart (provider declaration patterns)
    - .planning/phases/01-foundation-hardening/01-PATTERNS.md sections "lib/features/consent/data/services/ump_service.dart (NEW)" and "lib/features/consent/presentation/providers/consent_providers.dart (NEW)"
    - pubspec.yaml line 93 (verify google_mobile_ads ^5.1.0 — already present, the source of UMP types)
  </read_first>
  <action>
Create THREE files exactly as specified.

**File 1: `lib/features/consent/domain/entities/consent_state.dart`**

```dart
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
```

**File 2: `lib/features/consent/data/services/ump_service.dart`**

Replicate the singleton + idempotent + try/catch + debugPrint shape from `lib/features/ads/data/services/admob_service.dart` lines 8-30. The UMP package types come from `google_mobile_ads` itself.

NOTE on API shape: `ConsentInformation.instance.requestConsentInfoUpdate(...)` is **callback-based, NOT async/await**. Wrap it in a `Completer` to expose an awaitable `Future<ConsentState>` API to the rest of the app.

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../domain/entities/consent_state.dart';

class UmpService {
  static final UmpService _instance = UmpService._internal();
  factory UmpService() => _instance;
  UmpService._internal();

  bool _isInitialized = false;
  ConsentState _state = ConsentState.unknown;

  bool get isInitialized => _isInitialized;
  ConsentState get state => _state;

  /// Idempotent. Calls google_mobile_ads' `ConsentInformation.instance.requestConsentInfoUpdate`
  /// (callback-based) and unwraps it into a Future<ConsentState>.
  /// Per D-05: SDK auto-detects GDPR/EU; non-GDPR returns notRequired.
  Future<ConsentState> requestConsentInfoUpdate() async {
    if (_isInitialized) return _state;

    final completer = Completer<ConsentState>();
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // Success path — consent info now reflects the current jurisdiction.
        try {
          final status = await ConsentInformation.instance.getConsentStatus();
          _state = _mapStatus(status);
          _isInitialized = true;
          debugPrint('UMP consent info updated: $_state');
          completer.complete(_state);
        } catch (e) {
          debugPrint('UMP getConsentStatus failed after info update: $e');
          _state = ConsentState.notRequired; // fail-open
          _isInitialized = true;
          completer.complete(_state);
        }
      },
      (FormError formError) {
        debugPrint(
          'UMP requestConsentInfoUpdate failed: '
          '${formError.errorCode} ${formError.message}',
        );
        // Fail-open: treat as notRequired so app does not deadlock on consent.
        _state = ConsentState.notRequired;
        _isInitialized = true;
        completer.complete(_state);
      },
    );

    return completer.future;
  }

  /// If consent is required, present Google's hosted form. Updates state on completion.
  /// Per D-06: deny path returns ConsentState.denied; accept returns ConsentState.obtained.
  Future<ConsentState> loadAndShowConsentFormIfRequired() async {
    if (_state != ConsentState.required) return _state;

    final completer = Completer<ConsentState>();

    ConsentForm.loadAndShowConsentFormIfRequired((FormError? loadAndShowError) async {
      if (loadAndShowError != null) {
        debugPrint(
          'UMP loadAndShowConsentFormIfRequired failed: '
          '${loadAndShowError.errorCode} ${loadAndShowError.message}',
        );
        _state = ConsentState.denied; // conservative — assume deny on failure
        completer.complete(_state);
        return;
      }
      try {
        final status = await ConsentInformation.instance.getConsentStatus();
        // ConsentStatus.obtained on success — we cannot distinguish accept vs deny
        // through ConsentStatus alone. Use canRequestAds() to disambiguate:
        // - canRequestAds == true  -> personalized OR npa accepted -> ConsentState.obtained
        // - canRequestAds == false -> nothing accepted -> ConsentState.denied
        final canRequestAds = await ConsentInformation.instance.canRequestAds();
        if (status == ConsentStatus.obtained && !canRequestAds) {
          _state = ConsentState.denied;
        } else {
          _state = _mapStatus(status);
        }
        debugPrint('UMP form completed: $_state (canRequestAds=$canRequestAds)');
        completer.complete(_state);
      } catch (e) {
        debugPrint('UMP getConsentStatus after form failed: $e');
        _state = ConsentState.denied;
        completer.complete(_state);
      }
    });

    return completer.future;
  }

  /// Test hook — resets singleton state. NOT used in production code.
  @visibleForTesting
  void reset() {
    _isInitialized = false;
    _state = ConsentState.unknown;
  }

  ConsentState _mapStatus(ConsentStatus status) {
    switch (status) {
      case ConsentStatus.required:
        return ConsentState.required;
      case ConsentStatus.notRequired:
        return ConsentState.notRequired;
      case ConsentStatus.obtained:
        return ConsentState.obtained;
      case ConsentStatus.unknown:
        return ConsentState.unknown;
    }
  }
}
```

**File 3: `lib/features/consent/presentation/providers/consent_providers.dart`**

Mirror the pattern from `lib/features/ads/presentation/providers/ad_providers.dart` lines 9-24. Declare exactly these providers:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ump_service.dart';
import '../../domain/entities/consent_state.dart';

/// Singleton service provider.
final umpServiceProvider = Provider<UmpService>((ref) {
  return UmpService();
});

/// One-shot init: triggers requestConsentInfoUpdate. Consume via .when() in UI.
final umpInitProvider = FutureProvider<ConsentState>((ref) async {
  final service = ref.read(umpServiceProvider);
  return service.requestConsentInfoUpdate();
});

/// Current consent state. Reads from service singleton.
final consentStateProvider = Provider<ConsentState>((ref) {
  return ref.watch(umpServiceProvider).state;
});

/// True when UMP has finished resolving (form shown or auto-skipped).
/// BannerAdWidget gates render on this; AdMob init waits for this. (D-04)
final umpConsentReadyProvider = Provider<bool>((ref) {
  return ref.watch(consentStateProvider).isResolved;
});

/// True when personalized ads are allowed (obtained or notRequired).
/// AdRequest reads this: nonPersonalizedAds: !consentGranted. (D-06)
final consentGrantedProvider = Provider<bool>((ref) {
  return ref.watch(consentStateProvider).isPersonalizedAllowed;
});
```
  </action>
  <verify>
    <automated>flutter analyze lib/features/consent/ 2>&amp;1 | grep -v '^Analyzing' | grep -E 'error|warning' | wc -l | xargs -I {} test {} -eq 0</automated>
  </verify>
  <acceptance_criteria>
    - File `lib/features/consent/domain/entities/consent_state.dart` exists and contains `enum ConsentState` with 5 values (unknown/required/notRequired/obtained/denied)
    - File `lib/features/consent/data/services/ump_service.dart` exists and contains `class UmpService` with private named constructor `UmpService._internal()` (singleton pattern)
    - `grep -c "import 'package:google_mobile_ads/google_mobile_ads.dart'" lib/features/consent/data/services/ump_service.dart` returns 1 (UMP types come from google_mobile_ads)
    - `grep -c 'ConsentInformation.instance.requestConsentInfoUpdate' lib/features/consent/data/services/ump_service.dart` returns 1
    - `grep -c 'ConsentForm.loadAndShowConsentFormIfRequired' lib/features/consent/data/services/ump_service.dart` returns 1
    - File `lib/features/consent/presentation/providers/consent_providers.dart` exists and contains all five identifiers: `umpServiceProvider`, `umpInitProvider`, `consentStateProvider`, `umpConsentReadyProvider`, `consentGrantedProvider`
    - `grep -c 'extension ConsentStateX' lib/features/consent/domain/entities/consent_state.dart` returns 1
    - `grep -c 'class UmpService' lib/features/consent/data/services/ump_service.dart` returns 1
    - `flutter analyze lib/features/consent/` exits 0 (zero errors, zero warnings)
  </acceptance_criteria>
  <done>Consent feature module's domain/data/presentation-providers layers exist, follow the AdMobService singleton pattern, expose the documented Riverpod providers, use the verified `ConsentInformation`/`ConsentForm` API from google_mobile_ads, and pass `flutter analyze`.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Build UmpConsentScreen + UmpGate widget</name>
  <files>lib/features/consent/presentation/screens/ump_consent_screen.dart, lib/features/consent/presentation/widgets/ump_gate.dart</files>
  <read_first>
    - lib/features/consent/data/services/ump_service.dart (created in task 1 — UI calls into this)
    - lib/features/consent/presentation/providers/consent_providers.dart (created in task 1)
    - lib/features/qr_generator/presentation/pages/text_qr_screen.dart (ConsumerStatefulWidget skeleton + WidgetsBinding.instance.addPostFrameCallback pattern — PATTERNS.md `ump_consent_screen.dart` analog)
    - lib/shared/widgets/glass_button.dart (PrimaryGlassButton signature for the CTA)
    - lib/features/auth/presentation/pages/auth_flow.dart (downstream widget that UmpGate hands off to)
    - .planning/phases/01-foundation-hardening/01-PATTERNS.md section "Glassmorphism UI for Auth/Consent Screens"
  </read_first>
  <action>
**File 1: `lib/features/consent/presentation/screens/ump_consent_screen.dart`**

A `ConsumerStatefulWidget` that on first frame calls `UmpService.loadAndShowConsentFormIfRequired()`. Google's UMP SDK renders the actual form as a system overlay — our screen is a thin wrapper with a fallback CTA in case the form fails to load. Use `Color(0xFF1A1A1A)` background. Action button uses `PrimaryGlassButton`. Add stable Keys for Maestro.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../providers/consent_providers.dart';

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
```

**File 2: `lib/features/consent/presentation/widgets/ump_gate.dart`**

`UmpGate` is a `ConsumerWidget` that consumes `umpInitProvider`. While loading: shows a centered `CircularProgressIndicator`. On error or `state.isResolved == true`: renders `child` (which will be `AuthWrapper`). If state requires consent: renders `UmpConsentScreen`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/consent_providers.dart';
import '../screens/ump_consent_screen.dart';

class UmpGate extends ConsumerWidget {
  final Widget child;
  const UmpGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsync = ref.watch(umpInitProvider);
    final ready = ref.watch(umpConsentReadyProvider);

    if (ready) return child;

    return initAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) {
        // Fail-open: do not block the app on UMP errors. Show child.
        debugPrint('UmpGate error, failing open: $e');
        return child;
      },
      data: (state) {
        if (state.isResolved) return child;
        return const UmpConsentScreen();
      },
    );
  }
}
```
  </action>
  <verify>
    <automated>flutter analyze lib/features/consent/ 2>&amp;1 | grep -v '^Analyzing' | grep -E 'error|warning' | wc -l | xargs -I {} test {} -eq 0</automated>
  </verify>
  <acceptance_criteria>
    - File `lib/features/consent/presentation/screens/ump_consent_screen.dart` exists and contains `class UmpConsentScreen extends ConsumerStatefulWidget`
    - File `lib/features/consent/presentation/widgets/ump_gate.dart` exists and contains `class UmpGate extends ConsumerWidget`
    - `grep -c "Key('ump_consent_screen_root')" lib/features/consent/presentation/screens/ump_consent_screen.dart` returns 1
    - `grep -c "Key('ump_continue_button')" lib/features/consent/presentation/screens/ump_consent_screen.dart` returns 1
    - `grep -c 'PrimaryGlassButton' lib/features/consent/presentation/screens/ump_consent_screen.dart` returns at least 1
    - `grep -c '0xFF1A1A1A' lib/features/consent/presentation/screens/ump_consent_screen.dart` returns at least 1 (Carden Pro background)
    - `grep -c 'umpInitProvider' lib/features/consent/presentation/widgets/ump_gate.dart` returns at least 1
    - `flutter analyze lib/features/consent/` exits 0
  </acceptance_criteria>
  <done>UmpConsentScreen renders Carden Pro card with PrimaryGlassButton CTA and stable Keys; UmpGate gates `child` on consent readiness using `.when()`; both pass `flutter analyze`.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 3: Refactor main.dart init order + AdMobService 4 method signatures + BannerAdWidget + RewardedAdButton</name>
  <files>lib/main.dart, lib/features/ads/data/services/admob_service.dart, lib/features/ads/presentation/widgets/banner_ad_widget.dart, lib/features/ads/presentation/widgets/rewarded_ad_button.dart, lib/features/ads/presentation/providers/ad_providers.dart</files>
  <read_first>
    - lib/main.dart (current `initializeApp()` at lines 25-41 and `_QRaftAppState.build` at lines 64-107)
    - lib/features/ads/data/services/admob_service.dart (4 AdRequest construction sites enumerated below)
    - lib/features/ads/presentation/widgets/banner_ad_widget.dart (`_loadAd()` lines 41-77; `build()` lines 81-86; calls service.loadBannerAd at line 52)
    - lib/features/ads/presentation/widgets/rewarded_ad_button.dart (`_showRewardedAd()` line 36; calls service.showRewardedAd at line 45)
    - lib/features/ads/presentation/providers/ad_providers.dart (calls service.loadBannerAd at lines 35, 49)
    - lib/features/consent/presentation/widgets/ump_gate.dart (created in task 2 — main.dart imports this)
    - lib/features/consent/presentation/providers/consent_providers.dart (created in task 1)
    - .planning/phases/01-foundation-hardening/01-PATTERNS.md sections "lib/main.dart (modify)", "lib/features/ads/data/services/admob_service.dart", "lib/features/ads/presentation/widgets/banner_ad_widget.dart"
  </read_first>
  <action>

### Edit 1 — `lib/main.dart` — remove AdMob init from `initializeApp()`

In the `initializeApp()` function (currently at lines 25-41), DELETE the lines:
```dart
await MobileAds.instance.initialize();
debugPrint('✅ AdMob initialized');
```

The new order inside `initializeApp()` is:
```
EnvConfig.debugConfig();
await SupabaseService.initialize();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // already added by plan 03
debugPrint('✅ QRaft initialized with Supabase + Firebase core');
```

### Edit 2 — `lib/main.dart` — wrap AuthWrapper in UmpGate

In `_QRaftAppState.build()` (currently around lines 97-105), change:
```dart
: const AuthWrapper(),
```
to:
```dart
: const UmpGate(child: AuthWrapper()),
```
Add the import at the top:
```dart
import 'features/consent/presentation/widgets/ump_gate.dart';
```

Also add a top-level provider listener (in `_QRaftAppState.build`) that, once `umpConsentReadyProvider` flips to `true`, calls `ref.read(adMobInitProvider.future)` to trigger AdMob init. Implementation:

If the existing `_QRaftAppState` is `ConsumerState<QRaftApp>`, place the `ref.listen` at the top of `build`. If it isn't a Consumer, convert it to one (`extends ConsumerStatefulWidget` / `extends ConsumerState<>`):

```dart
ref.listen<bool>(umpConsentReadyProvider, (prev, next) {
  if (next == true && prev != true) {
    // UMP just resolved — kick off AdMob init.
    ref.read(adMobInitProvider.future);
  }
});
```

The goal: AdMob init is triggered only after `umpConsentReadyProvider == true`.

### Edit 3 — `lib/features/ads/data/services/admob_service.dart` — accept npa flag in all 4 ad-loading methods

There are exactly 4 sites that construct `const AdRequest()` (verified by `grep -n 'AdRequest()' lib/features/ads/data/services/admob_service.dart` on 2026-05-01). Modify each method's signature to add a `bool nonPersonalizedAds = false` named parameter, then change the construction. Specifically:

**Site 1 — Method `loadBannerAd` (line 49 — inside method declared at line 33):**

Change signature from:
```dart
Future<BannerAd?> loadBannerAd({
  required String adUnitId,
  AdSize size = AdSize.banner,
  void Function(Ad)? onAdLoaded,
  void Function(Ad, LoadAdError)? onAdFailedToLoad,
}) async {
```
to:
```dart
Future<BannerAd?> loadBannerAd({
  required String adUnitId,
  AdSize size = AdSize.banner,
  void Function(Ad)? onAdLoaded,
  void Function(Ad, LoadAdError)? onAdFailedToLoad,
  bool nonPersonalizedAds = false,
}) async {
```
Change line 49 from `request: const AdRequest(),` to:
```dart
request: AdRequest(nonPersonalizedAds: nonPersonalizedAds),
```
**Acceptance — site 1:** `grep -A3 'Future<BannerAd?> loadBannerAd' lib/features/ads/data/services/admob_service.dart | grep -c 'nonPersonalizedAds'` returns at least 1.

**Site 2 — Method `showRewardedAd` (line 84 — inside method declared at line 69):**

Change signature from:
```dart
Future<bool> showRewardedAd({
  required String adUnitId,
  required void Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward,
  void Function()? onAdDismissed,
  void Function(AdError error)? onAdFailedToShow,
}) async {
```
to:
```dart
Future<bool> showRewardedAd({
  required String adUnitId,
  required void Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward,
  void Function()? onAdDismissed,
  void Function(AdError error)? onAdFailedToShow,
  bool nonPersonalizedAds = false,
}) async {
```
Change line 84 from `request: const AdRequest(),` to:
```dart
request: AdRequest(nonPersonalizedAds: nonPersonalizedAds),
```

**Site 3 — Method `showInterstitialAd` (line 147 — inside method declared at line 128):**

Change signature from:
```dart
Future<bool> showInterstitialAd({
  required String adUnitId,
  void Function()? onAdDismissed,
  void Function(AdError error)? onAdFailedToShow,
}) async {
```
to:
```dart
Future<bool> showInterstitialAd({
  required String adUnitId,
  void Function()? onAdDismissed,
  void Function(AdError error)? onAdFailedToShow,
  bool nonPersonalizedAds = false,
}) async {
```
Change line 147 from `request: const AdRequest(),` to:
```dart
request: AdRequest(nonPersonalizedAds: nonPersonalizedAds),
```

**Site 4 — Method `loadNativeAd` (line 195 — inside method declared at line 179):**

Change signature from:
```dart
Future<NativeAd?> loadNativeAd({
  required String adUnitId,
  required String factoryId,
  void Function(Ad)? onAdLoaded,
  void Function(Ad, LoadAdError)? onAdFailedToLoad,
}) async {
```
to:
```dart
Future<NativeAd?> loadNativeAd({
  required String adUnitId,
  required String factoryId,
  void Function(Ad)? onAdLoaded,
  void Function(Ad, LoadAdError)? onAdFailedToLoad,
  bool nonPersonalizedAds = false,
}) async {
```
Change line 195 from `request: const AdRequest(),` to:
```dart
request: AdRequest(nonPersonalizedAds: nonPersonalizedAds),
```

The service does NOT read Riverpod refs directly (it's a plain singleton). Callers read the provider and pass the boolean down — see edits 4, 5, 6.

**Caller list to update** (verified by `grep -rn '<method>' lib/`):
- `loadBannerAd` callers: 3 sites — `banner_ad_widget.dart:52`, `ad_providers.dart:35`, `ad_providers.dart:49`
- `showRewardedAd` callers: 1 site — `rewarded_ad_button.dart:45`
- `showInterstitialAd` callers: 0 sites in `lib/` (library-ready for Phase 9 marketplace upsells; default `false` is correct for now)
- `loadNativeAd` callers: 0 sites in `lib/` (library-ready; default `false` is correct for now)

**Boundary note:** initialization no longer happens from `lib/main.dart`. `AdMobService.initialize()` is now invoked exclusively via `adMobInitProvider` in `lib/features/ads/presentation/providers/ad_providers.dart`, which is in turn triggered by the `ref.listen` in `lib/main.dart` after UMP resolves.

### Edit 4 — `lib/features/ads/presentation/widgets/banner_ad_widget.dart` — gate on UMP + pass npa

Modify `_loadAd()` (lines 41-77):
```dart
Future<void> _loadAd() async {
  final shouldShow = ref.read(shouldShowAdsProvider);
  if (!shouldShow) return;

  // NEW: do not load before UMP resolves. (D-04)
  final consentReady = ref.read(umpConsentReadyProvider);
  if (!consentReady) return;

  if (_isLoading) return;
  _isLoading = true;

  await ref.read(adMobInitProvider.future);

  // NEW: pass npa flag based on consent. (D-06)
  final personalizedAllowed = ref.read(consentGrantedProvider);
  final service = ref.read(adMobServiceProvider);
  // Update the existing service.loadBannerAd(...) call site (currently line 52)
  // to pass nonPersonalizedAds: !personalizedAllowed
  final ad = await service.loadBannerAd(
    adUnitId: /* existing adUnitId */,
    size: /* existing size */,
    onAdLoaded: /* existing callback */,
    onAdFailedToLoad: /* existing callback */,
    nonPersonalizedAds: !personalizedAllowed,
  );
  // ... existing onLoaded/onFailed handling
}
```

Modify `build()` (lines 81-86) to also watch `umpConsentReadyProvider` and skip render when not ready:
```dart
@override
Widget build(BuildContext context) {
  final shouldShow = ref.watch(shouldShowAdsProvider);
  final consentReady = ref.watch(umpConsentReadyProvider);

  if (!shouldShow || !consentReady || !_isLoaded || _bannerAd == null) {
    return const SizedBox.shrink();
  }
  // ... existing AdWidget render
}
```

Add the import:
```dart
import '../../../consent/presentation/providers/consent_providers.dart';
```

### Edit 5 — `lib/features/ads/presentation/widgets/rewarded_ad_button.dart` — pass npa to showRewardedAd

`rewarded_ad_button.dart:_showRewardedAd()` calls `service.showRewardedAd(...)` at line 45. Update that call site to pass `nonPersonalizedAds: !ref.read(consentGrantedProvider)`:

```dart
final personalizedAllowed = ref.read(consentGrantedProvider);
final success = await service.showRewardedAd(
  adUnitId: /* existing adUnitId */,
  onUserEarnedReward: /* existing callback */,
  onAdDismissed: /* existing */,
  onAdFailedToShow: /* existing */,
  nonPersonalizedAds: !personalizedAllowed,
);
```

Add the import:
```dart
import '../../../consent/presentation/providers/consent_providers.dart';
```

### Edit 6 — `lib/features/ads/presentation/providers/ad_providers.dart` — pass npa from 2 internal callers

`ad_providers.dart` calls `service.loadBannerAd(...)` at lines 35 and 49 (verified via grep). For each of those two sites, update to pass `nonPersonalizedAds: !ref.read(consentGrantedProvider)`. The provider's `(ref)` parameter has read access — no refactor needed beyond importing `consent_providers.dart` and threading the boolean.

Add the import at the top of `ad_providers.dart`:
```dart
import '../../../consent/presentation/providers/consent_providers.dart';
```

If `lib/features/ads/presentation/providers/ad_providers.dart` lacks an `adMobInitProvider` declaration, add one per the PATTERNS.md sample:
```dart
final adMobInitProvider = FutureProvider<void>((ref) async {
  final service = ref.read(adMobServiceProvider);
  await service.initialize();
});
```
  </action>
  <verify>
    <automated>flutter analyze 2>&amp;1 | grep -E '^\s*(error|warning)' | wc -l | xargs -I {} test {} -eq 0 &amp;&amp; flutter build apk --debug --target-platform android-arm64 2>&amp;1 | tail -3 | grep -q 'Built' &amp;&amp; flutter build ios --debug --no-codesign 2>&amp;1 | tail -3 | grep -q 'Built'</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c 'MobileAds.instance.initialize' lib/main.dart` returns 0 (AdMob init removed from main.dart per D-04)
    - `grep -c 'UmpGate' lib/main.dart` returns at least 2 (import + usage)
    - `grep -c 'umpConsentReadyProvider' lib/main.dart` returns at least 1 (the ref.listen)
    - `grep -c 'adMobInitProvider' lib/main.dart` returns at least 1 (kicked off after UMP resolves)
    - `grep -c 'nonPersonalizedAds' lib/features/ads/data/services/admob_service.dart` returns at least 8 (4 method signatures with the named param + 4 AdRequest construction sites passing it through)
    - `grep -c 'const AdRequest()' lib/features/ads/data/services/admob_service.dart` returns 0 (all 4 sites converted)
    - Each of the 4 methods has the new param: `grep -A6 'Future<BannerAd?> loadBannerAd'`, `grep -A7 'Future<bool> showRewardedAd'`, `grep -A5 'Future<bool> showInterstitialAd'`, `grep -A6 'Future<NativeAd?> loadNativeAd'` each contain `nonPersonalizedAds` (one match per method block).
    - `grep -c 'umpConsentReadyProvider' lib/features/ads/presentation/widgets/banner_ad_widget.dart` returns at least 1
    - `grep -c 'consentGrantedProvider' lib/features/ads/presentation/widgets/banner_ad_widget.dart` returns at least 1
    - `grep -c 'consentGrantedProvider' lib/features/ads/presentation/widgets/rewarded_ad_button.dart` returns at least 1
    - `grep -c "import '../../../consent/" lib/features/ads/presentation/widgets/banner_ad_widget.dart` returns at least 1
    - `grep -c "import '../../../consent/" lib/features/ads/presentation/widgets/rewarded_ad_button.dart` returns at least 1
    - `grep -c "import '../../../consent/" lib/features/ads/presentation/providers/ad_providers.dart` returns at least 1
    - `flutter analyze` exits 0 (zero errors)
    - `flutter build apk --debug --target-platform android-arm64` succeeds (output contains "Built")
    - `flutter build ios --debug --no-codesign` succeeds (output contains "Built")
  </acceptance_criteria>
  <done>main.dart initializes Firebase but NOT AdMob inside `initializeApp()`; AdMob init is deferred until UMP resolves via `ref.listen`; all 4 AdRequest construction sites in admob_service.dart now thread `nonPersonalizedAds` through; banner widget + rewarded button + 2 ad_providers call sites forward `!consentGranted`; banner widget gates render and load on `umpConsentReadyProvider`; both Android and iOS debug builds succeed.</done>
</task>

</tasks>

<verification>
After all 3 tasks complete:

```bash
# 1. Static analysis is clean
flutter analyze

# 2. Both debug builds succeed
flutter build apk --debug --target-platform android-arm64
flutter build ios --debug --no-codesign

# 3. Smoke test on both simulators (manual; final E2E covered by plan 07 Maestro flows)
# flutter run --dart-define-from-file=env.json -d "iPhone 15"
# flutter run --dart-define-from-file=env.json -d "sdk gphone"

# 4. Verify consent providers are in the Riverpod graph and threaded into all callers
grep -r 'umpConsentReadyProvider\|consentGrantedProvider' lib/features/ads/ | wc -l
# Should return at least 4 lines (banner widget reads both; rewarded button reads consentGrantedProvider; ad_providers reads consentGrantedProvider).

# 5. Verify all AdRequest call sites converted
grep -c 'const AdRequest()' lib/features/ads/data/services/admob_service.dart
# Must return 0.

grep -c 'AdRequest(nonPersonalizedAds:' lib/features/ads/data/services/admob_service.dart
# Must return 4 (one per method).
```
</verification>

<success_criteria>
- ROADMAP success criterion #4 (UMP integrated, consent form on first launch before any ad request) is satisfied
- D-04 ordering: splash → UMP eval → MobileAds.initialize() — verified by absence of MobileAds.initialize call in main.dart's initializeApp
- D-05 global scope: UMP SDK auto-detects regions; no manual region lists in our code
- D-06 npa=1: every AdRequest construction site reads the npa flag from `consentGrantedProvider` (4 service methods + their callers)
- D-07 separation: consent module is AdMob-only; no Habeas Data UI strings or imports from `features/profile/` or `features/auth/`
- Plan 07 has Maestro selectors to target: `ump_consent_screen_root`, `ump_continue_button`
- API surface matches verified Google AdMob Flutter privacy docs (https://developers.google.com/admob/flutter/privacy) — `ConsentInformation.instance` and `ConsentForm.loadAndShowConsentFormIfRequired` from google_mobile_ads ^5.1.0
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundation-hardening/01-05-SUMMARY.md` documenting:
- Final ConsentState enum values and their semantics
- The exact main.dart init flow (Supabase → Firebase → splash → UMP gate → AuthWrapper)
- Where AdMob init now happens (ref.listen in main.dart, triggered post-UMP)
- The 4 admob_service.dart method signatures that grew the `nonPersonalizedAds` param + the call-site updates in banner_ad_widget.dart, rewarded_ad_button.dart, and ad_providers.dart
- Verification that `flutter analyze` is clean and both builds succeed
- Note that Maestro flows for ump-accept.yaml + ump-deny-npa.yaml are deferred to plan 07
</output>
</content>
</invoke>