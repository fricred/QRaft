# Technology Stack

**Analysis Date:** 2026-05-01

## Languages

**Primary:**
- **Dart** 3.6.2+ - Cross-platform application logic and UI rendering
- **Kotlin** 11 (Java 11 target) - Android native code in `android/app/build.gradle.kts`
- **Swift** - iOS native code and AppDelegate configuration in `ios/Runner/AppDelegate.swift`

**Secondary:**
- **XML** - Android manifest configuration in `android/app/src/main/AndroidManifest.xml`
- **JavaScript** - Web platform bootstrap in `web/index.html` and Flutter Bootstrap
- **SQL** - Supabase database migrations in `supabase/migrations/`

## Runtime

**Environment:**
- **Flutter SDK** 3.6.2+ - Cross-platform application framework
- **Dart VM** - Native runtime for Dart code execution
- **Flutter Web Engine** - Chromium-based web rendering

**Package Manager:**
- **Pub** (Flutter's package manager) - Integrated with Flutter SDK
- **Lockfile:** `pubspec.lock` (present, tracks exact dependency versions)

## Frameworks

**Core:**
- **Flutter** 3.6.2+ - Cross-platform UI framework for iOS, Android, Web, macOS, Windows, Linux
- **Riverpod** 2.4.9 - State management and dependency injection provider pattern
- **Supabase Flutter** 2.0.0 - Backend-as-a-service with PostgreSQL, Auth, and Storage

**UI & Styling:**
- **Material Design 3** - Material Design system for consistent UI
- **Flutter Animate** 4.3.0 - Advanced animation library for Carden Pro design system
- **Glassmorphism** 3.0.0 - Glassmorphism effects (blur, transparency)
- **Shimmer** 3.0.0 - Loading shimmer animations

**QR Functionality:**
- **QR Flutter** 4.1.0 - QR code generation (renders as Widget)
- **Mobile Scanner** 7.0.0 - Camera-based QR code scanning (active scanning)

**Navigation:**
- **Go Router** 13.0.0 - Type-safe declarative routing and deep linking

**Graphics & Media:**
- **Flutter SVG** 2.0.9 - SVG rendering (custom logo and icons)
- **Cached Network Image** 3.3.0 - Network image caching and display
- **Image Picker** 1.0.7 - User device image selection
- **Crop Your Image** 2.0.0 - Image cropping functionality

**Platform Integration:**
- **Webview Flutter** 4.13.1 - WebView embedding for web content (in-app browser)
- **Google Mobile Ads** 5.1.0 - Google AdMob integration for ads (Android: `ca-app-pub-5118672998`, iOS: `ca-app-pub-9213497138890427~5118672998`)
- **Purchases Flutter** 8.1.0 - RevenueCat SDK for in-app purchases and subscriptions

**Utilities:**
- **URL Launcher** 6.2.4 - Open URLs and mail/phone intents
- **Share Plus** 10.0.0 - Multi-platform sharing functionality
- **Geolocator** 13.0.0 - Location services (GPS coordinates for location QR)
- **Flutter Map** 7.0.0 - Map rendering for location-based features
- **Flutter Contacts** 1.1.9 - Contact/email access for contact QR generation
- **Phone Form Field** 10.0.8 - Phone number input and validation
- **Permission Handler** 11.2.0 - Runtime permission management
- **Shared Preferences** 2.2.2 - Local key-value storage
- **Haptic Feedback** 0.5.1+1 - Tactile feedback on interaction
- **Equatable** 2.0.5 - Value equality helper for Dart models
- **UUID** 4.2.1 - UUID generation for unique identifiers
- **Intl** 0.20.2 - Internationalization (i18n) support (English, Spanish)

**Testing:**
- **Flutter Test** - Built-in widget testing framework
- **Mockito** 5.4.4 - Mock generation for unit tests
- **Mocktail** 1.0.3 - Type-safe mocking library (replaces Mockito mocks)
- **Build Runner** 2.4.10 - Code generation for Mockito and Mocktail
- **Fake Async** 1.3.1 - Async testing utilities

**Development:**
- **Flutter Launcher Icons** 0.14.1 - App icon generation for all platforms
- **Flutter Lints** 5.0.0 - Dart analysis and linting rules

## Key Dependencies

**Critical (Core Functionality):**
- `flutter_riverpod: ^2.4.9` - State management - essential for app-wide state and provider pattern
- `supabase_flutter: ^2.0.0` - Backend integration - PostgreSQL, authentication, storage, edge functions
- `qr_flutter: ^4.1.0` - Core feature: QR code generation
- `mobile_scanner: ^7.0.0` - Core feature: QR code scanning
- `google_mobile_ads: ^5.1.0` - Monetization for free tier users

**Infrastructure:**
- `go_router: ^13.0.0` - App navigation and deep linking
- `flutter_svg: ^2.0.9` - Logo and icon rendering
- `flutter_animate: ^4.3.0` - Carden Pro design animations
- `purchases_flutter: ^8.1.0` - RevenueCat subscription management

**Platform-Specific:**
- `webview_flutter: ^4.13.1` - WebView for in-app web content (marketplace, checkout)
- `geolocator: ^13.0.0` - GPS for location QR codes
- `flutter_contacts: ^1.1.9` - Contact access for contact QR codes
- `image_picker: ^1.0.7` - Image selection for profile and QR customization
- `permission_handler: ^11.2.0` - Runtime permission management

## Configuration

**Environment:**
- **Method:** Dart defines injected at build time via `--dart-define-from-file` flag
- **Configuration File:** `env.json` (git-ignored, contains secrets)
- **Template File:** `env.example.json` (committed, template only)
- **Key Variables:**
  - `SUPABASE_URL` - Supabase project URL
  - `SUPABASE_ANON_KEY` - Supabase public API key
  - `REVENUECAT_API_KEY_IOS` - RevenueCat SDK key for iOS (appl_*)
  - `REVENUECAT_API_KEY_ANDROID` - RevenueCat SDK key for Android (goog_*)

**Config Files:**
- `lib/core/config/env_config.dart` - Environment variable access layer
- `lib/core/config/supabase_config.dart` - Supabase-specific configuration (table names, constants)

**Build Configuration:**
- `pubspec.yaml` - Flutter project manifest with all dependencies
- `analysis_options.yaml` - Dart linting rules (flutter_lints)
- `android/app/build.gradle.kts` - Android build configuration (Kotlin DSL)
- `android/build.gradle.kts` - Android project-level configuration
- `ios/Podfile` - iOS CocoaPods dependencies
- `web/manifest.json` - Web app manifest (PWA metadata)

## Platform Requirements

**Development:**
- **macOS** - For iOS and desktop builds
- **Xcode** 14+ - iOS/macOS development
- **Android Studio** + **Android SDK** 23+ (API 23, minSdk varies by platform)
- **Flutter SDK** 3.6.2+ with Dart 3.6.2+
- **Java 11** - Required for Android builds (specified in build.gradle.kts)
- **Kotlin** 1.7+ - For Android native code

**Production:**
- **iOS:** iOS 12+ (via Flutter baseline)
- **Android:** API 23+ (minSdk 23, targetSdk 35 for Android 15 support)
- **Web:** Modern browser with Camera API support
- **Desktop:** macOS 10.11+, Windows 10+, Linux (glibc 2.27+)

**Capabilities Required:**
- **Camera** - For QR scanning (required Android, optional iOS)
- **Contacts** - Read access for contact QR generation
- **Location** - GPS access for location QR codes
- **Storage** - Read external storage via Android photo picker (image selection)
- **Network** - Internet access for Supabase, AdMob, RevenueCat

## Platform-Specific Configuration

**Android (`android/app/src/main/AndroidManifest.xml`):**
- **Package Name:** `io.gothcorp.qraft`
- **MinSDK:** 23 (Android 6.0), **TargetSDK:** 35 (Android 15)
- **Permissions:**
  - `android.permission.CAMERA` - QR scanning
  - `android.permission.READ_CONTACTS` - Contact access for contact QR codes
  - `android.permission.ACCESS_FINE_LOCATION` - GPS for location QR codes
  - `android.permission.ACCESS_COARSE_LOCATION` - Cell-based location fallback
  - `android.permission.INTERNET` - Network access for Supabase
  - Removed: `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `READ_MEDIA_*` (using Android photo picker)
- **Features:**
  - `android.hardware.camera` (required=true) - Camera required for scanning
  - `android.hardware.camera.autofocus` (required=false) - Auto-focus optional
  - `android.hardware.camera.flash` (required=false) - Flash optional
- **Deep Links:**
  - HTTPS: `https://qraft.gothcorp.io` (Firebase dynamic links domain)
  - Custom Scheme: `qraft://` (custom app scheme)
- **AdMob:** Application ID `ca-app-pub-9213497138890427~5118672998`
- **Hardware Acceleration:** Enabled (`hardwareAccelerated="true"`)

**iOS (`ios/Runner/Info.plist`):**
- **Bundle ID:** `io.gothcorp.qraft` (from Xcode project settings)
- **Minimum OS:** iOS 12+
- **Permissions (Privacy):**
  - `NSCameraUsageDescription` - Camera for QR scanning and photo capture
  - `NSPhotoLibraryUsageDescription` - Photo library for profile image and QR customization
  - `NSContactsUsageDescription` - Contacts for contact QR generation
  - `NSLocationWhenInUseUsageDescription` - GPS for location QR codes
- **Deep Links:**
  - Custom Scheme: `qraft://`
  - HTTPS: `https://qraft.gothcorp.io` (via associated domains)
- **AdMob:** Application ID `ca-app-pub-9213497138890427~5118672998`
- **SKAdNetwork IDs:** 10 SKAdNetwork identifiers for iOS 14+ ad attribution
- **User Tracking:** `NSUserTrackingUsageDescription` for personalized ads

**Web (`web/index.html`):**
- **Viewport:** Responsive with camera permissions
- **Camera Permission Policy:** `camera=*` (allow camera access)
- **Meta Tags:** Apple mobile web app capable, status bar styling, icons
- **Manifest:** Points to `manifest.json` for PWA metadata
- **Bootstrap:** Uses `flutter_bootstrap.js` for dynamic web initialization

**Desktop (macOS, Windows, Linux):**
- Supported platforms via Flutter's desktop support
- macOS uses native Objective-C/Swift via iOS API compatibility layer
- Windows/Linux use native C++ plugins for platform integration

## Build Outputs

- **Android:** APK and AAB (Android App Bundle) for Play Store
- **iOS:** iOS app package for App Store
- **Web:** HTML5/WASM Flutter web app
- **Desktop (macOS, Windows, Linux):** Native desktop applications
- **App Icons:** Auto-generated for all platforms via `flutter_launcher_icons`

---

*Stack analysis: 2026-05-01*
