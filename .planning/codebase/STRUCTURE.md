# Codebase Structure

**Analysis Date:** 2026-05-01

## Directory Layout

```
qraft/
├── lib/                              # Main Dart source code
│   ├── main.dart                     # App bootstrap, theme, auth routing
│   ├── core/                         # Shared infrastructure services
│   │   ├── config/                   # Configuration files
│   │   │   ├── env_config.dart       # Environment variables from dart-define
│   │   │   └── supabase_config.dart  # Supabase URL, key, table names
│   │   ├── providers/                # Global Riverpod providers
│   │   │   └── locale_provider.dart  # Language/locale state
│   │   └── services/                 # Service singletons
│   │       ├── deeplink_service.dart # Deeplink parsing and routing
│   │       ├── image_service.dart    # Image cropping utilities
│   │       ├── supabase_service.dart # Supabase client initialization
│   │       └── subscription_realtime_service.dart # Realtime updates
│   │
│   ├── features/                     # Feature modules (one per domain)
│   │   ├── splash/
│   │   │   └── splash_screen.dart    # 2.5s animated splash with particles
│   │   │
│   │   ├── auth/                     # Authentication
│   │   │   ├── data/
│   │   │   │   ├── models/           # (none yet; uses domain entities directly)
│   │   │   │   └── providers/        # Riverpod providers
│   │   │   │       └── supabase_auth_provider.dart  # Auth state (ChangeNotifier)
│   │   │   ├── domain/
│   │   │   │   ├── entities/         # (none; uses Supabase User)
│   │   │   │   └── repositories/     # (abstract auth repository; not yet implemented)
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   ├── auth_flow.dart       # Multi-screen auth navigation
│   │   │       │   ├── welcome_screen.dart  # Initial auth screen
│   │   │       │   ├── login_screen.dart    # Sign in form
│   │   │       │   └── signup_screen.dart   # Register form
│   │   │       └── widgets/
│   │   │           └── forgot_password_dialog.dart  # Password reset UI
│   │   │
│   │   ├── dashboard/                # Dashboard/home overview
│   │   │   ├── dashboard_screen.dart  # Stats and quick actions
│   │   │   └── providers/
│   │   │       └── dashboard_providers.dart  # Dashboard Riverpod providers
│   │   │
│   │   ├── home/
│   │   │   └── home_screen.dart      # (legacy; not currently used)
│   │   │
│   │   ├── main/                     # Main scaffold (hub for navigation)
│   │   │   └── main_scaffold.dart    # Bottom nav (5 tabs), IndexedStack
│   │   │
│   │   ├── qr_generator/             # QR code generation
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── qr_local_data_source.dart          # Abstract local storage
│   │   │   │   │   ├── qr_remote_data_source.dart         # Abstract remote storage
│   │   │   │   │   ├── qr_shared_prefs_data_source.dart   # SharedPrefs implementation
│   │   │   │   │   └── qr_supabase_data_source.dart       # Supabase implementation
│   │   │   │   ├── models/
│   │   │   │   │   └── qr_code_model.dart    # JSON-serializable QR code
│   │   │   │   └── repositories/
│   │   │   │       └── qr_repository_impl.dart  # Repository combining datasources
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── qr_code_entity.dart      # Immutable QR code + customization
│   │   │   │   │   ├── qr_data_models.dart      # QR type-specific data classes
│   │   │   │   │   └── qr_type.dart             # Enum of QR types
│   │   │   │   ├── repositories/
│   │   │   │   │   └── qr_repository.dart       # Abstract repository interface
│   │   │   │   └── use_cases/
│   │   │   │       └── generate_qr_use_case.dart # Use case implementations
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       │   ├── qr_generator_controller.dart     # QR generation state
│   │   │       │   └── qr_customization_controller.dart # Customization state
│   │   │       ├── pages/
│   │   │       │   ├── qr_generator_screen.dart         # Main QR generation hub
│   │   │       │   ├── qr_form_screen.dart              # Form layout wrapper
│   │   │       │   ├── url_qr_screen.dart               # URL QR type
│   │   │       │   ├── wifi_qr_screen.dart              # WiFi credentials QR
│   │   │       │   ├── email_qr_screen.dart             # Email QR
│   │   │       │   ├── personal_info_qr_screen.dart     # vCard/contact QR
│   │   │       │   ├── location_qr_screen.dart          # Location/map QR
│   │   │       │   ├── text_qr_screen.dart              # Plain text QR
│   │   │       │   └── coming_soon_qr_screen.dart       # Placeholder for future types
│   │   │       ├── providers/
│   │   │       │   └── qr_providers.dart    # Riverpod dependency injection
│   │   │       └── widgets/
│   │   │           ├── qr_preview_widget.dart           # QR display
│   │   │           ├── color_picker_widget.dart         # Color customization
│   │   │           └── forms/
│   │   │               ├── url_form.dart                # URL input form
│   │   │               ├── wifi_form.dart               # WiFi details form
│   │   │               ├── email_form.dart              # Email form
│   │   │               ├── text_form.dart               # Text input form
│   │   │               ├── location_form.dart           # Location picker
│   │   │               ├── personal_info_form.dart      # Contact info form
│   │   │               ├── colombian_personal_step.dart # Colombian ID
│   │   │               ├── colombian_address_step.dart  # Colombian address
│   │   │               ├── colombian_tax_step.dart      # Tax info
│   │   │               └── colombian_tax_form.dart      # Tax form wrapper
│   │   │
│   │   ├── qr_scanner/                # QR code scanning
│   │   │   ├── models/
│   │   │   │   └── scan_result.dart    # Parsed QR scan result
│   │   │   ├── providers/
│   │   │   │   └── qr_scanner_provider.dart  # Scan history provider
│   │   │   ├── qr_scanner_screen.dart # Camera-based scanner
│   │   │   └── widgets/
│   │   │       ├── scan_result_dialog.dart   # Result display/action UI
│   │   │       └── scan_history_screen.dart  # History list view
│   │   │
│   │   ├── qr_library/                # QR collection management
│   │   │   ├── presentation/
│   │   │   │   ├── controllers/
│   │   │   │   │   └── qr_library_controller.dart  # Library state
│   │   │   │   ├── pages/
│   │   │   │   │   ├── qr_code_details_screen.dart # Individual QR view
│   │   │   │   │   └── (uses qr_library_screen.dart)
│   │   │   │   ├── providers/
│   │   │   │   │   └── qr_library_providers.dart  # Fetch user QR codes
│   │   │   │   └── widgets/
│   │   │   │       └── qr_code_display_widget.dart # QR card widget
│   │   │   └── qr_library_screen.dart # Library grid view
│   │   │
│   │   ├── marketplace/               # Product catalog and checkout
│   │   │   ├── domain/
│   │   │   │   └── entities/
│   │   │   │       └── product_entity.dart  # Laser-engraved product
│   │   │   ├── marketplace_screen.dart      # Main marketplace hub
│   │   │   └── presentation/
│   │   │       ├── pages/
│   │   │       │   └── product_details_screen.dart  # Product detail view
│   │   │       └── widgets/
│   │   │           ├── product_hero_section.dart    # Large product image
│   │   │           ├── product_info_section.dart    # Name, price, material
│   │   │           ├── product_gallery.dart         # Image carousel
│   │   │           ├── features_section.dart        # Product features list
│   │   │           ├── customization_section.dart   # Customization options
│   │   │           ├── bottom_action_bar.dart       # Add to cart, buy buttons
│   │   │           └── coming_soon_overlay.dart     # Overlay for preview
│   │   │
│   │   ├── profile/                  # User profile and settings
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── user_profile_model.dart  # Profile JSON model
│   │   │   │   └── providers/
│   │   │   │       └── profile_stats_providers.dart  # Stats computation
│   │   │   ├── domain/
│   │   │   │   └── entities/
│   │   │   │       └── user_profile_entity.dart     # Profile value object
│   │   │   └── presentation/
│   │   │       ├── controllers/
│   │   │       │   └── profile_controller.dart  # Profile edit state
│   │   │       ├── pages/
│   │   │       │   └── profile_screen.dart      # Main profile view
│   │   │       └── widgets/
│   │   │           ├── profile_header.dart              # Avatar and name
│   │   │           ├── profile_info_section.dart        # User details
│   │   │           ├── profile_stats_section.dart       # QR count, scans, etc.
│   │   │           ├── profile_actions_section.dart     # Action buttons
│   │   │           ├── inline_editable_profile_info.dart # Inline edit fields
│   │   │           ├── edit_profile_modal.dart          # Full profile editor
│   │   │           └── profile_form_field.dart          # Form field widget
│   │   │
│   │   ├── subscription/             # RevenueCat integration & feature gating
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── revenuecat_datasource.dart  # RevenueCat wrapper
│   │   │   │   ├── repositories/
│   │   │   │   │   └── purchase_repository_impl.dart  # Purchase logic
│   │   │   │   └── services/
│   │   │   │       └── subscription_sync_service.dart  # Sync with user profile
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── subscription_plan.dart     # Free/Pro plan
│   │   │   │   │   ├── plan_limits.dart           # QR/scan limits
│   │   │   │   │   ├── purchase_product.dart      # Purchasable SKU
│   │   │   │   │   ├── purchase_error.dart        # Error types
│   │   │   │   │   └── feature_access.dart        # Feature availability
│   │   │   │   └── repositories/
│   │   │   │       └── purchase_repository.dart   # Abstract purchase API
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── subscription_providers.dart     # Plan and limits providers
│   │   │       │   ├── purchase_providers.dart        # Purchase state providers
│   │   │       │   └── feature_gate_providers.dart    # Feature access checks
│   │   │       └── widgets/
│   │   │           ├── feature_gate.dart          # Wrapper for gated features
│   │   │           ├── feature_locked_overlay.dart # Upgrade prompt overlay
│   │   │           ├── product_card.dart          # Subscription tier card
│   │   │           ├── purchase_button.dart       # Buy button
│   │   │           ├── upgrade_bottom_sheet.dart  # Purchase UI
│   │   │           ├── qr_limit_indicator.dart    # QR usage bar
│   │   │           ├── pro_badge.dart             # "Pro" label
│   │   │           └── widgets.dart               # Widget exports
│   │   │
│   │   ├── ads/                      # Google AdMob integration
│   │   │   ├── ads.dart              # Feature export
│   │   │   ├── constants/
│   │   │   │   └── ad_unit_ids.dart  # AdMob unit IDs by platform
│   │   │   ├── data/
│   │   │   │   └── services/
│   │   │   │       └── admob_service.dart  # AdMob initialization
│   │   │   ├── domain/
│   │   │   │   └── entities/
│   │   │   │       └── ad_config.dart     # Ad configuration
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── ad_providers.dart  # Ad loading providers
│   │   │       └── widgets/
│   │   │           ├── banner_ad_widget.dart   # Banner ad display
│   │   │           ├── native_ad_widget.dart   # Native ad display
│   │   │           └── rewarded_ad_button.dart # Rewarded ad button
│   │   │
│   │   └── dashboard/ (repeated; see above)
│   │
│   ├── shared/                       # Cross-feature shared code
│   │   ├── providers/                # Global state
│   │   │   └── (currently empty; locale_provider in core/)
│   │   ├── services/                 # (currently empty; services in core/)
│   │   └── widgets/                  # Reusable UI components
│   │       ├── qraft_logo.dart       # Custom SVG logo with theme support
│   │       ├── glass_button.dart     # Glassmorphism button (Primary, Secondary, Success)
│   │       ├── glass_card.dart       # Glassmorphism card container
│   │       ├── animated_favorite_button.dart  # Heart icon with animation
│   │       ├── main_navigation.dart  # Bottom navigation bar (5 tabs)
│   │       ├── language_selector.dart # Language/locale picker
│   │       ├── image_source_selector.dart     # Camera vs gallery picker
│   │       ├── image_cropper_screen.dart      # Image cropping UI
│   │       └── (shared widgets for all features)
│   │
│   └── l10n/                         # Localization (i18n)
│       ├── app_en.arb                # English translations
│       ├── app_es.arb                # Spanish translations
│       ├── app_localizations.dart    # Generated base class
│       ├── app_localizations_en.dart # Generated English delegate
│       ├── app_localizations_es.dart # Generated Spanish delegate
│       └── generated/                # Auto-generated i18n code (do not edit)
│
├── test/                             # Test suite
│   ├── widget_test.dart              # Default Flutter widget test
│   ├── core/
│   │   └── services/
│   │       ├── deeplink_service_test.dart    # Deeplink parsing tests
│   │       └── image_service_test.dart       # Image utility tests
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   └── providers/
│   │   │   │       └── supabase_auth_provider_test.dart  # Auth state tests
│   │   │   └── presentation/
│   │   │       └── widgets/
│   │   │           └── forgot_password_dialog_test.dart  # Password reset UI tests
│   │   ├── qr_generator/
│   │   │   ├── presentation/
│   │   │   │   ├── controllers/
│   │   │   │   │   └── wifi_form_controller_test.dart    # WiFi form logic tests
│   │   │   │   └── pages/
│   │   │   │       ├── email_qr_screen_test.dart
│   │   │   │       ├── location_qr_screen_test.dart
│   │   │   │       └── wifi_qr_screen_test.dart
│   │   │   ├── test_utilities/
│   │   │   │   └── qr_test_utilities.dart   # Test helper functions
│   │   │   └── QR_TESTING_SUMMARY.md        # QR testing documentation
│   │   ├── qr_scanner/
│   │   │   ├── models/
│   │   │   │   └── scan_result_test.dart    # Scan result model tests
│   │   │   └── widgets/
│   │   │       └── scan_result_dialog_test.dart  # Result display tests
│   │   └── (more test files for other features)
│   └── shared/
│       └── widgets/
│           └── glass_button_test.dart   # Button component tests
│
├── assets/                           # Static resources
│   ├── images/
│   │   ├── qraft_logo.svg            # Main app logo
│   │   └── qraft_logo_bg.svg         # Logo with background variant
│   └── icon/
│       └── icon.png                  # App icon
│
├── android/                          # Android-specific code
│   ├── app/
│   │   └── src/main/
│   │       ├── AndroidManifest.xml   # Deeplink intent filters, permissions
│   │       ├── java/                 # Java/Kotlin native code
│   │       ├── kotlin/               # Kotlin native code
│   │       └── res/                  # Android resources (strings, colors)
│   └── build.gradle                  # Android build configuration
│
├── ios/                              # iOS-specific code
│   └── Runner/
│       ├── Info.plist                # Deep linking setup, permissions
│       ├── AppDelegate.swift         # iOS app lifecycle and method channels
│       └── (Xcode project files)
│
├── web/                              # Web platform
│   ├── index.html                    # HTML entry point
│   └── manifest.json                 # Web app manifest
│
├── macos/                            # macOS desktop app (optional)
├── windows/                          # Windows desktop app (optional)
├── linux/                            # Linux desktop app (optional)
│
├── supabase/                         # Database and backend
│   ├── config.toml                   # Supabase local dev config
│   ├── complete_setup.sql            # SQL schema and RLS policies
│   ├── migrations/                   # Database schema migrations
│   └── functions/                    # Edge Functions (serverless)
│
├── pubspec.yaml                      # Project dependencies and metadata
├── analysis_options.yaml             # Dart linter configuration
├── CLAUDE.md                         # Development guide (architecture, setup)
├── README.md                         # Project overview
├── SETUP_GUIDE.md                    # Developer onboarding guide
├── env.example.json                  # Environment variable template (COMMITTED)
├── env.json                          # Environment variables (GITIGNORED)
└── l10n.yaml                         # i18n configuration
```

## Directory Purposes

**lib/**
- Main Dart application source code
- Contains all app logic, UI, state management
- Organized by feature (clean architecture)

**lib/core/**
- Infrastructure and cross-cutting services
- Supabase initialization, configuration, deeplink handling
- Shared locale provider
- No feature-specific logic

**lib/features/**
- Feature modules, one per significant domain (auth, qr_generator, marketplace, etc.)
- Each feature has data/domain/presentation layers
- Independent and composable; can be developed and tested in isolation

**lib/shared/widgets/**
- Reusable UI components used across multiple features
- GlassButton (glassmorphism button), GlassCard, logo, language selector, image tools
- No feature-specific state; purely presentational

**lib/l10n/**
- Generated and hand-authored localization files
- ARB format for English/Spanish translations
- Auto-generated delegates and localizations for `AppLocalizations.of(context)`

**test/**
- Unit and widget tests mirroring lib/ structure
- Co-located with source files (e.g., test/features/auth/ matches lib/features/auth/)
- Covers controllers, providers, services, widgets

**android/, ios/, web/, macos/, windows/, linux/**
- Platform-specific configuration and native code
- Android: Manifest for deeplinks/permissions, Kotlin/Java for native channels
- iOS: Info.plist for deeplinks/permissions, Swift for native channels
- Web: HTML/JS entry point and manifest
- Desktop (macos/windows/linux): Project setup (generated)

**supabase/**
- Database schema (migrations/), Edge Functions, local dev config
- `migrations/` contains versioned SQL files applied in sequence
- `complete_setup.sql` comprehensive schema + RLS policies
- Used by Supabase CLI (`supabase migration` commands)

**pubspec.yaml**
- Dart package manager configuration
- Lists all dependencies (flutter_riverpod, supabase_flutter, qr_flutter, etc.)
- Defines app name, version, build number, supported locales

## Key File Locations

**Entry Points:**
- `lib/main.dart` - App initialization, Supabase setup, theme, Riverpod ProviderScope
- `lib/features/splash/splash_screen.dart` - First UI screen (2.5s animation)
- `lib/features/auth/presentation/pages/auth_flow.dart` - Unauthenticated users
- `lib/features/main/main_scaffold.dart` - Authenticated users, main navigation hub

**Configuration:**
- `lib/core/config/env_config.dart` - Reads environment variables from dart-define
- `lib/core/config/supabase_config.dart` - Supabase credentials and table names
- `pubspec.yaml` - Project metadata, dependencies, version
- `env.example.json` - Template for environment variables (COMMITTED)
- `analysis_options.yaml` - Linter rules (flutter_lints)

**Core Logic:**
- `lib/core/services/supabase_service.dart` - Supabase client singleton, operations
- `lib/core/services/deeplink_service.dart` - Deeplink parsing, password reset routing
- `lib/features/auth/data/providers/supabase_auth_provider.dart` - Auth state management
- `lib/features/qr_generator/data/repositories/qr_repository_impl.dart` - QR data logic

**UI/Presentation:**
- `lib/features/*/presentation/pages/*_screen.dart` - Full-screen views
- `lib/features/*/presentation/widgets/*.dart` - Reusable UI components
- `lib/shared/widgets/*.dart` - Cross-feature components (buttons, cards, logo)
- `lib/l10n/app_localizations.dart` - Localization access (generated)

**Testing:**
- `test/shared/widgets/glass_button_test.dart` - Button component tests
- `test/features/auth/data/providers/supabase_auth_provider_test.dart` - Auth tests
- `test/features/qr_generator/**/*_test.dart` - QR generation tests
- `test/core/services/**/*_test.dart` - Service tests

## Naming Conventions

**Files:**
- `snake_case.dart` for all Dart files
- `*_screen.dart` for full-page widgets (routable screens)
- `*_controller.dart` for state management classes
- `*_provider.dart` for Riverpod providers or ChangeNotifier
- `*_entity.dart` for domain business objects
- `*_model.dart` for data layer JSON-serializable models
- `*_repository.dart` for abstract and concrete repository classes
- `*_test.dart` for test files
- `*_datasource.dart` for data access abstraction
- `*_service.dart` for singleton services (Supabase, AdMob, etc.)

**Directories:**
- `features/` - Feature modules (plural, lowercase)
- `data/` - Data layer (repositories, models, datasources)
- `domain/` - Domain layer (entities, use cases, abstract repositories)
- `presentation/` - Presentation layer (screens, widgets, providers, controllers)
- `pages/` - Full-screen widgets within presentation
- `widgets/` - Reusable components within presentation
- `models/` - Data layer models
- `entities/` - Domain layer value objects
- `repositories/` - Both data and domain layer
- `providers/` - Riverpod providers
- `datasources/` - Data access implementations
- `services/` - Singletons (core/services/)

**Classes & Functions:**
- `PascalCase` for classes (e.g., `QRCodeEntity`, `SupabaseAuthProvider`)
- `camelCase` for functions and variables (e.g., `generateQR()`, `userProfile`)
- `SCREAMING_SNAKE_CASE` for constants (e.g., `MAX_QR_CODES_FREE = 10`)
- Prefix with underscore for private (e.g., `_setLoading()`, `_client`)

**Widgets:**
- `StatelessWidget` for pure UI (no state)
- `StatefulWidget` for local mutable state (animations, text input)
- `ConsumerWidget` / `ConsumerStatefulWidget` for Riverpod integration
- Suffix with `Screen` for routable pages, `Widget` for components

## Where to Add New Code

**New Feature:**
1. Create `lib/features/{feature_name}/` directory
2. Add subdirectories: `data/` (datasources, models, repositories), `domain/` (entities, repositories, use_cases), `presentation/` (pages, widgets, controllers, providers)
3. Start with domain layer (define `Entity`, abstract `Repository`)
4. Implement data layer (`Model`, `RepositoryImpl`, `DataSource`)
5. Create presentation layer (screens, widgets, controllers)
6. Add Riverpod providers in `presentation/providers/`
7. Wire into navigation (e.g., add tab to `MainScaffold` if it's a main feature)
8. Add tests in `test/features/{feature_name}/` mirroring structure

**New Page/Screen:**
- Location: `lib/features/{feature}/presentation/pages/{screen_name}_screen.dart`
- Extend `ConsumerWidget` or `ConsumerStatefulWidget`
- Use Riverpod `ref.watch()` to subscribe to providers
- Route from parent navigator or bottom nav

**New Reusable Component:**
- Location: `lib/shared/widgets/{component_name}.dart` if cross-feature, else `lib/features/{feature}/presentation/widgets/`
- Extend `StatelessWidget` or `StatefulWidget` (no Riverpod needed unless state is complex)
- Document with /// comments explaining parameters and usage

**New Provider:**
- Location: `lib/features/{feature}/presentation/providers/{provider_name}_provider.dart`
- Use `Provider<T>` for computed/read-only values
- Use `StateProvider<T>` for simple toggles (e.g., navigation index)
- Use `FutureProvider<T>` for async data loading
- Use `StateNotifierProvider<NotifierClass, StateClass>` for complex state

**New Datasource:**
- Location: `lib/features/{feature}/data/datasources/{datasource_name}_data_source.dart`
- Create abstract base class with interface methods
- Implement concretely (e.g., `QRSupabaseDataSource`, `QRSharedPrefsDataSource`)
- Inject into repository via provider

**New Entity:**
- Location: `lib/features/{feature}/domain/entities/{entity_name}_entity.dart`
- Extend `Equatable` for value comparison
- Add `props` getter for equality
- Add `copyWith()` for immutable updates
- Add JSDoc /// comments for fields

**New Model (Data Layer):**
- Location: `lib/features/{feature}/data/models/{model_name}_model.dart`
- Extend corresponding entity class
- Implement `fromJson()` factory for deserialization
- Implement `toJson()` method for serialization
- Optionally add `fromEntity()` factory for domain→data conversion

**New Test:**
- Location: `test/features/{feature}/[data|domain|presentation]/{component}_test.dart`
- Use `testWidgets()` for widgets, `test()` for units
- Mock dependencies with `mockito` or `mocktail`
- Follow AAA pattern: Arrange → Act → Assert

## Special Directories

**supabase/migrations/**
- Purpose: Database schema version control
- Generated: No (hand-authored)
- Committed: Yes (version history)
- Naming: `YYYYMMDDHHMMSS_description.sql`
- Usage: Applied sequentially by Supabase CLI; cannot be modified after application

**supabase/functions/**
- Purpose: Edge Functions (serverless Deno scripts)
- Generated: No (hand-authored)
- Committed: Yes
- Usage: Called from app via Supabase client; handles complex backend logic

**build/**
- Purpose: Compiled artifacts and intermediate build files
- Generated: Yes (by Flutter)
- Committed: No (in .gitignore)
- Useful for: Debugging build issues; can be deleted and regenerated

**.dart_tool/**
- Purpose: Dart/Flutter toolchain cache
- Generated: Yes (by Flutter)
- Committed: No (in .gitignore)
- Useful for: Dependency resolution; can be regenerated

**lib/l10n/generated/**
- Purpose: Auto-generated localization code
- Generated: Yes (by `flutter gen-l10n`)
- Committed: No (generated on build)
- Editing: Only edit `*.arb` files; regenerate this directory

**ios/Pods/ and android/.gradle/**
- Purpose: Native dependency caches
- Generated: Yes (by pod/gradle)
- Committed: No (in .gitignore)
- Management: Tracked in Podfile.lock / gradle.lock

---

*Structure analysis: 2026-05-01*
