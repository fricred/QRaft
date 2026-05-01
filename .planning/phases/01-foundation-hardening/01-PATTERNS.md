# Phase 1: Foundation Hardening - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 23 (8 modify + 15 create — pubspec, main.dart, ads, auth, native config, Maestro flows)
**Analogs found:** 17 / 23 (6 are net-new categories: native config files, Maestro flows, no existing analog in repo)

> **Important caveats reconciled during mapping:**
> 1. CONTEXT.md and CLAUDE.md reference `lib/features/auth/presentation/controllers/auth_controller.dart` as the analog for the new `ForgotPasswordController`. **That file does not exist** — the directory `lib/features/auth/presentation/controllers/` is empty. The actual auth state holder is `lib/features/auth/data/providers/supabase_auth_provider.dart` (a `ChangeNotifier` exposed via `ChangeNotifierProvider`). This is the authoritative auth pattern in the codebase. The closest "controller" analogs that follow Riverpod `StateNotifier` + immutable state are in `lib/features/qr_generator/presentation/controllers/`. Planner must reconcile this discrepancy when proposing the controller pattern (StateNotifier vs AsyncNotifier vs hybrid per D-09).
> 2. The 327-line dialog target in CONTEXT.md is `lib/features/auth/presentation/widgets/forgot_password_dialog.dart`. The actual file is **328 lines**. Close enough — small line drift, no concern.
> 3. The "secondary AdMob init call site" referenced as `admob_service.dart:24` is `MobileAds.instance.initialize()` inside `AdMobService.initialize()`. It is invoked indirectly via `adMobInitProvider` (a `FutureProvider`), not from `main.dart`. `main.dart:35` is the direct call. Both must be UMP-gated.
> 4. **No `.maestro/` directory exists** — the entire Maestro foundation is net-new. There is no in-repo flow analog; planner must lean on Maestro docs and use mcp tools (`mcp__maestro__check_flow_syntax`, `mcp__maestro__query_docs`).

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `pubspec.yaml` (modify) | config | n/a | `pubspec.yaml` (self) | exact (in-place edit) |
| `lib/main.dart` (modify) | bootstrap | event-driven | `lib/main.dart` (self) | exact (in-place edit) |
| `lib/features/ads/data/services/admob_service.dart` (modify) | service | event-driven | `lib/features/ads/data/services/admob_service.dart` (self) | exact (in-place edit) |
| `lib/features/ads/presentation/widgets/banner_ad_widget.dart` (modify) | widget | request-response | `lib/features/ads/presentation/widgets/banner_ad_widget.dart` (self) | exact (in-place edit) |
| `lib/features/auth/presentation/widgets/forgot_password_dialog.dart` (modify) | widget | request-response | `lib/features/auth/presentation/widgets/forgot_password_dialog.dart` (self) | exact (in-place edit) |
| `test/features/auth/presentation/widgets/forgot_password_dialog_test.dart` (modify) | test | n/a | self + `test/features/qr_generator/presentation/controllers/wifi_form_controller_test.dart` | exact + extension |
| `android/app/build.gradle.kts` (modify) | native-config | n/a | self | exact (in-place edit) |
| `ios/Podfile` (modify) | native-config | n/a | self | exact (in-place edit) |
| `lib/features/consent/data/services/ump_service.dart` (NEW) | service | event-driven | `lib/features/ads/data/services/admob_service.dart` (singleton + init) | role-match |
| `lib/features/consent/domain/entities/consent_state.dart` (NEW) | model | n/a | `lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart` (state class shape) | role-match |
| `lib/features/consent/presentation/providers/consent_providers.dart` (NEW) | provider | event-driven | `lib/features/ads/presentation/providers/ad_providers.dart` | exact role match |
| `lib/features/consent/presentation/screens/ump_consent_screen.dart` (NEW) | screen | event-driven | `lib/features/qr_generator/presentation/pages/text_qr_screen.dart` (ConsumerStatefulWidget skeleton) | role-match |
| `lib/features/auth/presentation/controllers/forgot_password_controller.dart` (NEW) | controller | request-response | `lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart` (StateNotifier shape) + `supabase_auth_provider.dart` (Supabase calls) | hybrid (best in repo — no AsyncNotifier example exists) |
| `test/features/auth/presentation/controllers/forgot_password_controller_test.dart` (NEW) | test | n/a | `test/features/qr_generator/presentation/controllers/wifi_form_controller_test.dart` | exact role match |
| `android/app/google-services.json` (NEW) | native-config | n/a | none in repo | no analog (Firebase asset, downloaded from console) |
| `ios/Runner/GoogleService-Info.plist` (NEW) | native-config | n/a | none in repo | no analog (Firebase asset, downloaded from console) |
| `.maestro/config.yaml` (NEW) | e2e-config | n/a | none in repo | no analog (Maestro docs) |
| `.maestro/helpers/login.yaml` (NEW) | e2e-flow | n/a | none in repo | no analog (Maestro docs) |
| `.maestro/helpers/dismiss-permissions.yaml` (NEW) | e2e-flow | n/a | none in repo | no analog (Maestro docs) |
| `.maestro/auth/login-valid.yaml` + `login-invalid.yaml` + `logout.yaml` + `forgot-password.yaml` + `session-persistence.yaml` (NEW) | e2e-flow | n/a | `lib/features/auth/...` (selectors target these widgets) | partial (selectors only) |
| `.maestro/launch/splash-happy.yaml` + `ump-accept.yaml` + `ump-deny-npa.yaml` (NEW) | e2e-flow | n/a | `lib/features/splash/splash_screen.dart` + new UMP screen | partial (selectors only) |
| `.maestro/scanner/scanner-tab-launch.yaml` (NEW) | e2e-flow | n/a | `lib/features/qr_scanner/qr_scanner_screen.dart` | partial (selectors only) |
| `CLAUDE.md` + `.planning/codebase/CONCERNS.md` (modify) | docs | n/a | self | exact (in-place edit) |

---

## Pattern Assignments

### `lib/main.dart` (bootstrap, event-driven) — modify

**Analog:** `lib/main.dart` (self) — current `initializeApp()` at lines 25–41 and `_QRaftAppState.build` at lines 64–107.

**Current init order pattern** (lines 25–41) — order to extend:
```dart
Future<void> initializeApp() async {
  try {
    EnvConfig.debugConfig();
    await SupabaseService.initialize();
    debugPrint('✅ QRaft initialized with Supabase-only authentication');

    await MobileAds.instance.initialize();
    debugPrint('✅ AdMob initialized');
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
}
```
**Required new ordering** (per D-04, D-05): `EnvConfig.debugConfig()` → `SupabaseService.initialize()` → `Firebase.initializeApp()` → splash plays → `UmpService.requestConsentInformationUpdate()` (post-splash) → on consent complete: `MobileAds.instance.initialize()` (with npa flag if denied per D-06). Move `MobileAds.instance.initialize()` OUT of `initializeApp()` and gate it behind UMP completion.

**Splash → home transition pattern** (lines 97–105) — natural hook for UMP:
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
The `onInitializationComplete` callback is where UMP gating must dispatch (per D-04: "Splash animation runs unimpeded. Once splash finishes, before `MobileAds.instance.initialize()` is called, UMP evaluates"). Replace `AuthWrapper` with a new gating widget (`UmpGate`) that renders the UMP consent screen if needed, then falls through to `AuthWrapper`.

**Existing imports to add** (line 1–14 — current import list):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// ...
```
Add: `package:firebase_core/firebase_core.dart`, the new UMP service import, the new `firebase_options.dart` (generated by FlutterFire CLI).

---

### `lib/features/ads/data/services/admob_service.dart` (service, event-driven) — modify

**Analog:** `admob_service.dart` (self) — singleton at lines 8–10, init at lines 20–30.

**Singleton + idempotent init pattern** (lines 8–30) — the pattern to preserve:
```dart
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  bool _isInitialized = false;
  // ...

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
```
**Required modification** (per D-04, D-06): `initialize()` must accept (or read from a provider) the consent state and pass `npa=1` via a `RequestConfiguration` set BEFORE calling `MobileAds.instance.initialize()`. Also: do not initialize if consent is "unknown" — wait for the UMP gate.

**`AdRequest` construction pattern to extend** (lines 49, 84, 147, 195) — every ad load builds `const AdRequest()`. Update all of these to read consent state and pass `nonPersonalizedAds: true` when denied:
```dart
request: const AdRequest(),  // current
// → new
request: AdRequest(
  nonPersonalizedAds: !ref.read(consentGrantedProvider),
),
```
The service is currently NOT a Riverpod consumer — it's a plain singleton. Either (a) inject consent state via constructor/method args from the provider layer, or (b) refactor to read from a Riverpod ref via the `adMobServiceProvider` (planner picks; option a is less invasive).

---

### `lib/features/ads/presentation/widgets/banner_ad_widget.dart` (widget, request-response) — modify

**Analog:** `banner_ad_widget.dart` (self) — `_loadAd()` at lines 41–77.

**Current ad-gating pattern** (lines 41–46) — pattern to extend:
```dart
Future<void> _loadAd() async {
  final shouldShow = ref.read(shouldShowAdsProvider);
  if (!shouldShow) return;

  if (_isLoading) return;
  _isLoading = true;

  // Ensure AdMob is initialized
  await ref.read(adMobInitProvider.future);
  // ...
}
```
**Required modification** (per D-06, D-07): also gate on `umpConsentReadyProvider` (new) — do not load until UMP has resolved. Then read `consentGrantedProvider` and pass `npa=1` in the `AdRequest` (via the service's `loadBannerAd(adUnitId, size, nonPersonalizedAds: ...)` signature, which must be added).

**Render-gate pattern** (lines 81–86):
```dart
@override
Widget build(BuildContext context) {
  final shouldShow = ref.watch(shouldShowAdsProvider);

  if (!shouldShow || !_isLoaded || _bannerAd == null) {
    return const SizedBox.shrink();
  }
  // ...
}
```
Also watch `umpConsentReadyProvider` (new) here so the widget hides itself until consent is resolved. Do NOT block render forever if consent is "denied" — denial means `npa=1`, not "no ads".

---

### `lib/features/auth/presentation/widgets/forgot_password_dialog.dart` (widget, request-response) — modify

**Analog:** `forgot_password_dialog.dart` (self) — async logic at lines 27–38.

**Current async logic to EXTRACT** (lines 27–38) — moves into the new `ForgotPasswordController`:
```dart
void _handleSendResetEmail() async {
  if (_formKey.currentState?.validate() ?? false) {
    final authProvider = ref.read(supabaseAuthProvider);
    await authProvider.resetPassword(_emailController.text);

    if (authProvider.errorMessage == null) {
      setState(() {
        _emailSent = true;
      });
    }
  }
}
```
**Modification target** (per D-08): replace `_emailSent` local boolean and the direct `authProvider` call with a `ref.read(forgotPasswordControllerProvider.notifier).submit(email)` call, and `ref.watch(forgotPasswordControllerProvider)` to drive the UI states (idle, loading, success, error). Form validation stays in the widget (it's UI concern); state machine moves to the controller.

**Stable selectors for Maestro** (per D-14, D-15) — add `Key`s to:
- The `TextFormField` (line 150) → `Key('forgot_password_email_field')`
- The send button `PrimaryGlassButton` (line 237) → `Key('forgot_password_send_button')`
- The cancel `OutlinedButton` (line 215) → `Key('forgot_password_cancel_button')`
- The success state container (line 246–309) → `Key('forgot_password_success_state')`

Also add `Semantics(label: ...)` wrappers around action buttons so Maestro can locate them by accessibility text in the locale-agnostic way.

---

### `lib/features/auth/presentation/controllers/forgot_password_controller.dart` (controller, request-response) — NEW

**Analogs (hybrid — no perfect match):**
1. `lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart` — `StateNotifier` + immutable state class shape (preferred Riverpod pattern in this codebase for non-async state)
2. `lib/features/auth/data/providers/supabase_auth_provider.dart` — Supabase Auth call pattern + AuthException handling

**State class pattern** (from `qr_customization_controller.dart` lines 5–23) — apply for `ForgotPasswordState`:
```dart
class QRCustomizationState {
  final QRCustomization customization;
  final bool isPreviewMode;

  const QRCustomizationState({
    this.customization = const QRCustomization(),
    this.isPreviewMode = false,
  });

  QRCustomizationState copyWith({
    QRCustomization? customization,
    bool? isPreviewMode,
  }) {
    return QRCustomizationState(
      customization: customization ?? this.customization,
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
    );
  }
}
```
For `ForgotPasswordState`, fields should be `bool isLoading`, `bool emailSent`, `String? errorMessage` (or use sealed/AsyncValue per D-09 — planner decides).

**StateNotifier + provider pattern** (from `qr_customization_controller.dart` lines 25–32, 209–211):
```dart
class QRCustomizationController extends StateNotifier<QRCustomizationState> {
  QRCustomizationController() : super(const QRCustomizationState());

  void updateForegroundColor(Color color) {
    final customization = state.customization.copyWith(
      foregroundColor: _colorToInt(color),
    );
    state = state.copyWith(customization: customization);
  }
  // ...
}

final qrCustomizationControllerProvider = StateNotifierProvider<QRCustomizationController, QRCustomizationState>((ref) {
  return QRCustomizationController();
});
```

**Supabase + AuthException error handling pattern** (from `supabase_auth_provider.dart` lines 145–165):
```dart
Future<void> resetPassword(String email) async {
  try {
    _setLoading(true);
    _clearError();

    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'qraft://auth/reset',
    );
    debugPrint('Password reset email sent to: $email');

  } on AuthException catch (e) {
    debugPrint('Password reset error: ${e.message}');
    _setError('Password reset failed: ${e.message}');
  } catch (e) {
    debugPrint('Unexpected password reset error: $e');
    _setError('An unexpected error occurred');
  } finally {
    _setLoading(false);
  }
}
```
The new controller's `submit(email)` method should mirror this try/`on AuthException`/catch/finally structure exactly. Note: the controller can either re-call `_client.auth.resetPasswordForEmail(...)` directly (duplicating one Supabase call) or delegate to the existing `SupabaseAuthProvider.resetPassword()` and read its `errorMessage`. The latter has the race-condition pitfall flagged in CONCERNS.md — recommend direct call within the controller for testability.

**No AsyncNotifier example exists in the codebase.** If planner picks AsyncNotifier (Riverpod 2.x) per D-09, they will have no in-repo analog and must follow the official Riverpod docs pattern. This is a deliberate flag for the planner's decision matrix.

---

### `test/features/auth/presentation/controllers/forgot_password_controller_test.dart` (test) — NEW

**Analog:** `test/features/qr_generator/presentation/controllers/wifi_form_controller_test.dart`

**Test structure pattern** (lines 1–11):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/qr_generator/presentation/pages/wifi_qr_screen.dart';

void main() {
  group('WiFiFormController Tests', () {
    late WiFiFormController controller;

    setUp(() {
      controller = WiFiFormController();
    });
    // ...
```

**Validation + state assertion pattern** (lines 13–32):
```dart
group('Network Name Validation', () {
  test('validates empty network name', () {
    controller.updateNetworkName('');

    expect(controller.state.networkName, isEmpty);
    expect(controller.state.networkNameError, isNotNull);
    expect(controller.state.isValid, false);
  });
  // ...
});
```
For `ForgotPasswordController`, mirror this with `group('Email Submission')`, `group('State Transitions')`, `group('Error Handling')`. Cover: empty email rejected, valid email triggers loading→success transition, AuthException maps to errorMessage, network exception maps to generic error message.

**Mocktail Supabase mock pattern** (from `test/features/auth/data/providers/supabase_auth_provider_test.dart` lines 1–39):
```dart
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

setUpAll(() {
  registerFallbackValue(UserAttributes());
});

setUp(() {
  mockClient = MockSupabaseClient();
  mockAuth = MockGoTrueClient();
  when(() => mockClient.auth).thenReturn(mockAuth);
});
```
Use this exact mock structure to inject a fake Supabase client into the controller. The controller MUST accept the client via constructor for testability (do not use the static `SupabaseService.client` directly — that is the testability blocker from D-08).

---

### `test/features/auth/presentation/widgets/forgot_password_dialog_test.dart` (test) — modify

**Analog:** self (current 6 tests at lines 41–137).

**Existing widget test scaffold** (lines 26–39) — pattern to keep:
```dart
Widget createTestWidget() {
  return ProviderScope(
    overrides: [
      supabaseAuthProvider.overrideWith((ref) => mockAuthProvider),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: ForgotPasswordDialog(),
      ),
    ),
  );
}
```
**Modification** (per D-08, D-10): override `forgotPasswordControllerProvider` (new) instead of `supabaseAuthProvider`. Reduce widget tests to UI-only assertions (form renders, button visible, validates empty input). Move state-transition tests to the new controller test file. **Empirically count tests after refactor** — D-10 calls out a docs/code mismatch that must be reconciled (CONCERNS.md says 13 tests / 5 failing; file currently has 6 tests).

---

### `lib/features/consent/data/services/ump_service.dart` (service, event-driven) — NEW

**Analog:** `lib/features/ads/data/services/admob_service.dart`

**Singleton + idempotent init pattern** (admob_service.dart lines 8–30) — replicate:
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
```
**Adapt for UMP:** swap `MobileAds.instance.initialize()` for the UMP package's `ConsentInformation.requestConsentInfoUpdate()`, expose methods `isConsentRequired()`, `loadAndShowConsentForm()`, `getConsentStatus()` returning a `ConsentState` enum. Keep the singleton + idempotent init + try/catch + debugPrint shape.

---

### `lib/features/consent/presentation/providers/consent_providers.dart` (provider, event-driven) — NEW

**Analog:** `lib/features/ads/presentation/providers/ad_providers.dart`

**Provider declaration pattern** (ad_providers.dart lines 9–17):
```dart
final adMobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});

final adMobInitProvider = FutureProvider<void>((ref) async {
  final service = ref.read(adMobServiceProvider);
  await service.initialize();
});
```
**Adapt for UMP** — declare:
- `umpServiceProvider` → exposes `UmpService` singleton
- `umpInitProvider` → `FutureProvider<void>` that calls `requestConsentInfoUpdate`
- `consentStatusProvider` → derived `Provider<ConsentStatus>` reading from the service
- `consentGrantedProvider` → `Provider<bool>` for downstream `BannerAdWidget` to read
- `umpConsentReadyProvider` → `Provider<bool>` (true when init is complete, regardless of grant/deny)

**Computed-state pattern** (ad_providers.dart lines 19–24):
```dart
final shouldShowAdsProvider = Provider<bool>((ref) {
  return ref.watch(isFreeUserProvider);
});
```
Use this pattern for `consentGrantedProvider` and `umpConsentReadyProvider`.

---

### `lib/features/consent/presentation/screens/ump_consent_screen.dart` (screen, event-driven) — NEW

**Analog:** `lib/features/qr_generator/presentation/pages/text_qr_screen.dart` (ConsumerStatefulWidget skeleton)

**Screen skeleton pattern** (text_qr_screen.dart lines 23–60, 72–85):
```dart
class TextQRScreen extends ConsumerStatefulWidget {
  final QRCodeEntity? editingQRCode;

  const TextQRScreen({super.key, this.editingQRCode});

  @override
  ConsumerState<TextQRScreen> createState() => _TextQRScreenState();
}

class _TextQRScreenState extends ConsumerState<TextQRScreen>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger UMP form on first frame
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      // ...
```

**GlassButton usage for action buttons** (from `forgot_password_dialog.dart` line 237):
```dart
PrimaryGlassButton(
  text: l10n.sendResetLink,
  onPressed: _handleSendResetEmail,
  isLoading: isLoading,
),
```
The UMP screen's "Continue" / "Privacy Settings" actions should use `PrimaryGlassButton` from `lib/shared/widgets/glass_button.dart` for visual consistency. Note: the actual consent CHOICES (accept/deny) are rendered by Google's UMP form, NOT by us — our screen is a thin wrapper that triggers `loadAndShowConsentForm()` and shows a fallback CTA if the form fails to load (per D-04).

**Carden Pro background color** (text_qr_screen.dart line 73): `Color(0xFF1A1A1A)` — use this for the screen scaffold to match the app design system.

---

### `pubspec.yaml` (config) — modify

**Analog:** self.

**Current dep block organization pattern** (lines 30–96) — sections are commented and grouped. Preserve grouping:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  cupertino_icons: ^1.0.8

  # Internationalization
  intl: ^0.20.2

  # State Management
  flutter_riverpod: ^2.4.9

  # Backend Integration
  supabase_flutter: ^2.0.0

  # QR Functionality
  qr_flutter: ^4.1.0
  mobile_scanner: ^7.0.0
  # ...
```
**Required modifications** (per D-01, D-04, research SUMMARY):
1. SDK constraint at line 21: `sdk: ^3.6.2` → `sdk: ^3.29.0` (research note: mobile_scanner 7.x requires Flutter SDK ≥3.29).
2. `mobile_scanner: ^7.0.0` (line 51) → `mobile_scanner: ^7.2.0`.
3. Add 11 new deps grouped by purpose:
   - `# Firebase` block: `firebase_core`, `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics`
   - `# Ad Consent (UMP)` block: `google_user_messaging_platform`
   - `# Advanced QR Generation` block: `pretty_qr_code`, `screenshot`, `image`, `csv`
   - `# Forms` block: `flutter_form_builder`, `form_builder_validators`
   - `# Notifications` block: `flutter_local_notifications`

(Exact version bounds come from research/STACK.md. Planner picks ordering — D-09 / Claude's discretion #2.)

---

### `android/app/build.gradle.kts` (native-config) — modify

**Analog:** self (lines 1–9 plugins block).

**Current plugins block pattern** (lines 4–9):
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
```
**Required addition** (per D-01, D-02): append `id("com.google.gms.google-services")` to the plugins list. Also requires the Google services classpath in `android/build.gradle.kts` (root) — verify and add if missing.

**SDK config preservation** (lines 17–25): keep `compileSdk = flutter.compileSdkVersion` and JVM 11. No changes needed for Firebase Core (it ships its own AAR with min target 21, which is below our minSdk 23).

---

### `ios/Podfile` (native-config) — modify

**Analog:** self.

**Current platform pin** (line 2): `platform :ios, '13.0'` — keep at 13.0 (mobile_scanner 7.x minimum is iOS 13, Firebase iOS 11.0+ supports iOS 13).

**Current target block pattern** (lines 30–38) — pattern to preserve:
```ruby
target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end
```
**Required modification** (per D-01): Firebase pods are auto-installed by `flutter_install_all_ios_pods` once `firebase_core` is in pubspec — typically no manual pod entries needed. **Verify after `pod install --repo-update` that Firebase pods resolve cleanly.** If conflicts arise, may need explicit pinning.

**Existing post_install pattern** (lines 40–59) — preserve. The `permission_handler` config and `IPHONEOS_DEPLOYMENT_TARGET` deletion stay as-is.

---

### `android/app/google-services.json` (native-config) — NEW

**No analog in repo.**

This is a Firebase-issued asset. Download from Firebase Console → Project `qraft-e8a1d` → Android app `io.gothcorp.qraft`. Place at `android/app/google-services.json`. Verify `package_name` field matches `io.gothcorp.qraft` from `android/app/build.gradle.kts:42`. Reference: `.planning/codebase/STACK.md` line 156.

---

### `ios/Runner/GoogleService-Info.plist` (native-config) — NEW

**No analog in repo.**

This is a Firebase-issued asset. Download from Firebase Console → Project `qraft-e8a1d` → iOS app `io.gothcorp.qraft`. Place at `ios/Runner/GoogleService-Info.plist` and **add to Xcode project** (drag into the Runner target — this updates `ios/Runner.xcodeproj/project.pbxproj`). Verify `BUNDLE_ID` matches `io.gothcorp.qraft`.

---

### `.maestro/config.yaml` (e2e-config) — NEW

**No analog in repo.** Per D-14, D-17 — net-new foundation.

Reference: Maestro docs (https://maestro.mobile.dev/) accessed via `mcp__maestro__query_docs`. Standard Maestro project config exposes `appId` per platform and default device targets. Pin Maestro version 2.4.0+ in a comment or `.tool-versions` (D-17).

Expected shape (planner consults Maestro docs):
```yaml
# .maestro/config.yaml
appId: io.gothcorp.qraft
# Default platform-specific overrides if needed
```

---

### `.maestro/auth/login-valid.yaml` (e2e-flow) — NEW

**No flow analog in repo.** Maestro flows are net-new.

**Selectors must target widgets in:**
- `lib/features/auth/presentation/pages/auth_flow.dart` — login screen entry point
- Email field, password field, submit button — these widgets need stable `Key`s or `Semantics` labels added during the dialog refactor and any other auth widget touched.

**Pattern to apply (planner consults Maestro docs for syntax):**
```yaml
appId: io.gothcorp.qraft
---
- launchApp:
    clearState: true
- runFlow: ../helpers/dismiss-permissions.yaml
- tapOn:
    id: login_email_field
- inputText: test@qraft.dev
- tapOn:
    id: login_password_field
- inputText: ${MAESTRO_TEST_PASSWORD}
- tapOn:
    id: login_submit_button
- assertVisible:
    id: home_dashboard_root
```

**Reusability note (per D-15 #5):** This flow becomes a `runFlow:` target for Phases 2–12 — every later phase will start with `runFlow: ../auth/login-valid.yaml` to land in an authenticated state. Naming and selector stability matter long-term.

---

### `.maestro/launch/ump-accept.yaml` + `ump-deny-npa.yaml` (e2e-flow) — NEW

**No analog in repo.** Net-new. Selectors target the new `ump_consent_screen.dart`.

**Stable Keys to add to the new UMP screen** (mandatory for Maestro targetability):
- Screen root: `Key('ump_consent_screen_root')`
- Continue/accept CTA: `Key('ump_continue_button')`
- Manage settings link: `Key('ump_settings_link')`

**Important caveat:** the actual UMP form is rendered by Google's SDK (system overlay), NOT by our Flutter widgets. Maestro can interact with system dialogs via `tapOn: text:` matching the localized button text from Google's form. Document this in the flow YAML with comments and verify on both iOS simulator and Android emulator.

---

### `.maestro/scanner/scanner-tab-launch.yaml` (e2e-flow) — NEW

**No analog in repo.** Selectors target:
- `lib/features/main/main_scaffold.dart` — bottom nav tab for scanner
- `lib/features/qr_scanner/qr_scanner_screen.dart` — scanner UI root

Add stable `Key`s to the scanner tab icon/label and the scanner screen root before authoring this flow.

**Per D-15 #4:** Flow validates that `mobile_scanner` 7.2.0 boots on simulator/emulator without crash. Does NOT scan a real QR code (deferred to Phase 3 SCAN-02). Permission grant uses `helpers/dismiss-permissions.yaml`.

---

## Shared Patterns

### Riverpod Provider Declaration

**Source:** `lib/features/ads/presentation/providers/ad_providers.dart` (lines 9–24, 101–104)

**Apply to:** All new providers in `lib/features/consent/presentation/providers/consent_providers.dart` and `forgot_password_controller_provider`.

```dart
// Plain singleton provider (for services)
final adMobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});

// Async init provider (for one-shot initialization)
final adMobInitProvider = FutureProvider<void>((ref) async {
  final service = ref.read(adMobServiceProvider);
  await service.initialize();
});

// Derived/computed boolean provider (for downstream gating)
final shouldShowAdsProvider = Provider<bool>((ref) {
  return ref.watch(isFreeUserProvider);
});

// StateNotifier + state class
final adRewardProvider =
    StateNotifierProvider<AdRewardNotifier, List<AdReward>>((ref) {
  return AdRewardNotifier();
});
```

---

### Supabase + AuthException Error Handling

**Source:** `lib/features/auth/data/providers/supabase_auth_provider.dart` (lines 145–165)

**Apply to:** `ForgotPasswordController.submit()` and any new code touching Supabase Auth.

```dart
try {
  _setLoading(true);
  _clearError();

  await _client.auth.resetPasswordForEmail(
    email,
    redirectTo: 'qraft://auth/reset',
  );

} on AuthException catch (e) {
  debugPrint('Password reset error: ${e.message}');
  _setError('Password reset failed: ${e.message}');
} catch (e) {
  debugPrint('Unexpected password reset error: $e');
  _setError('An unexpected error occurred');
} finally {
  _setLoading(false);
}
```

---

### Singleton Service Pattern

**Source:** `lib/features/ads/data/services/admob_service.dart` (lines 8–30)

**Apply to:** `lib/features/consent/data/services/ump_service.dart`.

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

---

### Test File: Mocktail Setup

**Source:** `test/features/auth/data/providers/supabase_auth_provider_test.dart` (lines 1–39)

**Apply to:** `test/features/auth/presentation/controllers/forgot_password_controller_test.dart`.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  group('ForgotPasswordController Tests', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;

    setUpAll(() {
      registerFallbackValue(UserAttributes());
    });

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      when(() => mockClient.auth).thenReturn(mockAuth);
    });
    // ...
  });
}
```

---

### Test File: ProviderScope Override for Widget Tests

**Source:** `test/features/auth/presentation/widgets/forgot_password_dialog_test.dart` (lines 26–39)

**Apply to:** Refactored dialog test + any new widget tests for the UMP consent screen.

```dart
Widget createTestWidget() {
  return ProviderScope(
    overrides: [
      forgotPasswordControllerProvider.overrideWith((ref) => MockController()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: ForgotPasswordDialog(),
      ),
    ),
  );
}
```

---

### Glassmorphism UI for Auth/Consent Screens

**Source:** `lib/features/auth/presentation/widgets/forgot_password_dialog.dart` (lines 46–65, 237) + `lib/shared/widgets/glass_button.dart`

**Apply to:** UMP consent screen action buttons + any new auth-adjacent UI.

```dart
// Container with #2E2E2E + 24-radius + soft shadow (Carden Pro card)
Container(
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
  // ...
)

// Primary action button
PrimaryGlassButton(
  text: l10n.continueButton,
  onPressed: _handleContinue,
  isLoading: isLoading,
)
```

---

### Stable Keys for Maestro Targetability

**Source:** none currently — this is a new convention introduced by this phase.

**Apply to:** Every widget that a Maestro flow needs to interact with (form fields, action buttons, screen roots).

```dart
TextFormField(
  key: const Key('forgot_password_email_field'),
  // ...
),

PrimaryGlassButton(
  key: const Key('forgot_password_send_button'),
  text: l10n.sendResetLink,
  onPressed: _handleSendResetEmail,
),
```

Naming convention proposal (planner finalizes): `<feature>_<element>_<role>` — e.g., `login_email_field`, `ump_continue_button`, `scanner_tab_button`. Document in a `.maestro/CONVENTIONS.md` or in `.maestro/config.yaml` comments.

---

## No Analog Found

Files with no close match in the codebase (planner should rely on RESEARCH.md / external docs / package documentation):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `android/app/google-services.json` | native-config | n/a | Firebase-issued asset, not a code pattern |
| `ios/Runner/GoogleService-Info.plist` | native-config | n/a | Firebase-issued asset, not a code pattern |
| `.maestro/config.yaml` | e2e-config | n/a | No `.maestro/` directory exists in repo. Net-new. |
| `.maestro/helpers/login.yaml` | e2e-flow | n/a | No Maestro flows exist. Use Maestro docs / `mcp__maestro__query_docs`. |
| `.maestro/helpers/dismiss-permissions.yaml` | e2e-flow | n/a | Same as above. |
| `.maestro/auth/*.yaml` | e2e-flow | n/a | Same as above. Selectors target existing widgets but flow YAML structure is novel. |
| `.maestro/launch/*.yaml` | e2e-flow | n/a | Same as above. |
| `.maestro/scanner/scanner-tab-launch.yaml` | e2e-flow | n/a | Same as above. |
| `lib/features/consent/domain/entities/consent_state.dart` | model | n/a | Closest approximation is `qr_customization_controller.dart`'s state class — partial match. UMP-specific consent enum has no precedent. |

---

## Metadata

**Analog search scope:**
- `lib/main.dart`
- `lib/features/auth/` (controllers/, data/, presentation/)
- `lib/features/ads/` (data/services/, presentation/widgets/, presentation/providers/)
- `lib/features/qr_generator/presentation/controllers/`
- `lib/features/splash/`
- `lib/shared/widgets/`
- `lib/core/services/`, `lib/core/config/`
- `test/features/auth/`, `test/features/qr_generator/presentation/controllers/`
- `pubspec.yaml`, `android/app/build.gradle.kts`, `ios/Podfile`, `android/app/src/main/AndroidManifest.xml`

**Files scanned:** ~30 (incl. 6 directory listings)
**Pattern extraction date:** 2026-05-01

**Notable findings during mapping:**
1. The promised `auth_controller.dart` analog does not exist — `lib/features/auth/presentation/controllers/` is empty. The actual auth state holder is `SupabaseAuthProvider` (a `ChangeNotifier`). Closest StateNotifier examples are in `lib/features/qr_generator/presentation/controllers/`.
2. No AsyncNotifier (Riverpod 2.x) example exists anywhere in the codebase. If planner picks AsyncNotifier per D-09, they have no in-repo precedent — must follow official Riverpod docs.
3. The codebase uses `ChangeNotifierProvider` (auth) AND `StateNotifierProvider` (qr_generator) interchangeably. There is no consistent pattern. Planner can take this as freedom for D-09.
4. No `.maestro/` directory exists. This is the first phase introducing Maestro to the repo, confirming the "foundation" framing in CONTEXT.md.
5. `mobile_scanner: ^7.0.0` is currently installed (pubspec.yaml:51) — confirming the upgrade target ^7.2.0 from research SUMMARY.
6. Flutter SDK constraint is currently `^3.6.2` (pubspec.yaml:21) — must bump to `^3.29.0` per research SUMMARY.
7. The `forgot_password_dialog_test.dart` file has 6 tests, NOT 13 as docs claim (CONCERNS.md line 322, CLAUDE.md). D-10 already calls out reconciling this — flagged correctly.
