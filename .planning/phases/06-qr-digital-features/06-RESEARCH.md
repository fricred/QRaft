# Phase 6: QR Digital-Only Features — Research

**Researched:** 2026-05-03
**Domain:** Animated QR export, AI-stylized QR via Replicate API, home-screen widgets (iOS WidgetKit + Android Glance) via home_widget
**Confidence:** MEDIUM-HIGH (home_widget API verified via Context7 + pub.dev; AI provider cost/latency verified via Replicate.com; animated export stack is MEDIUM — render/screen_recorder are experimental)

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QRD-01 | Animated QR — GIF/MP4/Lottie export for digital sharing | `render` 0.1.4 (abandoned) → use `screen_recorder` 0.3.0 + `flutter_animate` for motion; or custom frame-capture loop with `image` package GIF encoder |
| QRD-02 | AI-stylized QR via Replicate/Stability with mandatory scannability gate before save | Replicate `zylim0702/qr_code_controlnet` REST API; ~$0.025/call, ~26s latency; scannability gate via `mobile_scanner` headless scan post-download |
| QRD-03 | Home-screen widgets iOS WidgetKit + Android Glance — show QR from user's library | `home_widget` 0.9.1 (verified active, verified pub.dev); `renderFlutterWidget` renders `PrettyQrView` → PNG → native widget reads path from shared storage |

</phase_requirements>

---

## Summary

Phase 6 builds three digital-only QR features. All three share a key constraint: they operate on the `digitalOnly` profile (QrProfile.digitalOnly) where `requiresDarkOnLight = false` and `requiresEcH = false`, relaxing the print-safe constraints enforced by the Phase 5 infrastructure — while still going through `QrDecorationBuilder` and `QrExportService` for consistency.

**QRD-01 (Animated QR):** There is no mature "Flutter QR animation → GIF file" package. The reliable path is: use `flutter_animate` (already installed) to drive a `CustomPainter` QR animation on a `RepaintBoundary`, then frame-capture to raw PNG frames using `screenshot` (already installed), then encode frames to GIF using the `image` package GIF encoder (already installed). This avoids adding new packages entirely. Export to GIF is slow on-device (>2s for 24 frames); show a progress indicator. MP4 export requires `ffmpeg_kit_flutter` or native platform calls and is deferred unless the user specifically requests it.

**QRD-02 (AI-stylized QR):** Replicate's `zylim0702/qr_code_controlnet` is the verified standard for AI QR stylization (~$0.025/call, ~26s). The critical gate: after downloading the AI-stylized image, run a headless `mobile_scanner` BarcodeCapture on the image bytes to verify the QR still decodes to the original URL before allowing save. If it fails, show a "style too strong — try different prompt" error. Block the `printSafe` profile from AI-styled QRs (already enforced by profile system).

**QRD-03 (Home-screen widget):** `home_widget` 0.9.1 is the standard. The key architectural insight: the QR image must be rendered via `HomeWidget.renderFlutterWidget(PrettyQrView(...), key: 'qr_widget_image', logicalSize: Size(300, 300))` — NOT by passing QR data as strings to native code, because the native widget cannot re-render a styled QR. The native sides (Swift WidgetKit + Kotlin Glance) read the rendered PNG path from shared storage (App Group on iOS, SharedPreferences on Android) and display it as an `Image`. Requires iOS App Group capability (Xcode provisioning) and a Widget Extension target in the Xcode project.

**Primary recommendation:** Use only packages already in pubspec.yaml for QRD-01 (flutter_animate + screenshot + image). Add `home_widget: ^0.9.1` for QRD-03 only. For QRD-02, use Dart `http` package (already available transitively) to call Replicate REST API — no SDK needed.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Animated QR frame capture | Frontend (isolate) | — | RepaintBoundary + screenshot in compute(); image package GIF encoder |
| GIF file save + share | Frontend (Flutter) | — | share_plus (already installed) handles share sheet |
| AI QR API call | Frontend → API | — | Replicate REST; Flutter http client; secret API key must be in Supabase Edge Function or env var |
| Post-AI scannability gate | Frontend (domain) | — | mobile_scanner headless BarcodeCapture on downloaded image bytes |
| Widget QR render to PNG | Frontend (Flutter) | — | HomeWidget.renderFlutterWidget; app must be foregrounded or in background (not killed) |
| Widget native display (iOS) | iOS WidgetKit (Swift) | — | SwiftUI reads PNG path from UserDefaults(suiteName:) |
| Widget native display (Android) | Android Glance (Kotlin) | — | GlanceAppWidget reads PNG path from SharedPreferences via HomeWidgetGlanceStateDefinition |
| Widget data refresh | Frontend (Flutter) | — | HomeWidget.updateWidget() triggers native widget timeline refresh |

---

## Standard Stack

### Core — already installed (verified pubspec.yaml)

| Library | Version | Purpose | Reuse from Phase 5 |
|---------|---------|---------|-------------------|
| `flutter_animate` | ^4.3.0 | Drive QR animation (fade, scale, rotate on modules) | Yes — already installed |
| `screenshot` | ^3.0.0 | Capture RepaintBoundary frames as PNG bytes | Yes — QrExportService uses it |
| `image` | ^4.5.4 | Encode PNG frame sequence to GIF (GifEncoder) | Yes — already installed |
| `share_plus` | ^10.0.0 | Share GIF/PNG file from app | Yes — already installed |
| `pretty_qr_code` | ^3.6.0 | QR widget for renderFlutterWidget | Yes — Phase 5 core |
| `mobile_scanner` | ^7.2.0 | Headless scannability gate for QRD-02 | Yes — Phase 3 scanner |

### New dependency — QRD-03 only

| Library | Version | Purpose | Why |
|---------|---------|---------|-----|
| `home_widget` | ^0.9.1 | Unified Flutter API for iOS WidgetKit + Android Glance | Only package with active maintenance (0.9.1, 20 days ago), verified publisher, renderFlutterWidget support |

### Packages evaluated and rejected

| Package | Version | Reason Rejected |
|---------|---------|----------------|
| `render` | 0.1.4 | Last published 23 months ago; unmaintained; requires FFmpeg; only Android+iOS+macOS |
| `screen_recorder` | 0.3.0 | "Highly experimental, API subject to change"; GIF encoding extremely slow; 21 months since last update |
| Stability AI Direct SDK | — | No dedicated QR ControlNet model; Replicate has `zylim0702/qr_code_controlnet` purpose-built |
| `fal_client` | — | Lower latency but no QR-specific ControlNet model available [ASSUMED] |

**Installation — QRD-03 only:**
```bash
flutter pub add home_widget
```

**Version verification (run before plan execution):**
```bash
dart pub search home_widget | head -3
# Expected: home_widget 0.9.1
```

---

## Architecture Patterns

### System Architecture — Phase 6 Data Flow

```
User selects QR from library
        |
        v
QrDigitalFeaturesController (Riverpod StateNotifier)
        |
   +----+----+
   |         |
   v         v
QRD-01     QRD-02                    QRD-03
Animate     AI Stylize               Widget Pin
   |              |                      |
   v              v                      v
flutter_animate  Replicate REST       HomeWidget
on PrettyQrView  (via Supabase EF     .renderFlutterWidget
                  or env key)          (PrettyQrView)
   |              |                      |
   v              v                      v
screenshot      Download image PNG   PNG path saved
frame loop      (bytes)                 to SharedPrefs /
   |              |                   UserDefaults
   v              v                      |
image.GifEncoder  mobile_scanner         v
(encode frames)   headless scan     HomeWidget.updateWidget()
   |              |                      |
   v              v                      v
Save GIF to    PASS → save to       iOS WidgetKit (Swift)
temp dir       Supabase Storage     OR Android Glance (Kotlin)
   |           FAIL → show error    reads PNG path → displays
   v
share_plus
share sheet
```

### Recommended Project Structure additions

```
lib/features/qr_digital/
├── domain/
│   ├── services/
│   │   ├── qr_animation_service.dart      # QRD-01: frame capture + GIF encode
│   │   ├── qr_ai_style_service.dart       # QRD-02: Replicate API call + scannability gate
│   │   └── qr_widget_service.dart         # QRD-03: HomeWidget save/render/update
│   └── entities/
│       └── qr_ai_style_result.dart        # holds image bytes + scan_ok bool
├── presentation/
│   ├── pages/
│   │   ├── qr_animate_page.dart
│   │   ├── qr_ai_style_page.dart
│   │   └── qr_widget_pin_page.dart
│   └── controllers/
│       └── qr_digital_controller.dart     # single StateNotifier for all 3
ios/
└── QRaftWidgetExtension/                  # New Xcode Widget Extension target
    ├── QRaftWidget.swift                  # SwiftUI WidgetKit entry
    └── QRaftWidgetBundle.swift
android/app/src/main/
└── kotlin/.../
    ├── QrWidget.kt                        # GlanceAppWidget implementation
    └── QrWidgetReceiver.kt                # HomeWidgetGlanceWidgetReceiver
```

### Pattern 1: QRD-01 — Animated QR via Frame Capture + GIF Encode

**What:** Animate PrettyQrView using flutter_animate, capture N frames via screenshot package, encode with image package GifEncoder.
**When to use:** User taps "Animate" on a digitalOnly-profile QR.

```dart
// Source: image package GifEncoder API [VERIFIED: pub.dev/packages/image]
// + screenshot package RepaintBoundary [VERIFIED: pub.dev/packages/screenshot]

Future<Uint8List> encodeQrGif(
  QrImage qrImage,
  PrettyQrDecoration decoration, {
  int frameCount = 12,
  int frameDelayMs = 100,
}) async {
  final animation = img.Animation();
  for (int i = 0; i < frameCount; i++) {
    final t = i / frameCount; // 0.0 → 1.0
    // Apply per-frame decoration mutation (e.g., opacity pulse, scale)
    final frameDeco = decoration.copyWith(
      // Example: pulse foreground opacity
    );
    final pngBytes = await QrExportService.exportPrintSafe(qrImage, frameDeco);
    final frame = img.decodePng(pngBytes)!;
    frame.frameDuration = frameDelayMs;
    animation.addFrame(frame);
  }
  return Uint8List.fromList(img.encodeGif(animation));
}
```

**Performance note:** GIF encoding 12 frames at 400×400px takes ~1-3s on a mid-range device. Run in `compute()` isolate. Show CircularProgressIndicator. Warn: 24-frame GIF at 2160px resolution will OOM — cap at 400px for GIF, 2160px only for static PNG export.

### Pattern 2: QRD-02 — AI Stylization via Replicate + Scannability Gate

**What:** POST to Replicate API, poll for result, download image, verify QR is still scannable.
**When to use:** User selects digitalOnly profile QR and taps "AI Style."

```dart
// Source: Replicate REST API [VERIFIED: replicate.com/zylim0702/qr_code_controlnet]
// API key must come from environment (--dart-define-from-file=env.json)
// NEVER hardcode in client code.

class QrAiStyleService {
  static const _model = 'zylim0702/qr_code_controlnet';

  Future<QrAiStyleResult> stylize({
    required String qrDataUrl,  // URL to base QR PNG (Supabase Storage)
    required String prompt,
    required String apiKey,     // from String.fromEnvironment('REPLICATE_API_KEY')
  }) async {
    // 1. Create prediction
    final createResp = await http.post(
      Uri.parse('https://api.replicate.com/v1/models/$_model/predictions'),
      headers: {'Authorization': 'Token $apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({'input': {'qr_code_content': qrDataUrl, 'prompt': prompt}}),
    );
    final predictionId = jsonDecode(createResp.body)['id'];

    // 2. Poll for completion (p50 ~26s)
    String? outputUrl;
    while (outputUrl == null) {
      await Future.delayed(const Duration(seconds: 3));
      final pollResp = await http.get(
        Uri.parse('https://api.replicate.com/v1/predictions/$predictionId'),
        headers: {'Authorization': 'Token $apiKey'},
      );
      final status = jsonDecode(pollResp.body)['status'];
      if (status == 'succeeded') {
        outputUrl = jsonDecode(pollResp.body)['output'][0];
      } else if (status == 'failed') throw Exception('replicate_failed');
    }

    // 3. Download image bytes
    final imageBytes = (await http.get(Uri.parse(outputUrl))).bodyBytes;

    // 4. MANDATORY scannability gate — mobile_scanner headless scan
    final scanResult = await BarcodeCapture.fromImageBytes(imageBytes); // [ASSUMED API]
    return QrAiStyleResult(
      imageBytes: imageBytes,
      scanOk: scanResult.barcodes.isNotEmpty,
    );
  }
}
```

**Critical:** API key must not be embedded in the Flutter app binary. Either use a Supabase Edge Function as a proxy (recommended for production — adds ~200ms but hides key), or use `--dart-define-from-file` env var (acceptable for beta). Never commit `REPLICATE_API_KEY` to git.

**Cost model:** $0.025/call. At 100 AI styles/day = $2.50/day = ~$75/month. Gate behind a freemium limit (e.g., 5 AI styles/month free, unlimited for premium) using RevenueCat entitlement check before calling API.

### Pattern 3: QRD-03 — Home Widget via home_widget 0.9.1

**What:** Render PrettyQrView to PNG, store path, trigger native widget refresh.
**iOS:** SwiftUI Widget Extension reads PNG from UserDefaults(suiteName: appGroup).
**Android:** GlanceAppWidget reads PNG from SharedPreferences via HomeWidgetGlanceStateDefinition.

```dart
// Source: home_widget 0.9.1 API [VERIFIED: Context7 /abausg/home_widget]

class QrWidgetService {
  static const _appGroupId = 'group.io.gothcorp.qraft'; // Must match Xcode capability

  static Future<void> pinQrToWidget(QrImage qrImage, PrettyQrDecoration deco) async {
    await HomeWidget.setAppGroupId(_appGroupId); // iOS only; no-op on Android

    // Render Flutter QR widget to PNG and store path under key 'qr_widget_image'
    await HomeWidget.renderFlutterWidget(
      PrettyQrView.data(
        data: '', // data comes via QrImage; use PrettyQrView with qrImage param
        decoration: deco,
      ),
      key: 'qr_widget_image',
      logicalSize: const Size(300, 300), // Keep ≤300px — iOS WidgetKit memory limit ~30MB
    );

    // Save display metadata
    await HomeWidget.saveWidgetData<String>('qr_label', 'My QR');
    await HomeWidget.saveWidgetData<int>(
        'updated_at', DateTime.now().millisecondsSinceEpoch);

    // Trigger native widget refresh
    await HomeWidget.updateWidget(
      iOSName: 'QRaftWidget',         // must match Widget `kind` in Swift
      androidName: 'QrWidgetReceiver', // must match receiver class name
    );
  }
}
```

**iOS Xcode setup required (not automatable from Flutter):**
1. Add Widget Extension target in Xcode (File > New > Target > Widget Extension).
2. Add App Group capability to both Runner and Widget Extension (`group.io.gothcorp.qraft`).
3. Swift widget reads: `UserDefaults(suiteName: "group.io.gothcorp.qraft")?.string(forKey: "qr_widget_image")` → display as `Image(uiImage: UIImage(contentsOfFile: path))`.

**Android Gradle addition:**
```groovy
// android/app/build.gradle
implementation 'androidx.glance:glance-appwidget:1.1.1'
```

### Anti-Patterns to Avoid

- **Passing QR data strings to native widget and re-rendering natively**: Native WidgetKit/Glance cannot use `pretty_qr_code`. Always pre-render to PNG via `renderFlutterWidget`.
- **Requesting `renderFlutterWidget` when app is killed**: Only works with app foregrounded or in background. Show an in-app prompt to trigger widget pin; do not schedule background renders.
- **Using full 2160px for GIF frames**: Will OOM. Cap GIF at 400×400px. 2160px only for static PNG.
- **Calling Replicate directly from client in production with embedded API key**: Key will be extracted from app binary. Use Edge Function proxy.
- **Skipping scannability gate on AI-stylized QR**: 20-30% of AI outputs fail to scan (REQUIREMENTS.md notes ~10-15% post-engraving). Block save if `scanOk == false`.
- **Allowing AI-stylized QR on printSafe or tattooSafe profile**: REQUIREMENTS.md explicitly bans this. `QrProfile.digitalOnly` only.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GIF encoding | Custom GIF bit-packer | `image` package `GifEncoder` | LZW compression, palette quantization, disposal modes — edge cases are severe |
| Home widget data bridge | Custom platform channel | `home_widget` 0.9.1 | App Group provisioning, UserDefaults scoping, Glance state sync — already solved |
| AI image generation | Fine-tune SD locally | Replicate hosted `qr_code_controlnet` | GPU provisioning, model weights, ControlNet conditioning — months of infra work |
| Scannability validation | Pixel luminance heuristic | `mobile_scanner` BarcodeCapture on bytes | Scanner library already in project; luminance heuristics have high false-positive rate |

---

## How digitalOnly Profile Differs from printSafe

Verified from `lib/features/qr_generator/domain/value_objects/qr_profile.dart` [VERIFIED: codebase grep]:

| Constraint | printSafe | digitalOnly | tattooSafe |
|------------|-----------|-------------|------------|
| `requiresDarkOnLight` | `true` | **`false`** | `true` |
| `requiresEcH` | `true` | **`false`** | `true` |
| `maxLogoScale` | 0.20 | 0.20 | 0.15 |

For Phase 6, this means:
- AI-stylized QRs may have inverted colors, dark backgrounds, complex patterns — allowed because `requiresDarkOnLight = false`.
- EC level is caller-controlled (default M from QRCustomization) — the AI model internally handles QR scannability.
- Scannability validation replaces the structural EC-H guarantee.
- **Animated QRs must still encode a valid QR** — the animation is visual effect only; the underlying `QrImage` data is unchanged.

---

## Phase 5 Infrastructure Reused

All of the following exist and are fully reusable [VERIFIED: codebase read]:

| Service/Class | File | Reuse in Phase 6 |
|---------------|------|-----------------|
| `QrExportService.exportPrintSafe` | `domain/services/qr_export_service.dart` | Frame capture for GIF (override background for digitalOnly) |
| `QrDecorationBuilder.buildDecoration` | `domain/services/qr_decoration_builder.dart` | Build decoration for renderFlutterWidget |
| `QrDecorationBuilder.buildQrImage` | `domain/services/qr_decoration_builder.dart` | Construct QrImage for all digital features |
| `QrProfile.digitalOnly` | `domain/value_objects/qr_profile.dart` | Profile validation (no dark-on-light, no EC-H forced) |
| `QrProfileValidator.validate` | `domain/services/qr_profile_validator.dart` | Validate logo cap before AI stylization |
| `QRCustomization` entity | `domain/entities/qr_code_entity.dart` | Read profile=1 (digitalOnly) before enabling QRD-01/02/03 |

**Important:** `QrExportService.exportPrintSafe` hardcodes `background: Colors.white`. For digitalOnly animated QRs, build a `exportDigitalOnly` variant that does NOT force white background — allowing dark backgrounds for animated effects.

---

## Common Pitfalls

### Pitfall 1: iOS Widget Extension App Group Misconfiguration
**What goes wrong:** `HomeWidget.renderFlutterWidget` succeeds, but widget shows blank image. Widget reads from wrong UserDefaults suite — App Group ID mismatch between Runner and Widget Extension targets.
**Why it happens:** App Group must be added to both targets in Xcode manually; Flutter tooling cannot do this.
**How to avoid:** Verify App Group capability enabled in Xcode for BOTH targets. `UserDefaults(suiteName: "group.io.gothcorp.qraft")` must match `HomeWidget.setAppGroupId('group.io.gothcorp.qraft')`.
**Warning signs:** Widget shows placeholder, not the rendered PNG. No crash — just empty data.

### Pitfall 2: renderFlutterWidget Size > 300px Causes iOS Memory Crash
**What goes wrong:** WidgetKit has ~30MB memory budget. Rendering at 600×600px can crash widget extension with `EXC_RESOURCE RESOURCE_TYPE_MEMORY`.
**Why it happens:** iOS Widget extensions have strict memory budgets separate from the main app.
**How to avoid:** Cap `logicalSize` at `Size(300, 300)` for widget renders. This is sufficient for all widget size families (systemSmall through systemLarge).
**Warning signs:** Widget crashes on launch on physical device (not simulator). Thread 1: EXC_RESOURCE.

### Pitfall 3: AI Scannability Gate Not Applied Before Save
**What goes wrong:** AI-stylized QR looks great but doesn't scan. User orders business cards (outside QRaft) or shares the QR digitally; recipient cannot scan it.
**Why it happens:** AI ControlNet output quality varies by prompt; high `controlnet_conditioning_scale` makes it more scannable but less artistic.
**How to avoid:** Gate is mandatory — `QrAiStyleResult.scanOk` must be `true` before save button enables. Show "Retry with different prompt" error when false.
**Warning signs:** User support tickets "QR code doesn't work" on AI-styled QRs.

### Pitfall 4: GIF Encoding Blocking Main Thread
**What goes wrong:** App freezes for 3-8s during GIF encoding.
**Why it happens:** `img.encodeGif()` is CPU-intensive; if called on main isolate, blocks UI.
**How to avoid:** Always call encoding in `compute()` isolate. Show progress indicator.
**Warning signs:** App ANR on Android (>5s main thread block), UI unresponsive on iOS.

### Pitfall 5: Replicate API Key Visible in App Bundle
**What goes wrong:** API key extracted via `strings` on the .ipa — attacker makes unlimited Replicate calls at QRaft's cost.
**Why it happens:** `String.fromEnvironment('REPLICATE_API_KEY')` with `--dart-define-from-file` bakes the key into the Dart snapshot.
**How to avoid (production path):** Create a Supabase Edge Function `generate-ai-qr` that holds the Replicate key server-side. Flutter calls the Edge Function with the authenticated user JWT. Rate-limit per user per day.
**How to avoid (beta/dev path):** Use `--dart-define-from-file` with `.gitignore`d `env.json`. Acceptable if beta users are internal/trusted only.
**Warning signs:** Unexpectedly high Replicate usage charges.

---

## Code Examples

### GIF Frame Capture with image Package
```dart
// Source: image package 4.5.4 GifEncoder API [VERIFIED: pub.dev/packages/image]
import 'package:image/image.dart' as img;

Future<Uint8List> buildQrGif(List<Uint8List> pngFrames, {int delayMs = 100}) {
  return compute((List<Uint8List> frames) {
    final animation = img.Animation()
      ..loopCount = 0; // infinite loop
    for (final pngBytes in frames) {
      final frame = img.decodePng(pngBytes)!;
      frame.frameDuration = delayMs;
      animation.addFrame(frame);
    }
    return Uint8List.fromList(img.encodeGif(animation));
  }, pngFrames);
}
```

### iOS SwiftUI Widget Display
```swift
// Source: home_widget Context7 docs [VERIFIED: /abausg/home_widget]
struct QRaftWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        if let imagePath = entry.imagePath,
           let uiImage = UIImage(contentsOfFile: imagePath) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(8)
        } else {
            Text("Open QRaft to pin a QR")
                .font(.caption)
        }
    }
}
```

### Android Glance Widget Display
```kotlin
// Source: home_widget Context7 docs [VERIFIED: /abausg/home_widget]
class QrWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<HomeWidgetGlanceState>().preferences
            val imagePath = prefs.getString("qr_widget_image", null)
            if (imagePath != null) {
                val bitmap = BitmapFactory.decodeFile(imagePath)
                Image(
                    provider = ImageProvider(bitmap),
                    contentDescription = "QR Code",
                    modifier = GlanceModifier.fillMaxSize().padding(8.dp)
                )
            } else {
                Text("Open QRaft to pin a QR")
            }
        }
    }
}
```

---

## Environment Availability

| Dependency | Required By | Available | Version | Notes |
|------------|------------|-----------|---------|-------|
| Flutter SDK | All | ✓ | >=3.29.0 (pubspec) | home_widget 0.9.1 requires Flutter 3.x — satisfied |
| Xcode (Widget Extension) | QRD-03 iOS | ✓ (macOS dev machine) | 26 (per search results) | Swift Package Manager support added in home_widget 0.9.0 |
| Android Studio / Gradle | QRD-03 Android | ✓ | — | glance-appwidget:1.1.1 added to build.gradle |
| Replicate API account | QRD-02 | Must provision | — | ~$0.025/call; requires API key |
| App Group (iOS provisioning) | QRD-03 | Must configure | — | Via Xcode + Apple Developer Portal; cannot be scripted |

**Blocking items (require human action before coding):**
1. Create Replicate API account + generate API key → add to `env.json` as `REPLICATE_API_KEY`.
2. Configure iOS App Group `group.io.gothcorp.qraft` in Apple Developer Portal + Xcode.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) + mocktail |
| Config file | analysis_options.yaml |
| Quick run command | `flutter test test/features/qr_digital/ -x` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QRD-01 | GIF encoder produces non-empty bytes from frame list | unit | `flutter test test/features/qr_digital/services/qr_animation_service_test.dart -x` | ❌ Wave 0 |
| QRD-01 | Frame capture returns correct PNG dimensions | unit | same file | ❌ Wave 0 |
| QRD-02 | Scannability gate returns scanOk=false for blank image | unit | `flutter test test/features/qr_digital/services/qr_ai_style_service_test.dart -x` | ❌ Wave 0 |
| QRD-02 | Replicate API call is correctly structured (mock) | unit | same file | ❌ Wave 0 |
| QRD-03 | Widget service calls HomeWidget.saveWidgetData + updateWidget | unit (mocked) | `flutter test test/features/qr_digital/services/qr_widget_service_test.dart -x` | ❌ Wave 0 |
| QRD-03 | Profile guard: printSafe QR cannot be pinned with AI style | unit | same file | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/qr_digital/ -x`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/features/qr_digital/services/qr_animation_service_test.dart` — covers QRD-01
- [ ] `test/features/qr_digital/services/qr_ai_style_service_test.dart` — covers QRD-02 (mock Replicate HTTP)
- [ ] `test/features/qr_digital/services/qr_widget_service_test.dart` — covers QRD-03 (mock HomeWidget)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No — uses existing Supabase session | — |
| V4 Access Control | Yes — AI style must check premium entitlement before calling API | RevenueCat entitlement check before Replicate call |
| V5 Input Validation | Yes — AI prompt injection risk | Sanitize user prompt: strip control chars, max 200 chars, block prompt injection patterns |
| V6 Cryptography | No — no new crypto | — |
| API Key Exposure | Yes — Replicate key | Edge Function proxy in production; env.json only for dev/beta |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Replicate API key extraction from app binary | Information Disclosure | Supabase Edge Function proxy for production; env var for beta |
| Prompt injection in AI style prompt | Tampering | Max 200 chars, regex strip, server-side prompt wrapper |
| Unlimited AI API calls per user (DoS by cost) | Denial of Service | Rate-limit: 5 AI styles/month free, check RevenueCat entitlement |
| Malicious image bytes from Replicate response | Spoofing | Only process Replicate-hosted image URLs (replicate.delivery domain whitelist) |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mobile_scanner` exposes `BarcodeCapture.fromImageBytes()` for headless scan of arbitrary PNG bytes | QRD-02 scannability gate pattern | If API doesn't exist, scannability gate must use a different approach (e.g., write bytes to temp file + scan via camera) — additional complexity |
| A2 | `fal.ai` has no purpose-built QR ControlNet model | Standard Stack alternatives | If fal has a faster QR model, it would be preferable due to lower latency (~2-4s vs 26s) |
| A3 | Replicate `zylim0702/qr_code_controlnet` still operational under Cloudflare ownership | QRD-02 | If model is deprecated, need to find alternative (Stability AI ControlNet endpoint or self-hosted) |
| A4 | `androidx.glance:glance-appwidget` version 1.1.1 is current stable | Android setup | Check before implementation: `implementation 'androidx.glance:glance-appwidget:LATEST'` |

**A1 is the highest-risk assumption.** Verify before writing `QrAiStyleService`. If `BarcodeCapture.fromImageBytes` does not exist in mobile_scanner 7.2.0, the fallback is: save image bytes to a temp file → use `mobile_scanner`'s `analyzeImage(path)` method which does exist.

---

## Open Questions

1. **Replicate API key storage for production**
   - What we know: `--dart-define-from-file` bakes key into binary (extractable). Edge Function proxy is more secure.
   - What's unclear: Is QRD-02 launching in beta (key in env.json acceptable) or GA (must use proxy)?
   - Recommendation: Default to Edge Function proxy. If beta-only, document risk and use env var.

2. **AI style freemium gate**
   - What we know: $0.025/call; RevenueCat already installed for premium gating.
   - What's unclear: How many free AI styles per month? Is this a premium-only feature?
   - Recommendation: 5 free AI styles/month; unlimited for premium tier. If premium tier not yet launched (it's Phase 12), gate behind feature flag that defaults to 5/month.

3. **GIF vs MP4 — which formats to ship in v1?**
   - What we know: GIF works with existing `image` package. MP4 requires `ffmpeg_kit_flutter` (large binary, ~10MB APK increase) or native platform code.
   - What's unclear: Does the user actually need MP4, or is GIF sufficient for digital sharing (WhatsApp, Instagram, etc.)?
   - Recommendation: Ship GIF only in Phase 6. Add MP4 in v2 if user demand justifies `ffmpeg_kit_flutter` dependency.

4. **mobile_scanner headless scan API**
   - What we know: mobile_scanner 7.2.0 is installed; has `analyzeImage(String path)` for file-based scan.
   - What's unclear: Does it support in-memory bytes scan without writing to disk first?
   - Recommendation: Use `analyzeImage(path)` — write AI image to temp file, scan, delete. Slightly slower but definitively supported.

---

## Sources

### Primary (HIGH confidence)
- [VERIFIED: Context7 /abausg/home_widget] — saveWidgetData, renderFlutterWidget, setAppGroupId, updateWidget API, iOS SwiftUI pattern, Android Glance pattern
- [VERIFIED: pub.dev/packages/home_widget] — version 0.9.1, published 20 days ago, active maintenance, breaking changes in 0.9.0
- [VERIFIED: pub.dev/packages/home_widget/changelog] — 0.9.1 adds saveFile/saveImage, 0.9.0 adds Swift Package Manager support
- [VERIFIED: codebase] — QrProfile.digitalOnly constraints, QrExportService, QrDecorationBuilder, QRCustomization entity, pubspec.yaml installed packages
- [VERIFIED: replicate.com/zylim0702/qr_code_controlnet] — ~$0.025/call, ~26s latency, ControlNet QR model
- [VERIFIED: pub.dev/packages/image] — GifEncoder, img.Animation, encodeGif API exists in image 4.x
- [VERIFIED: pub.dev/packages/render] — version 0.1.4, 23 months stale, rejected
- [VERIFIED: pub.dev/packages/screen_recorder] — version 0.3.0, "highly experimental", 21 months stale, rejected

### Secondary (MEDIUM confidence)
- [CITED: github.com/ABausG/home_widget/issues/178] — Image.asset rendering issue with renderFlutterWidget (workaround: use PrettyQrView which uses canvas, not Image.asset)
- [CITED: github.com/ABausG/home_widget/issues/170] — renderFlutterWidget blocked in interactivity callbacks
- [CITED: apple developer forums] — iOS Widget memory limit ~30MB; 1200×1200px image crashes widget
- [CITED: pub.dev/packages/lottie] — version 3.3.3, 22 days ago; plays After Effects JSON; cannot generate QR data dynamically

### Tertiary (LOW confidence — ASSUMED)
- A1: mobile_scanner headless bytes scan API existence — [ASSUMED from API design patterns; verify against mobile_scanner source before implementing]
- A2: fal.ai no QR ControlNet model — [ASSUMED; not verified in this session]
- A3: Replicate model still operational post-Cloudflare acquisition — [ASSUMED; search result mentioned acquisition but model page was live at research time]

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on Phase 6 |
|-----------|------------------|
| State management: Riverpod only | `QrDigitalController` must be Riverpod `StateNotifier`; no BLoC |
| Firebase Auth + Supabase | Supabase Storage for AI result images; no new auth stack |
| `--dart-define-from-file=env.json` | Replicate API key in env.json; never hardcoded |
| `flutter analyze` must pass | No dynamic casts; explicit types in all service classes |
| `flutter test` must pass | Unit tests for all three services before commit |
| Design system: Carden Pro (#1A1A1A, #00FF88, glassmorphism) | Animation effects use neon accent; AI style result card uses dark card + glassmorphism overlay |
| iOS target: io.gothcorp.qraft | App Group: `group.io.gothcorp.qraft` |

---

## Metadata

**Confidence breakdown:**
- Standard stack (home_widget, image GifEncoder, Replicate): HIGH — all verified via pub.dev + Context7 + official site
- Architecture patterns: HIGH — based on verified APIs
- AI provider recommendation: MEDIUM — cost/latency verified, but mobile_scanner headless scan API assumed
- Pitfalls: MEDIUM-HIGH — iOS memory limits and App Group issues cited from real GitHub issues

**Research date:** 2026-05-03
**Valid until:** 2026-06-03 (home_widget is fast-moving; re-check changelog before implementation)
