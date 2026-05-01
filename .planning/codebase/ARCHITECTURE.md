<!-- refreshed: 2026-05-01 -->
# Architecture

**Analysis Date:** 2026-05-01

## System Overview

QRaft follows a **Clean Architecture pattern** with feature-based modular structure and Riverpod state management. The app is organized into discrete features (auth, qr_generator, qr_scanner, marketplace, profile, subscription) each with data/domain/presentation layers, plus a core layer for shared services.

```text
┌─────────────────────────────────────────────────────────────┐
│                 Presentation Layer (UI)                      │
│      screens, pages, widgets, controllers, providers         │
│   `lib/features/{feature}/presentation/`                    │
│   `lib/shared/widgets/`                                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│         Domain Layer (Business Logic & Entities)             │
│      use cases, repositories (abstract), entities            │
│   `lib/features/{feature}/domain/`                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│     Data Layer (Implementation & Data Sources)               │
│      repositories (impl), models, datasources                │
│   `lib/features/{feature}/data/`                            │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│         Core Layer (Infrastructure Services)                 │
│      Supabase client, configuration, deeplink service        │
│   `lib/core/`                                               │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                External Integrations                         │
│      Supabase, RevenueCat, Google AdMob                      │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| QRaftApp (ConsumerStatefulWidget) | Root app widget, theme setup, locale management | `lib/main.dart` |
| SplashScreen | Animated splash with 2.5s initialization delay | `lib/features/splash/splash_screen.dart` |
| AuthWrapper | Routes between auth flow (unauthenticated) and MainScaffold (authenticated) | `lib/main.dart` (lines 110-204) |
| AuthFlow | Multi-page auth navigation (Welcome → Login/SignUp) | `lib/features/auth/presentation/pages/auth_flow.dart` |
| SupabaseAuthProvider | Authentication state management, sign in/up/out, password reset | `lib/features/auth/data/providers/supabase_auth_provider.dart` |
| MainScaffold | Bottom navigation hub, routes between 5 main screens | `lib/features/main/main_scaffold.dart` |
| DashboardScreen | User overview and statistics | `lib/features/dashboard/dashboard_screen.dart` |
| QRGeneratorScreen | QR creation tools with multiple types (URL, WiFi, email, etc.) | `lib/features/qr_generator/qr_generator_screen.dart` |
| QRScannerScreen | Camera-based QR scanning interface | `lib/features/qr_scanner/qr_scanner_screen.dart` |
| QRLibraryScreen | User's saved QR codes collection | `lib/features/qr_library/qr_library_screen.dart` |
| MarketplaceScreen | Laser-engraved product catalog | `lib/features/marketplace/marketplace_screen.dart` |
| ProfileScreen | User profile, settings, subscription info | `lib/features/profile/presentation/pages/profile_screen.dart` |
| SupabaseService | Singleton Supabase client initialization and operations | `lib/core/services/supabase_service.dart` |

## Pattern Overview

**Overall:** Clean Architecture with Riverpod state management

**Key Characteristics:**
- Feature-based modular structure (auth, qr_generator, qr_scanner, qr_library, marketplace, profile, subscription, ads, dashboard)
- Three-layer pattern per feature: data/domain/presentation
- Riverpod providers for dependency injection and state management
- Supabase as backend (replaced Firebase Auth) with PostgreSQL
- RevenueCat for subscription management
- Google AdMob for free-tier advertising
- Deeplink support for password reset and email verification

## Layers

**Presentation Layer:**
- Purpose: UI rendering, user interaction handling, state subscription via Riverpod
- Location: `lib/features/{feature}/presentation/` and `lib/shared/widgets/`
- Contains: Pages/screens, widgets, controllers, presentation providers
- Depends on: Domain layer (use cases, repositories), Riverpod providers
- Used by: Flutter widget tree, user interactions

**Domain Layer:**
- Purpose: Business logic, entity definitions, use case orchestration
- Location: `lib/features/{feature}/domain/`
- Contains: Entities (plain Dart classes), abstract repositories, use cases
- Depends on: Nothing (pure Dart, no external dependencies)
- Used by: Presentation layer (via use cases), Data layer (implements repositories)

**Data Layer:**
- Purpose: Data persistence and retrieval, model-to-entity mapping
- Location: `lib/features/{feature}/data/`
- Contains: Repositories (implementations), models (JSON serialization), datasources
- Depends on: Domain layer (entities, abstract repositories), Supabase/local storage
- Used by: Domain repositories, called by presentation controllers

**Core Layer:**
- Purpose: Cross-cutting infrastructure, service initialization, configuration
- Location: `lib/core/`
- Contains: Supabase service, environment config, deeplink service, image service, locale provider
- Depends on: External packages (supabase_flutter, url_launcher)
- Used by: All features, main.dart

## Data Flow

### Primary Request Path: QR Code Generation and Storage

1. **User triggers QR generation** - User fills form in `QRGeneratorScreen` (e.g., URL form `url_form.dart`)
2. **Controller captures input** - `QRGeneratorController` in `lib/features/qr_generator/presentation/controllers/qr_generator_controller.dart` validates input
3. **Use case invoked** - `GenerateQRUseCase` (from `lib/features/qr_generator/domain/use_cases/generate_qr_use_case.dart`) processes business logic
4. **Repository stores data** - `QRRepositoryImpl` (from `lib/features/qr_generator/data/repositories/qr_repository_impl.dart`) delegates to datasources:
   - Remote: `QRSupabaseDataSource` saves to Supabase `qr_codes` table
   - Local: `QRSharedPrefsDataSource` caches locally
5. **Model-to-Entity conversion** - `QRCodeModel` (from `lib/features/qr_generator/data/models/qr_code_model.dart`) maps JSON ↔ `QRCodeEntity`
6. **Response flows back** - `QRCodeEntity` returned through layers
7. **Provider updates state** - Riverpod `userQRCodesProvider` notified via refresh, UI re-renders

### Authentication Flow (Entry Point)

1. **App startup** - `main()` initializes Supabase via `SupabaseService.initialize()` (`lib/core/services/supabase_service.dart`)
2. **SplashScreen displays** - 2.5s animation, calls `onInitializationComplete()`
3. **AuthWrapper checks state** - Watches `supabaseAuthProvider` from `lib/features/auth/data/providers/supabase_auth_provider.dart`
4. **Auth state routes**:
   - If `currentUser` null → Shows `AuthFlow` (Welcome/Login/SignUp screens)
   - If `currentUser` exists → Shows `MainScaffold` with 5-tab navigation
5. **User authenticates** - `SupabaseAuthProvider.signIn()` or `.signUp()` calls Supabase auth
6. **RevenueCat initializes** - On auth success, `initializeRevenueCat()` sets up subscription tracking (`lib/features/subscription/data/services/subscription_sync_service.dart`)
7. **Subscription realtime listener** - `startSubscriptionRealtime()` monitors subscription changes via Supabase realtime

### QR Scanner Flow

1. **User opens Scanner tab** - `QRScannerScreen` in `lib/features/qr_scanner/qr_scanner_screen.dart`
2. **Camera stream acquired** - `mobile_scanner` package feeds camera frames
3. **QR code detected** - Barcode parser returns raw value and parsed data
4. **ScanResult created** - `ScanResult` model (from `lib/features/qr_scanner/models/scan_result.dart`) structures the data
5. **History saved** - `QRSupabaseDataSource` writes to `scan_history` table in Supabase
6. **Dialog shows result** - `ScanResultDialog` displays parsed content (URL, WiFi details, contact, etc.)
7. **User action** - Copy, share, save to library, or open link

### Feature Gate (Subscription)

1. **User attempts action** - e.g., create 11th QR code on free plan
2. **Provider check** - `canCreateQRProvider` evaluates `planLimitsProvider` + current QR count
3. **Gate enforcement**:
   - If `false` → `FeatureLockedOverlay` blocks action, shows upgrade button
   - If `true` → Action proceeds
4. **Upgrade flow** - `UpgradeBottomSheet` opens, RevenueCat handles in-app purchase
5. **Subscription updated** - Realtime listener updates user profile with `subscription_status: 'pro'`

**State Management:**
- Riverpod `Provider` (computed) for pure reads (no state)
- Riverpod `StateProvider` for simple toggles (e.g., navigation index in `MainScaffold`)
- Riverpod `FutureProvider` for async data loads (e.g., user profile, QR codes)
- Riverpod `StateNotifierProvider` for complex state (e.g., `profileControllerProvider`)
- `ChangeNotifier` for `SupabaseAuthProvider` (legacy pattern, integrated with Riverpod via `ref.watch()`)

## Key Abstractions

**QRCodeEntity (Domain):**
- Purpose: Represents a QR code in business logic, immutable
- Examples: `lib/features/qr_generator/domain/entities/qr_code_entity.dart`
- Pattern: Equatable-based value object with `copyWith()` for immutability
- Contains: id, name, type, data, displayData, customization, timestamps, userId, isFavorite

**QRCustomization (Domain):**
- Purpose: Styling data for QR codes (colors, size, eye shape, logo)
- Examples: `lib/features/qr_generator/domain/entities/qr_code_entity.dart` (lines 70-139)
- Pattern: Nested value object with full serialization support

**QRType (Domain):**
- Purpose: Enum of QR types supported (URL, WiFi, email, vCard, location, event, text, phone)
- Examples: `lib/features/qr_generator/domain/entities/qr_type.dart`
- Pattern: Enum with `identifier` property for string serialization

**QRRepository (Abstract):**
- Purpose: Contract for QR data operations
- Examples: `lib/features/qr_generator/domain/repositories/qr_repository.dart`
- Pattern: Abstract class with methods like `saveQRCode()`, `getUserQRCodes()`, `toggleFavorite()`

**QRRepositoryImpl (Implementation):**
- Purpose: Concrete repository combining remote (Supabase) and local (SharedPrefs) datasources
- Examples: `lib/features/qr_generator/data/repositories/qr_repository_impl.dart`
- Pattern: Strategy pattern, delegates to appropriate datasource based on operation

**QRCodeModel (Data):**
- Purpose: JSON-serializable version of QRCodeEntity
- Examples: `lib/features/qr_generator/data/models/qr_code_model.dart`
- Pattern: Extends entity, adds `fromJson()`, `toJson()`, `fromEntity()` methods

**SupabaseAuthProvider (State Holder):**
- Purpose: Authentication state management (current user, loading, errors)
- Examples: `lib/features/auth/data/providers/supabase_auth_provider.dart`
- Pattern: ChangeNotifier with Riverpod integration
- Methods: `signUp()`, `signIn()`, `signOut()`, `resetPassword()`

**Providers (Riverpod):**
- Purpose: Dependency injection containers and computed state
- Examples: 
  - `qrRepositoryProvider` (Provider) in `lib/features/qr_generator/presentation/providers/qr_providers.dart`
  - `subscriptionPlanProvider` (FutureProvider) in `lib/features/subscription/presentation/providers/subscription_providers.dart`
- Pattern: Composable providers that transform/combine lower-level providers

## Entry Points

**main.dart - Application Bootstrap:**
- Location: `lib/main.dart`
- Triggers: `flutter run` or app launch
- Responsibilities: 
  1. Initialize Supabase via `SupabaseService.initialize()`
  2. Initialize AdMob via `MobileAds.instance.initialize()`
  3. Wrap app in `ProviderScope` (Riverpod)
  4. Set up localization (English/Spanish)
  5. Apply dark theme (Carden Pro design)
  6. Show SplashScreen → AuthWrapper branching

**SplashScreen - Initialization UI:**
- Location: `lib/features/splash/splash_screen.dart`
- Triggers: First screen after `main()`
- Responsibilities:
  1. Display animated logo with particle effects
  2. Run 2.5s initialization delay
  3. Call `onInitializationComplete()` to advance to `AuthWrapper`

**AuthWrapper - Authentication Gate:**
- Location: `lib/main.dart` (lines 110-204)
- Triggers: After SplashScreen
- Responsibilities:
  1. Watch `supabaseAuthProvider` for auth state
  2. On `currentUser == null` → Route to `AuthFlow` (unauthenticated)
  3. On `currentUser != null` → Route to `MainScaffold` (authenticated)
  4. Initialize RevenueCat and subscription realtime on auth success
  5. Handle loading and error states

**AuthFlow - Multi-Screen Navigation:**
- Location: `lib/features/auth/presentation/pages/auth_flow.dart`
- Triggers: Unauthenticated users
- Responsibilities:
  1. Manage state for 3-screen flow: Welcome → Login/SignUp
  2. Delegate auth actions to `SupabaseAuthProvider`
  3. Show deeplink-based forgot password dialog

**MainScaffold - Main Hub:**
- Location: `lib/features/main/main_scaffold.dart`
- Triggers: Authenticated users
- Responsibilities:
  1. Provide bottom navigation bar with 5 tabs
  2. Use `IndexedStack` to switch between screens
  3. Manage navigation via `navigationIndexProvider` (StateProvider)

## Architectural Constraints

- **Threading:** Single-threaded event loop (Dart default). Supabase async operations don't block UI.
- **Global state:** `SupabaseService._client` is a static singleton (initialized once in `main()`); auth state is global via `supabaseAuthProvider`
- **Circular imports:** None detected; clean unidirectional dependency flow (Presentation → Domain ← Data)
- **Deeplinks:** Handled via method channels (Android: native intent filters, iOS: universal links); `deepLinkHandlerProvider` processes password reset and email verification links
- **Auth state persistence:** Supabase SDK persists session to device storage; `currentUser` re-populated on app restart
- **Feature gates:** Subscription status cached in user profile; gating checked at time of action (not pre-computed)

## Anti-Patterns

### Mixed Business Logic in Presentation

**What happens:** Some screens have validation logic mixed with widget build code (e.g., form validators in `EmailQRScreen`)
**Why it's wrong:** Violates separation of concerns; hard to test; duplicates logic across screens
**Do this instead:** Extract form validation to controllers (`QRGeneratorController`, `QRCustomizationController`) and use `StateNotifierProvider` for validation state

### Hardcoded Colors in Widgets

**What happens:** Color values (#1A1A1A, #00FF88) repeated throughout presentation widgets instead of centralized theme
**Why it's wrong:** Maintenance burden; theme changes require hunting across many files
**Do this instead:** Extend `ColorScheme` in `main.dart` theme setup or create a dedicated `lib/core/theme/` directory with `AppColors` class

### Direct Supabase Calls in Widgets

**What happens:** Some screens reference `Supabase.instance.client` directly instead of going through providers
**Why it's wrong:** Tight coupling to Supabase; makes testing difficult; breaks abstraction layers
**Do this instead:** Always go through data layer providers (e.g., `qrRepositoryProvider`) or create a dedicated data source provider

### Missing Error Handling in Use Cases

**What happens:** Some use cases don't have try-catch; exceptions bubble up unhandled
**Why it's wrong:** Crashes the app or leaves UI in inconsistent state
**Do this instead:** Wrap all async operations in try-catch; return Result types or throw domain-specific exceptions

## Error Handling

**Strategy:** Exception-driven with fallback states

**Patterns:**
- `SupabaseAuthProvider.signIn()` catches `AuthException`, sets `_errorMessage`, UI displays via SnackBar
- `QRRepositoryImpl` delegates exceptions from datasources; presentation controllers catch and update loading/error state
- Deeplink service wraps URL parsing in try-catch; invalid deeplinks logged and ignored
- Subscription providers use `.when()` with error handler: `error: (_, __) => PlanLimits.free` (safe fallback)

**User feedback:**
- Errors shown via SnackBar (non-blocking) or AlertDialog (blocking, e.g., critical auth failures)
- Loading states shown via `CircularProgressIndicator` or shimmer overlays
- Validation errors shown inline in form fields (red border, error text)

## Cross-Cutting Concerns

**Logging:** 
- `debugPrint()` used throughout for development (printed only in debug mode)
- All Supabase calls logged with "✅", "❌", "🔍" emojis for quick scanning
- Auth state changes logged in `SupabaseAuthProvider._initialize()`

**Validation:** 
- Email validation via regex in `ForgotPasswordDialog` (`lib/main.dart` lines 381-390)
- Form validation delegated to widgets (e.g., `TextFormField.validator`)
- QR data validation in form widgets before passing to controller

**Authentication:**
- Managed centrally via `SupabaseAuthProvider` with Riverpod integration
- Deeplink-based password reset via Firebase Dynamic Links forwarding to Supabase reset page
- Session persistence handled by Supabase SDK; no manual token storage needed

---

*Architecture analysis: 2026-05-01*
