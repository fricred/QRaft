# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**QRaft** is a comprehensive Flutter application for QR code generation, scanning, and physical marketplace integration. The app allows users to create personalized QR codes and order laser-engraved physical products through an integrated marketplace using XTool F1 Ultra laser machine.

### Key Features
- **QR Generation**: Create QR codes for personal info, URLs, WiFi, vCards, events, locations
- **QR Scanner**: Scan and manage QR code history
- **Visual Customization**: Personalize QR appearance with colors, logos, templates
- **Marketplace**: Order laser-engraved QR codes on various materials (wood, acrylic, metal, leather, glass, stone)
- **User Management**: Authentication, profiles, order tracking
- **Template Library**: Pre-designed QR templates

### Tech Stack
- **Frontend**: Flutter (cross-platform)
- **Authentication**: Firebase Authentication
- **Backend**: Supabase (PostgreSQL, Edge Functions, Storage)
- **Target Platforms**: iOS, Android, Web

## Development Commands

### Setup and Dependencies
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies to latest versions

### Development
- `flutter run` - Run the app in debug mode on connected device/emulator
- `flutter run -d chrome` - Run the app in web browser
- `flutter run --hot-reload` - Enable hot reload during development

### Code Quality
- `flutter analyze` - Run static analysis on Dart code
- `flutter test` - Run all widget and unit tests
- `flutter test test/widget_test.dart` - Run a specific test file

### Building
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app (requires macOS and Xcode)
- `flutter build web` - Build web version
- `flutter build macos` - Build macOS desktop app
- `flutter build windows` - Build Windows desktop app  
- `flutter build linux` - Build Linux desktop app

### Other Useful Commands
- `flutter doctor` - Check development environment setup
- `flutter clean` - Clean build artifacts
- `flutter devices` - List available devices/emulators

## Project Structure

- `lib/main.dart` - Main application entry point with Firebase initialization and splash screen flow
- `lib/features/splash/splash_screen.dart` - Animated splash screen with Carden Pro styling
- `lib/features/auth/` - Firebase authentication module with clean architecture
- `lib/shared/widgets/qraft_logo.dart` - Custom QRaft logo widget with configurable themes
- `assets/images/qraft_logo.svg` - Custom SVG logo with QR and laser elements
- `test/` - Widget and unit tests
- `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/` - Platform-specific configurations
- `pubspec.yaml` - Flutter project configuration and dependencies
- `analysis_options.yaml` - Dart static analysis configuration using flutter_lints

## Recommended Architecture

### State Management: BLoC vs Riverpod Analysis (2024-2025)

**Recommendation: Riverpod** (with BLoC as viable alternative)

For this complex app with multiple integrations (Firebase + Supabase), marketplace functionality, and planned scalability, the analysis shows:

**Riverpod Advantages:**
- Better for multiple backend integrations (Firebase Auth + Supabase)
- Less boilerplate for the extensive screen count (20+ screens planned)
- Compile-time safety (critical for payment/marketplace operations)
- No context dependency (useful for background operations like scan history, order tracking)
- Excellent testability for marketplace features
- Modern, actively maintained approach

**BLoC Alternative:**
If team already has BLoC expertise:
- Excellent for strict business logic separation
- Proven for enterprise-scale applications
- Clear event → state pattern
- Strong community support

### Proposed Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # Main app widget
│   ├── router/                     # Go Router setup
│   └── theme/                      # App theming
├── core/
│   ├── constants/                  # App constants
│   ├── utils/                      # Utility functions
│   ├── errors/                     # Error handling
│   └── network/                    # HTTP clients
├── features/
│   ├── auth/                       # Authentication
│   │   ├── data/                   # Firebase Auth integration
│   │   ├── domain/                 # Auth business logic
│   │   └── presentation/           # Login/Register screens
│   ├── qr_generation/              # QR Creation
│   │   ├── data/                   # QR generation logic
│   │   ├── domain/                 # QR models & use cases
│   │   └── presentation/           # QR creation screens
│   ├── qr_scanner/                 # QR Scanning
│   ├── qr_library/                 # QR Management
│   ├── templates/                  # Template system
│   ├── marketplace/                # E-commerce
│   │   ├── data/                   # Supabase integration
│   │   ├── domain/                 # Product models
│   │   └── presentation/           # Catalog, cart, checkout
│   ├── orders/                     # Order management
│   └── profile/                    # User profile
└── shared/
    ├── widgets/                    # Reusable widgets
    ├── providers/                  # Global state providers
    └── services/                   # External services
```

### Key Dependencies to Add

```yaml
dependencies:
  # State Management
  flutter_riverpod: ^2.4.9          # or flutter_bloc: ^8.1.3
  
  # Backend Integration
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  supabase_flutter: ^2.0.0
  
  # QR Functionality
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.7            # Modern QR scanner
  
  # Navigation
  go_router: ^13.0.0
  
  # UI Components
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  
  # Animation & Effects (Carden Pro Style)
  flutter_animate: ^4.3.0              # For complex animations
  glassmorphism: ^3.0.0                # Glassmorphism effects
  shimmer: ^3.0.0                      # Loading shimmer effects
  
  # Utilities
  equatable: ^2.0.5
  uuid: ^4.2.1
  share_plus: ^7.2.1
  haptic_feedback: ^3.0.0              # For tactile feedback

dev_dependencies:
  # Testing
  mockito: ^5.4.4
  build_runner: ^2.4.7
```

### Core App Modules

1. **Authentication Module**
   - Firebase Auth integration
   - User registration/login
   - Profile management

2. **QR Generation Module**
   - Multiple QR types (URL, vCard, WiFi, etc.)
   - Visual customization
   - Template system

3. **QR Scanner Module**
   - Camera-based scanning
   - Scan history management
   - Result handling by QR type

4. **Marketplace Module**
   - Product catalog (materials: wood, acrylic, metal, etc.)
   - Shopping cart
   - Checkout process
   - Order tracking

5. **QR Library Module**
   - User's saved QR codes
   - Organization and sharing
   - Edit/duplicate functionality

### Design System

**Visual Design Reference: Carden Pro Mobile App**

QRaft's design system is inspired by the Carden Pro Behance design, adapted for QR code generation and marketplace functionality.

**Color Palette**:
- **Primary Blue**: #1A73E8 (Adapted from Carden Pro's neon green #00FF88)
- **Accent/Success**: #00FF88 (Used for successful scans, confirmations)
- **Dark Base**: #1A1A1A (Primary background, adapted from Carden Pro)
- **Secondary Dark**: #2E2E2E (Cards, modals, secondary backgrounds)
- **Light Background**: #F5F7FA (Light mode alternative)

**Typography**:
- **Primary Font**: SF Pro (iOS) / Roboto (Android)
- **Headers**: Bold, 24-32px
- **Body**: Regular, 16-18px
- **Captions**: Medium, 12-14px

**Spacing System**:
- **Micro**: 4px
- **Small**: 8px
- **Medium**: 16px
- **Large**: 24px
- **XLarge**: 32px
- **XXLarge**: 48px

### UI/UX Design Patterns (2025)

**Recommended Pattern: "Navigation + Cards + Tab Architecture"**

#### 1. Navigation Architecture
- **Bottom Navigation** for main functions: Generate, Scan, Library, Marketplace, Profile
- **Stack Navigation** within each section for complex flows
- **Drawer Navigation** optional for advanced settings

#### 2. Visual Design Patterns (Carden Pro Inspired)
- **Dark-First Design** using #1A1A1A as primary background
- **Glassmorphism Cards** with subtle transparency and blur effects
- **Rounded Corner System**: 12px (small), 16px (medium), 24px (large)
- **Elevated Components** with 4-8px shadows
- **Neon Accent Elements** using #00FF88 for active states
- **Modular Card System** for features like Custom QR, High Accuracy, Quick Actions

#### 3. Component Library (Based on Carden Pro)
- **Action Cards**: Rounded rectangles with icons and descriptions
  - "Custom QR Code" → QR generation options
  - "High Accuracy" → Scanner settings  
  - "Email Signature" → Profile/contact info
- **Quick Action Bar**: Horizontal scrollable actions (Transfer, Scan, Generate, More)
- **Stats Cards**: Income/Expense style cards for scan analytics
- **Progress Indicators**: Circular and linear with neon accent
- **Toggle Buttons**: Recommended/Smart sync style switching
- **Icon System**: Consistent rounded square icons on dark backgrounds

#### 4. Screen Layouts
- **Grid System**: 2-column cards for feature selection
- **List Views**: Clean rows with trailing actions (share, edit, delete)
- **Full-Screen Modals**: Dark overlay with centered content
- **Bottom Sheet**: Rounded top corners, slide-up animations

#### 5. QR-Specific Patterns (Carden Pro Adaptation)
- **QR Preview Cards**: Dark cards with QR code display and neon border on active
- **Scanner Interface**: Full-screen camera with green overlay frame
- **Generation Progress**: Circular progress indicator with #00FF88 accent
- **Share Actions**: Bottom sheet with multiple export options
- **Template Gallery**: Grid layout with preview thumbnails

#### 6. Marketplace UX Patterns
- **Physical Product Cards**: Similar to Carden Pro's credit card display
  - Material preview (wood, acrylic, metal texture)
  - Laser engraving preview overlay
  - Price and specifications
- **Cart Interface**: Slide-up bottom sheet with item list
- **Checkout Flow**: Step indicator with neon progress
- **Order Tracking**: Timeline view with status updates

#### 7. Flutter Implementation Guidelines

**Key Widgets to Use**:
```dart
// Card System
Container(
  decoration: BoxDecoration(
    color: Color(0xFF2E2E2E),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)]
  )
)

// Neon Accent Button
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [Color(0xFF00FF88), Color(0xFF00CC6A)]),
    borderRadius: BorderRadius.circular(12)
  )
)

// Glassmorphism Effect
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16)
    )
  )
)
```

#### 8. 2025 Microinteractions (Carden Pro Style)
- **Haptic Feedback** on successful scan with neon flash
- **Card Hover Effects** with subtle scale and glow
- **Smooth Transitions** between screens (300ms duration)
- **Loading Shimmer** effects on cards during data loading
- **Success Animations** with expanding neon circles
- **Pull-to-Refresh** with custom neon indicator
- **Gesture Navigation** for swipe actions with visual feedback
- **Button Press** animations with scale down (0.95x) and neon glow

#### 9. Animation System
```dart
// Card Press Animation
AnimatedContainer(
  duration: Duration(milliseconds: 150),
  transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
  child: Card(...)
)

// Neon Glow Animation
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  decoration: BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: Color(0xFF00FF88).withOpacity(_isActive ? 0.6 : 0.0),
        blurRadius: _isActive ? 20 : 0,
        spreadRadius: _isActive ? 2 : 0
      )
    ]
  )
)
```

#### 10. Accessibility Features
- **Voice Over** support for screen readers
- **High Contrast** mode option
- **Large Text** scaling support
- **Alternative Text** for all QR codes and images

## Implementation Phases

### Phase 1: MVP (Current Status)
- ✅ Firebase Authentication setup and configuration
- ✅ Professional splash screen with animations
- ✅ Custom logo and app icon generation
- ✅ Project architecture and design system
- ✅ Login/Register screens with Firebase authentication
- ✅ Forgot password functionality with deeplinks
- ✅ GlassButton component library with glassmorphism effects
- ✅ iOS and Android deeplink configuration
- ✅ Keyboard navigation and form validation
- 🔄 Core QR generation (URL, text, personal info)
- 🔄 Simple QR scanner (pending iOS dependency resolution)
- 🔄 Basic marketplace catalog
- 🔄 Simple checkout process

### Phase 2: Enhancement (3-4 months)
- Advanced QR types (WiFi, vCard, events, location)
- QR visual customization
- Template library
- Complete marketplace features
- Order tracking system

### Phase 3: Polish (2-3 months)
- Analytics and usage statistics
- Social sharing features
- Premium features
- Performance optimization
- Advanced customization options

## Database Schema (Supabase)

Key tables:
- `users` - User profiles and preferences
- `qr_codes` - Generated QR codes with metadata
- `templates` - QR design templates
- `scan_history` - User scan records
- `products` - Marketplace catalog
- `orders` - Purchase orders and status
- `order_items` - Individual items in orders

## Dependencies

**Current Implementation Status:**
- ✅ Flutter SDK 3.6.2+
- ✅ Firebase Core & Auth (`firebase_core: ^2.24.2`, `firebase_auth: ^4.15.3`)
- ✅ Riverpod state management (`flutter_riverpod: ^2.4.9`)
- ✅ Advanced animations (`flutter_animate: ^4.3.0`)
- ✅ SVG graphics (`flutter_svg: ^2.0.9`)
- ✅ App icon generation (`flutter_launcher_icons: ^0.13.1`)
- ✅ Flutter lints (`flutter_lints: ^5.0.0`)
- ✅ Carden Pro design system implementation
- ✅ Custom logo with QR and laser elements
- ✅ Splash screen with 8-second animation sequence
- ✅ Authentication module structure (data/domain/presentation)
- ✅ Firebase Authentication with error handling
- ✅ Forgot password with deeplinks (iOS & Android)
- ✅ GlassButton component with glassmorphism effects
- ✅ Form validation and keyboard navigation
- ✅ i18n support (English/Spanish)

**Next Phase Implementation:**
- 🔄 QR generation functionality (`qr_flutter: ^4.1.0`)
- 🔄 QR scanning (`mobile_scanner: ^3.5.7` - pending iOS dependency resolution)
- 🔄 Supabase integration (`supabase_flutter: ^2.0.0`)
- 🔄 Navigation system (`go_router: ^13.0.0`)
- 🔄 Marketplace features

**Production Ready Features:**
- Cross-platform app icons (iOS, Android, Web, Desktop)
- Firebase authentication setup for all platforms
- Professional splash screen with staged animations
- Clean architecture foundation with feature-based modules
- Git repository with comprehensive documentation
- Complete authentication flow with password recovery
- Reusable glassmorphism button component library

## Authentication Implementation Details

### Firebase Configuration
- **Project ID**: qraft-e8a1d
- **Bundle ID**: io.gothcorp.qraft
- **Package Name**: io.gothcorp.qraft
- **Deeplink Domain**: qraft-e8a1d.firebaseapp.com (configured)

### Deeplink Configuration

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="qraft-e8a1d.firebaseapp.com" />
</intent-filter>
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="qraft" />
</intent-filter>
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>qraft</string>
        </array>
    </dict>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>https</string>
        </array>
    </dict>
</array>
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:qraft-e8a1d.firebaseapp.com</string>
</array>
```

### Method Channel Implementation

#### Android (`MainActivity.kt`)
```kotlin
class MainActivity: FlutterActivity() {
    private lateinit var channel: MethodChannel
    private var initialLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "qraft/deeplink")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> result.success(initialLink)
                else -> result.notImplemented()
            }
        }
        
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_VIEW) {
            val link = intent.dataString
            if (link != null) {
                if (::channel.isInitialized) {
                    channel.invokeMethod("routeUpdated", link)
                } else {
                    initialLink = link
                }
            }
        }
    }
}
```

#### iOS (`AppDelegate.swift`)
```swift
@main
@objc class AppDelegate: FlutterAppDelegate {
    private var methodChannel: FlutterMethodChannel?
    private var initialLink: String?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        guard let controller = window?.rootViewController as? FlutterViewController else {
            fatalError("rootViewController is not type FlutterViewController")
        }
        
        methodChannel = FlutterMethodChannel(name: "qraft/deeplink", binaryMessenger: controller.binaryMessenger)
        methodChannel?.setMethodCallHandler(handleMethodCall)
        
        if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
            initialLink = url.absoluteString
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getInitialLink":
            result(initialLink)
            initialLink = nil
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        methodChannel?.invokeMethod("routeUpdated", arguments: url.absoluteString)
        return true
    }
    
    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            methodChannel?.invokeMethod("routeUpdated", arguments: url.absoluteString)
            return true
        }
        return false
    }
}
```

### Firebase Domain Authorization

**Important**: When implementing forgot password functionality, ensure domains are authorized in Firebase Console:

1. Go to Firebase Console → Authentication → Settings
2. Under "Authorized domains", add:
   - `localhost` (for development)
   - `qraft-e8a1d.firebaseapp.com` (default Firebase domain)
   - Your custom domain (if using one)

**Common Error**: "Domain not authorized" - This occurs when the domain in `ActionCodeSettings` is not listed in Firebase authorized domains.

### GlassButton Component

#### Usage
```dart
// Primary button with default gradient
PrimaryGlassButton(
  text: "Sign In",
  onPressed: _handleLogin,
  isLoading: isLoading,
  width: double.infinity,
)

// Custom gradient button
GlassButton(
  text: "Custom",
  onPressed: _handleAction,
  gradientColors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
  width: 200,
  height: 48,
)
```

#### Features
- **Glassmorphism Effect**: BackdropFilter with 15px blur
- **Multi-layer Glow**: Exterior glow without affecting button size
- **Loading States**: Animated CircularProgressIndicator
- **Customizable**: Colors, gradients, dimensions, border radius
- **Variants**: Primary, Secondary, Success pre-configured
- **Accessibility**: Full VoiceOver support

The component replaces all gradient buttons across the app for consistency.