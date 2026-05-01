# Codebase Concerns

**Analysis Date:** 2026-05-01

## Tech Debt

**Large UI Screen Files:**
- Issue: Multiple presentation screens exceed 1500+ lines, violating single-responsibility principle
- Files: 
  - `lib/features/qr_generator/presentation/pages/location_qr_screen.dart` (2025 lines)
  - `lib/features/qr_library/qr_library_screen.dart` (1834 lines)
  - `lib/features/qr_generator/presentation/pages/wifi_qr_screen.dart` (1403 lines)
  - `lib/features/qr_generator/presentation/pages/qr_form_screen.dart` (1238 lines)
  - `lib/features/dashboard/dashboard_screen.dart` (963 lines)
- Impact: Difficult to test, maintain, and debug; widget tree becomes unwieldy; high cognitive load for developers
- Fix approach: Extract form widgets to separate files, create custom stateful widget components for validation logic, split into smaller focused screens with nested navigation

**Incomplete Feature Implementation (Phase 1 MVP):**
- Issue: Multiple TODO comments indicating unfinished functionality
- Files and locations:
  - `lib/core/services/deeplink_service.dart:194` - Password reset screen navigation not implemented
  - `lib/core/services/deeplink_service.dart:203` - Email verification handling incomplete
  - `lib/features/marketplace/presentation/pages/product_details_screen.dart:130` - Cart navigation stub
  - `lib/features/profile/presentation/pages/profile_screen.dart:224,233,242` - Settings screens not implemented
  - `lib/features/profile/presentation/widgets/profile_actions_section.dart:252,257,262,267,272,278,284` - Multiple navigation destinations unimplemented
  - `lib/features/qr_library/qr_library_screen.dart:1587` - Share functionality incomplete
  - `lib/features/qr_library/presentation/pages/qr_code_details_screen.dart:413` - Share button not functional
- Impact: User-facing features marked "Coming Soon" are non-functional; inconsistent UX; potential support requests
- Fix approach: Implement missing screens, complete navigation routing, or remove Coming Soon placeholders and replace with real implementations

**Mobile Scanner Dependency Update:**
- Issue: Package updated from ^3.5.7 to ^7.0.0 (major version jump)
- File: `pubspec.yaml:51`
- Impact: Major API changes, potential breaking changes in QR scanner functionality, iOS dependency resolution issues mentioned in CLAUDE.md
- Fix approach: Run full QR scanner tests across iOS/Android, verify camera permission handling, review changelog for breaking changes (v4.0, v5.0, v6.0, v7.0), update scanner implementation if needed

**Localization File Bloat:**
- Issue: Monolithic localization file containing 3619 lines of generated code
- File: `lib/l10n/app_localizations.dart` (3619 lines)
- Impact: Difficult to navigate, slow IDE indexing, no semantic organization
- Fix approach: Split translations by feature domain (auth, qr_generation, marketplace, etc.), use generated translation keys instead of full strings, leverage intl_utils for structure

## Known Bugs

**ForgotPasswordDialog Test Failures:**
- Symptoms: 0 out of 6 tests failing pre-refactor for password reset flow (verified empirically 2026-05-01 via `grep -cE 'testWidgets\(|^\s*test\(' test/features/auth/presentation/widgets/forgot_password_dialog_test.dart` = 6, and `flutter test ...forgot_password_dialog_test.dart` = `+6 -0 All tests passed!` — prior 5/13 figure in this doc was stale; reconciled per Phase 1 D-10). The actual concern is not test failures but the underlying async/state-machine fragility documented below: the test count was correct in shape (Riverpod async state race conditions are real) but inflated in numbers.
- Files: 
  - `lib/features/auth/presentation/widgets/forgot_password_dialog.dart`
  - `test/features/auth/presentation/widgets/forgot_password_dialog_test.dart`
- Trigger: User submits email in forgot password dialog under various error conditions (race condition surface, even when current tests pass)
- Cause: Async state management issues with Riverpod provider state, email validation edge cases, loading state race conditions; widget holds an `_emailSent` boolean and reads `authProvider.errorMessage` after `await`, both of which can drift from the underlying `SupabaseAuthProvider` state machine
- Fix approach: Phase 1 plan 06 extracts state into a new `ForgotPasswordController` (StateNotifier + immutable state); Phase 1 plan 07 rewrites the test suite against the controller (controller tests + minimal widget tests), restoring full coverage and removing the race surface

**QR Scanner Permission Handling Gaps:**
- Symptoms: Camera permission request may fail silently on cold app start
- Files: `lib/features/qr_scanner/qr_scanner_screen.dart:37-77`
- Trigger: User opens scanner on first app launch without granting permissions
- Cause: Permission status not persisted; no retry mechanism after denial; controller initialization without proper error bubbling
- Workaround: Close and reopen scanner; manually grant permission in settings
- Fix approach: Add permission result callback with retry UI, show permission rationale dialog, handle permission revocation during scanning

**Incomplete Deep Link Navigation:**
- Symptoms: Password reset emails land in app but navigation doesn't occur
- Files: 
  - `lib/core/services/deeplink_service.dart:194,203` (TODO comments)
  - Platform-level handlers in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`
- Trigger: User clicks password reset link in email
- Cause: Deep link parameters parsed but not routed to appropriate screens
- Workaround: Users must manually navigate after reset
- Fix approach: Implement route handlers in `deeplink_service.dart`, wire up navigation based on `actionCode` and operation type

## Security Considerations

**Environment Configuration Secret Exposure Risk:**
- Risk: `env.json` file contains sensitive credentials and could be accidentally committed
- Files: 
  - `.gitignore` has `env.json` entry (correct)
  - `env.example.json` is committed (safe template)
  - `lib/core/config/env_config.dart` loads via `String.fromEnvironment()`
- Current mitigation: `.gitignore` prevents accidental commits; build-time injection via `--dart-define-from-file` is more secure than runtime loading
- Recommendations: 
  - Add pre-commit hook to verify env.json is never staged
  - Educate team on never running `flutter pub get` without env.json (will cause placeholder defaults)
  - Document that `env.json` must exist before running app or tests will fail with default values

**Supabase Service Key Removal - Verification Needed:**
- Risk: Service keys can bypass Row Level Security (RLS); removed in commit ecbf781
- Files affected: 
  - `lib/core/config/env_config.dart` - removed service key handling
  - `lib/core/services/supabase_service.dart` - uses only anon key
  - `lib/core/config/supabase_config.dart` - removed service key references
- Current state: Service key removed from codebase ✅
- Verification needed: 
  - Confirm no service key in `.env.production.json` (not in repo)
  - Verify RLS policies enforce user-scoped access
  - Audit Supabase Cloud Function access (if any edge functions exist)
- Recommendations:
  - Document that only anon key should ever be used in client app
  - Set up Supabase RLS policies audit in CI/CD
  - Use service key only in backend/edge functions with proper access control

**Ad Consent & Privacy - AdMob Integration:**
- Risk: Google AdMob requires GDPR/consent management for EU users
- Files: 
  - `lib/features/ads/data/services/admob_service.dart` - no consent handling
  - `lib/features/ads/constants/ad_unit_ids.dart` - ad unit configuration
  - `pubspec.yaml:93` - `google_mobile_ads: ^5.1.0` integrated
- Current state: AdMob integrated but no UMP (User Messaging Platform) consent management
- Current mitigation: Ad IDs updated to production in commit ecbf781 (test IDs for some units)
- Recommendations:
  - Integrate Google UMP SDK for consent management (`google_user_messaging_platform`)
  - Show consent form on first app launch for EU/UK users
  - Respect user consent preferences when serving ads
  - Document compliance with AdMob policies (family-friendly content, privacy policy link)
  - Add privacy policy screen in app (placeholder exists at `lib/features/profile/presentation/pages/profile_screen.dart:233`)

**Data Collection & Privacy Policy:**
- Risk: App collects camera, location, contacts, phone numbers without explicit consent UI
- Files with permissions:
  - Camera: `lib/features/qr_scanner/qr_scanner_screen.dart` (permission_handler integrated)
  - Location: `lib/features/qr_generator/presentation/pages/location_qr_screen.dart` (geolocator integrated)
  - Contacts: Multiple files use `flutter_contacts` for phone number/email input
  - Files: `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`
- Current state: Permissions requested at runtime but no privacy explanation screen
- Recommendations:
  - Create formal privacy policy document and host at qraft-e8a1d.firebaseapp.com
  - Add privacy policy acknowledgement on first app launch or in onboarding
  - Document data retention policies (how long scan history is kept, when deleted)
  - Add data export/deletion features (stub exists in profile screen)
  - Ensure strings in Info.plist explain purpose of each permission clearly

## Performance Bottlenecks

**QR Library List Rendering Performance:**
- Problem: QR library screen loads entire user's QR code list at once
- Files: `lib/features/qr_library/qr_library_screen.dart` (1834 lines)
- Cause: No pagination, no virtual scrolling, full list fetched from Supabase per load
- Impact: App hangs/stutters on users with 100+ saved QR codes; poor UX on slower devices
- Improvement path: 
  - Implement infinite scroll with pagination (fetch 20 at a time)
  - Use ListView.builder instead of ListView with full list
  - Add caching layer with pagination offset
  - Consider IndexedStack or PageView for lazy loading sections

**Large QR Generation Screen Memory Usage:**
- Problem: Form state stored with full QR bitmap in memory during form interaction
- Files: `lib/features/qr_generator/presentation/pages/location_qr_screen.dart` (2025 lines)
- Cause: Real-time QR preview generates new image on every form field change
- Impact: Memory spikes on devices with <2GB RAM; potential OutOfMemory crashes
- Improvement path:
  - Debounce QR generation to 500ms after user stops typing
  - Cache QR image and only regenerate on significant data changes
  - Use image memory pool to prevent garbage collection thrashing
  - Profile with DevTools memory timeline to identify leaks

**Location Map Widget Unoptimized Rendering:**
- Problem: flutter_map renders full map on every form field change
- Files: `lib/features/qr_generator/presentation/pages/location_qr_screen.dart`
- Cause: Map controller not wrapped in RepaintBoundary; rebuilds entire map
- Impact: Janky map panning/zooming; excessive repaints
- Improvement path:
  - Wrap map in RepaintBoundary
  - Use StreamBuilder with location updates only, not form rebuilds
  - Move map outside of reactive form state

**Image Processing Blocking Main Thread:**
- Problem: Image picker and cropping operations block UI
- Files: `lib/core/services/image_service.dart` (640 lines)
- Cause: Synchronous image operations on main thread
- Impact: App becomes unresponsive during image selection/cropping
- Improvement path:
  - Use `compute()` to run image operations on isolate
  - Add loading indicator during processing
  - Implement background image compression before storage

## Fragile Areas

**QR Type Detection and Parsing Logic:**
- Files: `lib/features/qr_scanner/models/scan_result.dart`
- Why fragile: Multiple regex patterns and string parsing for different QR types (URL, email, WiFi, vCard, etc.); no comprehensive test coverage
- Safe modification: 
  - Add unit tests for each QR type detection pattern
  - Use regex constants and document expected formats
  - Add escape sequence handling for special characters
  - Implement fallback to raw value if parsing fails
- Test coverage gaps: URL scheme detection (http, https, custom schemes), WiFi SSID encoding, vCard field extraction

**Deep Link Parameter Extraction:**
- Files: `lib/core/services/deeplink_service.dart` (194-203 with TODOs)
- Why fragile: Platform-specific link handling (Android intent data vs iOS universal links); parameter parsing with string operations
- Safe modification:
  - Add URL parameter validation before routing
  - Handle URL encoding edge cases (special characters, %20 vs +)
  - Add unit tests for each Firebase Auth link type (password reset, email verification, sign-in link)
  - Use Uri.parse() instead of manual string splitting
- Test coverage: Password reset code extraction, email verification links, error cases

**Riverpod State Management Interdependencies:**
- Files: Multiple provider files with cross-dependencies
  - `lib/features/auth/data/providers/supabase_auth_provider.dart`
  - `lib/features/qr_library/presentation/providers/qr_library_providers.dart`
  - `lib/features/subscription/presentation/providers/subscription_providers.dart`
- Why fragile: Circular provider dependencies possible; state invalidation cascading; async operations ordering not guaranteed
- Safe modification:
  - Document provider dependency graph
  - Use `.when()` and error handling on all async providers
  - Avoid direct state mutation; use copy-with patterns
  - Test provider interactions with full integration tests
- Test coverage: Provider override behavior, state updates, error propagation

**Database Migration Ordering:**
- Files: `supabase/migrations/` directory with 8 migration files
- Why fragile: Migration sequence critical; out-of-order execution causes RLS policy mismatches
- Safe modification:
  - Never modify applied migrations (create new ones)
  - Test all migrations in sequence locally before applying to production
  - Maintain clear migration documentation with dependencies
  - Use migration repair commands only if absolutely necessary
- Known migrations: scan_history schema fix (20250725122236), QR codes table (20250728000000-20250728000001), subscription fields (20251227001445-20251227002000)

## Scaling Limits

**Supabase Row Level Security Coverage:**
- Current capacity: RLS policies applied to main tables (users, qr_codes, scan_history, orders)
- Limit: As feature set expands, maintaining RLS consistency becomes harder; complex policies may have performance impact
- Scaling path:
  - Audit all tables for RLS policy completeness
  - Profile RLS policy performance as table sizes grow (10k+ rows per user)
  - Consider caching layer for frequently accessed data
  - Plan for table partitioning if single tables exceed 10GB

**Ad Loading and Serving Scale:**
- Current capacity: AdMob SDK tested with banner, interstitial, rewarded, and native ad formats
- Limit: Ad requests fail gracefully but no request batching; potential rate limiting at scale with 100k+ daily active users
- Scaling path:
  - Monitor ad request failures in production
  - Implement exponential backoff for failed ad loads
  - Use AdMob mediation if scaling requires multiple ad networks
  - Add analytics dashboard to track ad performance metrics

**Real-Time Sync Scalability (Supabase Realtime):**
- Current capacity: Realtime enabled on users table (20260102_enable_realtime_users.sql)
- Limit: Realtime broadcasts to all connected clients; may saturate WebSocket connections at 1000+ simultaneous users
- Scaling path:
  - Monitor Supabase Realtime subscription count and bandwidth
  - Implement client-side debouncing for Realtime updates
  - Use Realtime selectively (only tables that need live updates)
  - Plan for read replicas if profile updates cause bottleneck

## Dependencies at Risk

**mobile_scanner v7.0.0 Major Version:**
- Risk: Major version jump (3.5.7 → 7.0.0) suggests breaking API changes; iOS dependency resolution mentioned as "pending" in CLAUDE.md
- Impact: QR scanner functionality may break; camera permission handling may have changed; platform-specific code may need updates
- Migration plan:
  - Review mobile_scanner changelog for v4.0, v5.0, v6.0, v7.0 breaking changes
  - Test QR scanning on real iOS and Android devices
  - Verify camera permission flow still works with new version
  - Check if MLKit version on iOS has compatibility issues
  - Consider pinning to last stable minor version if issues persist

**webview_flutter v4.13.1 Recent Update:**
- Risk: Updated in commit 5d1dac3 but not used anywhere in codebase (no webview imports found)
- Impact: Unused dependency increases app size and build time; may have security vulnerabilities if outdated
- Migration plan:
  - Remove dependency if not used (check all files for `webview_flutter` imports)
  - If used, document the usage and ensure version is actively maintained
  - Monitor for security advisories on unused transitive dependencies

**purchases_flutter (RevenueCat) Integration:**
- Risk: In-app purchase handling for subscription tier; dependency on third-party service
- Impact: Subscription features fail if RevenueCat API down; user subscription status caching issues
- Monitoring: 
  - Check RevenueCat status page for outages
  - Log all purchase events for reconciliation
  - Implement fallback behavior if RevenueCat unreachable
- Recommendations:
  - Add RevenueCat error handling with user-friendly messaging
  - Implement offline queue for purchase events
  - Monitor RevenueCat SDK for deprecations

**google_mobile_ads Consent Management Gap:**
- Risk: AdMob SDK v5.1.0 requires explicit GDPR consent handling but no UMP integration found
- Impact: App non-compliant with EU data protection regulations; potential app store violations
- Migration plan:
  - Add `google_user_messaging_platform` package
  - Implement consent form on first app launch
  - Store consent preferences and respect user choices
  - Add AdMob policy compliance audit

## Missing Critical Features

**Privacy Policy & Data Handling:**
- Problem: No formal privacy policy document; data collection not disclosed
- Blocks: GDPR compliance, app store listing, user trust
- Stub exists: `lib/features/profile/presentation/pages/profile_screen.dart:233` - "Implement privacy settings"
- Action: Create comprehensive privacy policy covering:
  - What data is collected (camera, location, contacts)
  - How data is used (QR generation, scan history, marketplace orders)
  - Data retention and deletion policies
  - Third-party services (Firebase, Supabase, RevenueCat, AdMob)
  - User rights (export, deletion)

**Ad Consent Disclosure:**
- Problem: AdMob ads served without explicit user consent (GDPR/CCPA)
- Blocks: Compliance with Google Play Store policies, EU regulations
- Action: Implement Google User Messaging Platform (UMP) for consent management

**Notification Settings Screen:**
- Problem: Profile screen has TODO for notifications but feature not implemented
- Files: `lib/features/profile/presentation/pages/profile_screen.dart:224`
- Blocks: Push notification feature cannot be controlled by users
- Action: Implement notification permission and preference UI

**Complete Deep Link Navigation for Auth Flows:**
- Problem: TODOs at `lib/core/services/deeplink_service.dart:194,203`
- Blocks: Password reset, email verification flows broken
- Action: Complete navigation handlers and route users to appropriate screens

## Test Coverage Gaps

**ForgotPasswordDialog Incomplete Coverage:**
- What's not tested: 0 of 6 tests failing pre-refactor (verified empirically 2026-05-01); the 5/13 figure previously cited from CLAUDE.md was stale. The real coverage gap is depth, not failure rate: only happy-path UI assertions exist (renders, contains email field, validates empty input, accepts valid format, has cancel/send buttons, cancel closes dialog). Async submission paths, error states, success state, and loading transitions are NOT exercised. Phase 1 plan 06 extracts state into a controller; plan 07 rewrites the suite (controller-level state tests + reduced widget tests) to close the depth gap.
- Files: `lib/features/auth/presentation/widgets/forgot_password_dialog.dart`
- Risk: Password reset flow may crash in production paths the tests don't cover (loading races, AuthException handling, success transition)
- Priority: High - auth feature is critical
- Fix: Phase 1 plan 06 extracts ForgotPasswordController; plan 07 rewrites tests against the controller and restores depth coverage

**QR Type Detection and Parsing:**
- What's not tested: Different QR type parsing (WiFi, vCard, location, events)
- Files: `lib/features/qr_scanner/models/scan_result.dart`
- Risk: Invalid QR data may cause crashes or data corruption
- Priority: High - core scanner feature
- Fix: Add unit tests for each QR type, edge cases, special characters

**Image Service Processing:**
- What's not tested: Image picker, cropping, compression error handling
- Files: `lib/core/services/image_service.dart` (640 lines)
- Risk: Image operations may hang or crash, no error recovery
- Priority: Medium - affects logo upload feature
- Fix: Add tests for permission denial, invalid image formats, large files

**Deep Link Routing:**
- What's not tested: Platform-specific link handling, parameter extraction
- Files: `lib/core/services/deeplink_service.dart`
- Risk: Password reset links may not route correctly
- Priority: High - affects critical auth flow
- Fix: Add unit tests for each deep link type, URL parameter extraction

**Performance and Memory:**
- What's not tested: Large list rendering, image processing memory usage
- Files: `lib/features/qr_library/qr_library_screen.dart`, `lib/features/qr_generator/presentation/pages/location_qr_screen.dart`
- Risk: App crashes on low-memory devices or with large datasets
- Priority: Medium - affects user experience on older devices
- Fix: Add widget tests with large datasets, profile memory usage

---

*Concerns audit: 2026-05-01*
