# External Integrations

**Analysis Date:** 2026-05-01

## APIs & External Services

**Authentication & Backend:**
- **Supabase** - Backend-as-a-service combining authentication, database, storage, and edge functions
  - SDK/Client: `supabase_flutter: ^2.0.0` in `lib/core/services/supabase_service.dart`
  - Auth Type: PKCE flow (OAuth 2.0) configured in `lib/core/services/supabase_service.dart` line 31-33
  - Configuration: `lib/core/config/supabase_config.dart` manages URL and anon key from `SUPABASE_URL` and `SUPABASE_ANON_KEY` env vars
  - Project Reference: Available in Supabase Dashboard (for CLI operations in `supabase/config.toml`)
  - Tables: `users`, `qr_codes`, `scan_history`, `templates`, `products`, `orders`, `order_items` defined in `lib/core/config/supabase_config.dart`

**Monetization & Ads:**
- **Google AdMob** - In-app advertising for free tier users
  - SDK: `google_mobile_ads: ^5.1.0` initialized in `lib/main.dart` line 35
  - App ID (Production):
    - Android: `ca-app-pub-9213497138890427~5118672998` (in `android/app/src/main/AndroidManifest.xml` line 87-88)
    - iOS: `ca-app-pub-9213497138890427~5118672998` (in `ios/Runner/Info.plist` line 86-87)
  - Usage: Implemented in `lib/features/ads/presentation/providers/ad_providers.dart`

- **RevenueCat** - Subscription and in-app purchase management
  - SDK: `purchases_flutter: ^8.1.0` for iOS and Android
  - API Keys (Platform-specific):
    - iOS: `REVENUECAT_API_KEY_IOS` env var (format: `appl_*`)
    - Android: `REVENUECAT_API_KEY_ANDROID` env var (format: `goog_*`)
  - Configuration: `lib/core/config/env_config.dart` lines 21-31
  - Usage: `lib/features/subscription/presentation/providers/purchase_providers.dart`
  - Subscription Fields: Migration `20251227001445_add_subscription_fields.sql` and `20251227002000_add_revenuecat_fields.sql` add RevenueCat tracking to `users` table

**Maps & Location:**
- **Google Maps** (via flutter_map)
  - SDK: `flutter_map: ^7.0.0` for map display
  - Dependencies: `latlong2: ^0.9.1` for latitude/longitude handling
  - Usage: Location-based QR code creation in `lib/features/qr_generator/qr_generator_screen.dart`

## Data Storage

**Databases:**
- **PostgreSQL (Supabase)**
  - Provider: Supabase (managed PostgreSQL)
  - Connection: Uses `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `env.json`
  - Client: Supabase Flutter SDK (`supabase_flutter: ^2.0.0`)
  - Service Layer: `lib/core/services/supabase_service.dart`
  - Tables:
    - `users` - User profiles and subscription status
    - `qr_codes` - Generated QR codes with metadata
    - `scan_history` - User scan records (schema fixed in migration `20250725122236_fix_scan_history_schema.sql`)
    - `templates` - QR design templates
    - `products` - Marketplace product catalog
    - `orders` - Purchase orders
    - `order_items` - Line items for orders
    - `migrations` - Migration tracking system

**Local Storage:**
- **Shared Preferences** - Local key-value storage
  - SDK: `shared_preferences: ^2.2.2`
  - Usage: Storing user preferences, local app state, onboarding flags
  - Access: Standard Flutter shared preferences API

**File Storage:**
- **Supabase Storage** - Cloud file storage for user avatars and QR previews
  - Bucket: `avatars` (public bucket for user profile images)
  - Authentication: Uses authenticated requests via Supabase client
  - RLS Policies: Defined in `supabase/migrations/002_storage_policies.sql`
  - Access: Via Supabase Storage API in service layer

## Authentication & Identity

**Auth Provider:**
- **Supabase Authentication** - Built-in with PostgreSQL backend
  - Implementation: PKCE OAuth 2.0 flow configured in `lib/core/services/supabase_service.dart` lines 31-33
  - Provider: `lib/features/auth/data/providers/supabase_auth_provider.dart`
  - Sign-Up/Sign-In: Email + password via Supabase auth
  - Password Reset: Email-based with deep links to `qraft://` scheme and `https://qraft.gothcorp.io` domain
  - Deep Link Handler: `lib/core/services/deeplink_service.dart` parses Firebase auth links

**Deeplink Configuration:**
- **Android Deep Links:** `android/app/src/main/AndroidManifest.xml` lines 62-77
  - HTTPS: `https://qraft.gothcorp.io` with `autoVerify="true"` for verification
  - Custom Scheme: `qraft://` for app-to-app linking
- **iOS Deep Links:** `ios/Runner/Info.plist` lines 54-76
  - Custom Scheme: `qraft://`
  - Associated Domains: `applinks:qraft.gothcorp.io` (line 75)

## Monitoring & Observability

**Error Tracking:**
- Not detected - No error tracking service (Sentry, Crashlytics, etc.) currently integrated
- Recommendation: Consider adding Firebase Crashlytics or Sentry for production monitoring

**Logs:**
- **Console Logging:** Using Dart `debugPrint()` throughout codebase
  - Examples: `lib/main.dart` line 32, `lib/core/services/supabase_service.dart` lines 18, 36
- **Supabase Logs:** PostgreSQL query logs available in Supabase Dashboard (not accessed via SDK)
- **No Remote Logging:** Logs are local to debug console only (development only)

## CI/CD & Deployment

**Hosting:**
- **iOS App Store** - Distribution via Apple App Store
- **Google Play Store** - Distribution via Google Play Store
- **Web** - Self-hosted or CDN-deployed Flutter web app
- **Desktop** - Direct distribution for macOS, Windows, Linux

**CI Pipeline:**
- Not detected - No CI/CD pipeline configured (no GitHub Actions, GitLab CI, etc.)
- Build Configuration: Manual build via Flutter CLI commands
  - `flutter build apk` - Android APK
  - `flutter build ios` - iOS app
  - `flutter build web` - Web version
  - Signing: Android signing config in `android/app/build.gradle.kts` lines 31-38 (loads from `key.properties`)

## Environment Configuration

**Required env vars (in `env.json`):**
```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here",
  "REVENUECAT_API_KEY_IOS": "appl_xxxxxxxxxxxx",
  "REVENUECAT_API_KEY_ANDROID": "goog_xxxxxxxxxxxx"
}
```

**Required env vars (from `env.example.json`):**
- `SUPABASE_URL` - Supabase project endpoint
- `SUPABASE_ANON_KEY` - Supabase public API key (used for unauthenticated requests)
- `REVENUECAT_API_KEY_IOS` - RevenueCat app-specific API key for iOS (format: `appl_*`)
- `REVENUECAT_API_KEY_ANDROID` - RevenueCat app-specific API key for Android (format: `goog_*`)

**Secrets location:**
- `.gitignore` - Excludes `env.json` from git (contains real credentials)
- `env.example.json` - Committed template, no actual secrets
- Firebase credentials: Not directly in code (Firebase is deprecated in favor of Supabase-only auth)
- Android signing: `key.properties` file (git-ignored, contains keystore passwords)

## Webhooks & Callbacks

**Incoming (App receives from external services):**
- **Supabase Webhooks** - Can be configured in Supabase Dashboard for database events
  - Currently: Not detected in codebase (would appear in database policies or edge functions)
  - Potential Use: Trigger functions on order status changes, payment confirmations

- **Deep Link Callbacks** - App receives URLs via intent filters:
  - Android: Intent filters in `android/app/src/main/AndroidManifest.xml` capture `qraft://` and `https://qraft.gothcorp.io` URLs
  - iOS: URL schemes in `ios/Runner/Info.plist` capture `qraft://` and HTTPS domain links
  - Handler: `lib/core/services/deeplink_service.dart` parses URLs and routes to appropriate screens
  - Use Case: Password reset links, email verification links

- **RevenueCat Webhooks** - RevenueCat can send purchase events via webhooks
  - Currently: Not detected (would be handled via SDK callbacks, not HTTP webhooks)
  - Implementation: `lib/features/subscription/presentation/providers/purchase_providers.dart` handles purchase events

**Outgoing (App sends to external services):**
- **Supabase API Calls** - All data operations go to Supabase PostgreSQL
  - Endpoints: Supabase REST API (auto-generated from database schema)
  - Examples: `lib/core/services/supabase_service.dart` methods for user profiles, QR codes

- **RevenueCat API** - In-app purchase and subscription verification
  - SDK handles: App sends receipt data to RevenueCat for validation
  - Bidirectional: RevenueCat returns subscription status to app

- **Google AdMob API** - Ad serving requests
  - SDK handles: App requests ads from Google servers
  - No outgoing data beyond standard ad request (no custom webhooks)

- **Geolocator API** - Platform-specific location services
  - Android: Uses Google Location Services API
  - iOS: Uses CoreLocation framework
  - Outbound: No external API calls (local device GPS only)

## Payment Processing

**Payment Provider:**
- **RevenueCat** (abstraction layer) - Handles App Store and Google Play In-App Purchases
  - iOS: Communicates with Apple App Store
  - Android: Communicates with Google Play Billing Library
  - No Direct Credit Card Processing - Uses platform app store billing only

**Subscription Management:**
- **RevenueCat SDK** (`purchases_flutter: ^8.1.0`)
  - Tracks subscription status
  - Manages entitlements and feature access
  - Database tracking: `lib/features/subscription/` with provider pattern

## Data Integration Patterns

**Realtime Capabilities:**
- **Supabase Realtime** - WebSocket-based real-time updates (BETA in v2.0.0)
  - Enabled: Migration `20260102_enable_realtime_users.sql` enables realtime on `users` table
  - Usage: `lib/core/services/subscription_realtime_service.dart` subscribes to user subscription changes
  - Pattern: Riverpod providers use `.stream()` methods for real-time data

**Edge Functions:**
- **Supabase Edge Functions** - Serverless PostgreSQL-triggered functions
  - Location: `supabase/functions/` directory
  - Usage: Custom business logic, webhooks, scheduled jobs
  - Examples: Could handle order processing, payment verification, marketplace operations

## Third-Party Libraries for API Integration

**Image & Media:**
- `image_picker: ^1.0.7` - Uses native image picker (iOS Photos, Android Gallery)
- `crop_your_image: ^2.0.0` - Image cropping (local processing)

**Device & Platform:**
- `url_launcher: ^6.2.4` - Open URLs, email, phone, SMS intents
- `share_plus: ^10.0.0` - Multi-platform sharing via OS share sheet
- `permission_handler: ^11.2.0` - Runtime permission management
- `haptic_feedback: ^0.5.1+1` - Device vibration

**Internationalization:**
- `intl: ^0.20.2` - i18n support (English, Spanish)

---

*Integration audit: 2026-05-01*
