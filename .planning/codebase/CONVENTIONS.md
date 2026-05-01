# Coding Conventions

**Analysis Date:** 2026-05-01

## Naming Patterns

**Files:**
- Classes and widgets: PascalCase (`glass_button.dart`, `wifi_qr_screen.dart`, `qraft_logo.dart`)
- Utility files: snake_case (`qr_test_utilities.dart`, `env_config.dart`, `deeplink_service.dart`)
- Provider files: Include provider name in file (`supabase_auth_provider.dart`, `qr_library_providers.dart`)

**Classes:**
- Widget classes: PascalCase with descriptive purpose (`GlassButton`, `PrimaryGlassButton`, `SupabaseAuthProvider`, `DeepLinkService`)
- Private classes: Prefix with underscore for internal state classes (`_QRaftAppState`, `_AuthWrapperState`)
- Test helpers: Descriptive names with suffix pattern (`QRTestHelpers`, `MockFlutterContacts`, `MockGeolocator`)

**Functions and Methods:**
- Public methods: camelCase (`signUp()`, `signIn()`, `resetPassword()`, `parseSupabaseAuthLink()`)
- Private methods: Prefix with underscore (`_initialize()`, `_setLoading()`, `_clearError()`, `_handleMethodCall()`)
- Future async methods: Use `async`/`await` pattern, no trailing "Async" suffix
- Callback handlers: `_handle` prefix or context-specific name (`_handleSendResetEmail()`, `_handleDeepLink()`, `_handleSignupConfirmation()`)

**Variables:**
- Instance fields: camelCase (`_currentUser`, `_isLoading`, `_errorMessage`, `_emailController`)
- Constants: camelCase with `const` keyword (`const testText = 'Test Button'`)
- Late-initialized: Use `late` keyword for non-nullable fields initialized later (`late MockGenerateQRUseCase mockGenerateQRUseCase`)
- Color constants: Full hex with `const Color()` (`const Color(0xFF1A73E8)`, `const Color(0xFF00FF88)`)

**Types:**
- Generic type parameters: Single letter when obvious (`<T>`), descriptive when specific (`<QRCodeEntity>`, `<AuthResponse>`)
- Custom exceptions: Suffix with "Exception" or rely on platform exceptions (`AuthException`, `PlatformException`)
- Type aliases: Use appropriate naming for domain concepts

## Code Style

**Formatting:**
- Line length: Flexible, but prefer readability (Flutter convention: ~80-100 characters for most code, wider for expressions)
- Indentation: 2 spaces (Dart convention)
- Trailing commas: Use in multi-line collections, function arguments, and constructor parameters
- Spacing: One blank line between methods, two blank lines between class sections

**Linting:**
- Tool: `flutter_lints` (version ^5.0.0) via `analysis_options.yaml`
- Configuration: `include: package:flutter_lints/flutter.yaml`
- Rules: Uses flutter_lints recommended ruleset; no custom overrides currently enabled
- Run: `flutter analyze` to check code quality

**Example of standard Dart formatting:**
```dart
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  
  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    // Implementation
  }
}
```

## Import Organization

**Order:**
1. Dart imports (`dart:ui`, `dart:async`)
2. Flutter imports (`package:flutter/material.dart`, `package:flutter/services.dart`)
3. Third-party packages (`package:flutter_riverpod`, `package:supabase_flutter`)
4. Local imports (`relative imports` using `package:qraft/`)

**Example:**
```dart
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/deeplink_service.dart';
import '../../../../core/services/supabase_service.dart';
```

**Path Aliases:**
- Use full package imports: `package:qraft/core/services/deeplink_service.dart`
- Relative imports only for same-directory access
- Provider imports: Use absolute paths for clarity

## Error Handling

**Patterns:**
- Try-catch blocks with specific exception types first:
```dart
try {
  // Operation
} on AuthException catch (e) {
  debugPrint('Supabase signup error: ${e.message}');
  _setError('Signup failed: ${e.message}');
} on PlatformException catch (e) {
  debugPrint('Platform error: ${e.message}');
  // Handle platform error
} catch (e) {
  debugPrint('Unexpected error: $e');
  _setError('An unexpected error occurred');
} finally {
  _setLoading(false);
}
```

**Provider-Level Error Handling:**
- Supabase `AuthException` is the primary exception type used in auth flows (`lib/features/auth/data/providers/supabase_auth_provider.dart`)
- `PlatformException` for method channel communication (`lib/core/services/deeplink_service.dart`)
- Custom error message state management via `_errorMessage` property
- `_setError()` and `_clearError()` helper methods for consistent state updates

**Error Messages:**
- User-facing: Descriptive but concise ("Login failed: Invalid credentials")
- Debug output: Prefixed with emoji and context (`debugPrint('🔗 Received deeplink: $link')`)
- Validation errors: Specific field validation with clear message ("Password is required for secured networks")

## Logging

**Framework:** `debugPrint()` and `print()` from Dart

**Patterns:**
- Development logging: Use `debugPrint()` for debug-only messages
- Format: Emoji prefix + descriptive message for quick visual scanning
- Examples:
  ```dart
  debugPrint('✅ QRaft initialized with Supabase-only authentication');
  debugPrint('❌ Error verifying signup: $e');
  debugPrint('🔗 Received deeplink: $link');
  debugPrint('📧 Processing signup confirmation with token: ${parsed['token']?.substring(0, 10)}...');
  ```
- Control output: Use conditional checks for large data logging
- No logging of sensitive data (tokens truncated, passwords omitted)

## Comments

**When to Comment:**
- Complex algorithm logic
- Non-obvious design decisions
- Workarounds for known issues
- Integration points with external services
- Do not comment obvious code (variable assignments, basic operations)

**JSDoc/TSDoc:**
- Use Dart doc comments (`///`) for public APIs
- Document parameters, return values, and exceptions
- Example:
```dart
/// Parses Supabase Auth action links
/// 
/// Returns a map with parsed parameters if valid, null otherwise
/// 
/// Supports:
/// - Supabase auth verification links
/// - Custom QRaft deeplink format
/// - Legacy Firebase auth links
static Map<String, String>? parseSupabaseAuthLink(String link) {
  // Implementation
}
```

## Function Design

**Size:** 
- Keep functions focused on single responsibility
- Typical range: 20-50 lines (including error handling)
- Large screens/widgets split into private helper methods

**Parameters:**
- Named parameters for clarity: `Future<void> signUp({ required String email, required String password })`
- Optional parameters with default values when appropriate
- Use `required` keyword explicitly for non-nullable parameters

**Return Values:**
- Use `Future<void>` for async operations with side effects
- Use `Future<T>` for operations returning data
- Use `Stream<T>` for continuous event streams (e.g., `linkStream`)
- Nullable returns when value might not exist: `User?`, `Map<String, String>?`

**Example of well-designed method:**
```dart
/// Signs in user with email and password
/// 
/// Throws [AuthException] if credentials invalid
Future<void> signIn({
  required String email,
  required String password,
}) async {
  try {
    _setLoading(true);
    _clearError();
    
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user != null) {
      _currentUser = response.user;
      debugPrint('Signin successful: ${response.user!.email}');
    }
  } on AuthException catch (e) {
    _setError('Login failed: ${e.message}');
  } finally {
    _setLoading(false);
  }
}
```

## Module Design

**Exports:**
- Use barrel files (`lib/features/auth/auth.dart`) to export key classes
- Export only public API, not internal implementations
- Pattern: `export 'presentation/pages/auth_flow.dart';`

**Barrel Files:**
- Not extensively used, but pattern is available
- Main entry points are feature screens directly imported

**Clean Architecture Pattern Applied:**
- **Data Layer**: `lib/features/*/data/` - Repositories, providers, API clients
- **Domain Layer**: `lib/features/*/domain/` - Entities, use cases, interfaces
- **Presentation Layer**: `lib/features/*/presentation/` - UI screens, widgets, controllers
- **Core Layer**: `lib/core/` - Services, utilities, configuration shared across features

**Example structure (`lib/features/auth/`):**
```
lib/features/auth/
├── data/
│   └── providers/
│       └── supabase_auth_provider.dart        # Auth state management
├── domain/
│   └── entities/
│       └── auth_user.dart                     # User domain model
└── presentation/
    ├── pages/
    │   └── auth_flow.dart                     # Main auth screen
    └── widgets/
        └── forgot_password_dialog.dart        # Password reset dialog
```

## Riverpod State Management

**Provider Patterns:**
- Use `Provider<T>` for simple computed values and services
- Use `ChangeNotifier` with `ChangeNotifierProvider` for mutable state
- Use `FutureProvider<T>` for async operations (data fetching)
- Use `StreamProvider<T>` for continuous streams

**Example (Service Provider):**
```dart
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});
```

**Example (ChangeNotifier Provider for State):**
```dart
class SupabaseAuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}
```

## Glassmorphism Widget Component Pattern

**GlassButton Component** (`lib/shared/widgets/glass_button.dart`):
- Multi-layer structure with `BackdropFilter` for blur effect
- Exterior glow using `BoxShadow` (does not affect button size)
- Interior glass effect with white border and internal shadows
- Gradient colors customizable via parameters
- Default colors: `Color(0xFF00FF88)` to `Color(0xFF1A73E8)` (neon green to blue)
- Loading state with `CircularProgressIndicator`
- Disabled state with reduced opacity
- Icon support (optional, configurable position)

**Built-in Variants:**
- `PrimaryGlassButton`: Green-to-blue gradient (primary action)
- `SecondaryGlassButton`: Blue-to-purple gradient (secondary action)
- `SuccessGlassButton`: Green gradient (success feedback)

**Usage Example:**
```dart
PrimaryGlassButton(
  text: "Sign In",
  onPressed: _handleLogin,
  isLoading: isLoading,
  width: double.infinity,
)
```

**Glass Card Component** (`lib/shared/widgets/glass_card.dart`):
- Similar glassmorphism pattern applied to cards
- Used for content containers with background visibility
- Variants: `GlassCard`, `GlassStatCard`, `GlassTabContainer`

## Method Channel Pattern (Platform Communication)

**Implementation Pattern** (`lib/core/services/deeplink_service.dart`):
- Static `MethodChannel` constant: `const MethodChannel('qraft/deeplink')`
- Handlers: `_channel.setMethodCallHandler()` for incoming calls from native code
- Invoking native: `await _channel.invokeMethod('getInitialLink')`
- Exception handling: Wrap in try-catch for `PlatformException`
- Disposal: Close resources in `dispose()` method

**Deeplink Service Specifics:**
- Broadcasts deeplink stream: `StreamController<String>.broadcast()`
- Static parsing methods: `parseSupabaseAuthLink()`, `isPasswordResetLink()`
- Handler class: `DeepLinkHandler` wraps service with business logic
- Error recovery: Gracefully handles platform unavailability

## Testing Convention Patterns

**Widget Tests:**
- Use `testWidgets()` for UI component tests
- Wrap widgets in `MaterialApp` for testing context
- Use `tester.pumpWidget()` for initial build, `tester.pumpAndSettle()` for settling
- Find widgets via `find.byType()`, `find.text()`, `find.byIcon()`
- Tap: `await tester.tap(finder);`
- Type text: Via `tester.enterText()` or `tester.tap()` + text

**Unit Tests:**
- Use `test()` for non-widget logic
- Use `mocktail` for mocking (modern pattern replacing `mockito`)
- Register mocks: `registerFallbackValue()` for complex types
- Setup mocks: `when(...).thenReturn()/thenAnswer()/thenThrow()`
- Verify calls: `verify(...).called(n)`

**Service Tests:**
- Mock method channels: Use `TestDefaultBinaryMessengerBinding`
- Mock platform responses: Return values from `setMockMethodCallHandler`
- Test exception paths: Throw `PlatformException`

See `TESTING.md` for detailed testing patterns and structure.

---

*Convention analysis: 2026-05-01*
