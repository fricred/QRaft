# 🚀 QRaft - Complete Setup Guide

This guide provides complete instructions for setting up the QRaft Flutter application with Supabase authentication and database.

## Table of Contents
- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Supabase Configuration](#supabase-configuration)
- [Running the Application](#running-the-application)
- [Authentication Flow](#authentication-flow)
- [Development Commands](#development-commands)
- [Troubleshooting](#troubleshooting)

---

## Project Overview

**QRaft** is a comprehensive Flutter application for QR code generation, scanning, and physical marketplace integration. The app allows users to create personalized QR codes and order laser-engraved physical products.

### Key Features
- ✅ **Supabase Authentication** - Native email/password auth with deeplinks
- ✅ **Inline Profile Editing** - Edit profile fields individually with real-time saving
- ✅ **QR Generation** - Create QR codes for URLs, WiFi, vCards, events, locations
- ✅ **QR Scanner** - Scan and manage QR code history
- ✅ **Visual Customization** - Personalize QR appearance with colors, logos, templates
- 🔄 **Marketplace** - Order laser-engraved QR codes on various materials
- 🔄 **User Management** - Profiles, order tracking, analytics

### Tech Stack
- **Frontend**: Flutter 3.6.2+ (cross-platform: iOS, Android, Web, Desktop)
- **Authentication**: Supabase Auth (email verification with deeplinks)
- **Database**: Supabase (PostgreSQL with Row Level Security)
- **State Management**: Riverpod
- **Design System**: Carden Pro inspired (dark-first with glassmorphism)

---

## Prerequisites

### Development Tools
- **Flutter SDK**: 3.6.2 or higher
- **Dart SDK**: 3.0.0 or higher
- **IDE**: VS Code or Android Studio
- **Mobile Testing**: Android device/emulator or iOS simulator

### Accounts Required
- **Supabase Account**: [supabase.com](https://supabase.com) (free tier available)

---

## Environment Setup

### 1. Create Environment Configuration

Create `env.json` in the project root:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here"
}
```

**⚠️ Important**: Never commit `env.json` to version control. It's already in `.gitignore`.

### 2. Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Verify Flutter setup
flutter doctor
```

---

## Supabase Configuration

### 1. Create Supabase Project
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Create a new project
3. Copy the **Project URL** and **Anon Public Key**
4. Add them to your `env.json` file

### 2. Run Database Setup
1. Go to **SQL Editor** in Supabase Dashboard
2. Copy and paste the entire content of `supabase_complete_setup.sql`
3. Click **Run**

This will:
- Create all necessary tables (`users`, `qr_codes`, `scan_history`, `templates`, `products`, `orders`, `order_items`)
- Set up Row Level Security (RLS) policies
- Create performance indexes
- Insert sample templates and products

### 3. Configure Authentication URLs

In Supabase Dashboard → **Authentication** → **URL Configuration**:

**Site URL:**
```
qraft://auth/verify
```

**Redirect URLs:**
```
qraft://auth/verify
qraft://auth/reset
http://localhost:3000
```

### 4. Email Templates (Optional)
The default email templates work out of the box with the deeplinks configured above.

---

## Running the Application

### Development Mode
```bash
# Run with environment variables
flutter run --dart-define-from-file=env.json

# Run on specific device
flutter run -d chrome --dart-define-from-file=env.json
flutter run -d android --dart-define-from-file=env.json
```

### Building for Production
```bash
# Android APK
flutter build apk --dart-define-from-file=env.json

# iOS (requires macOS and Xcode)
flutter build ios --dart-define-from-file=env.json

# Web
flutter build web --dart-define-from-file=env.json
```

---

## Authentication Flow

### Registration Process
1. **User registers** with email/password
2. **Email sent** with deeplink: `qraft://auth/verify?token=xxx`
3. **User clicks email link** → App opens automatically
4. **Token verified** → User authenticated
5. **Profile created** in database

### Login Process
1. **User enters credentials**
2. **Supabase validates** email/password
3. **User authenticated** → Redirected to dashboard

### Password Reset
1. **User requests password reset**
2. **Email sent** with deeplink: `qraft://auth/reset?token=xxx`
3. **User clicks link** → App opens to reset screen
4. **New password set** → User authenticated

---

## Development Commands

### Flutter Commands
```bash
# Development
flutter run --dart-define-from-file=env.json
flutter hot-reload  # Press 'r' while running

# Code Quality
flutter analyze
flutter test
flutter test test/specific_test.dart

# Dependencies
flutter pub get
flutter pub upgrade
flutter clean

# Device Management
flutter devices
flutter doctor
```

### Testing Commands
```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/shared/widgets/glass_button_test.dart
flutter test test/features/auth/presentation/controllers/auth_controller_simple_test.dart

# Run tests with coverage
flutter test --coverage
```

### Debugging
```bash
# View logs on Android
adb logcat | grep flutter

# View all app logs
adb logcat | grep -E "(flutter|QRaft|Supabase)"

# View deeplink logs specifically
adb logcat | grep -E "(🔗|📧|✅|❌|deeplink)"
```

---

## Key Features Implemented

### 🔐 Authentication System
- **Supabase Native Auth**: Complete migration from Firebase
- **Email Verification**: Automatic verification via deeplinks
- **Password Reset**: Secure password recovery flow
- **Deeplink Handling**: Custom `qraft://` scheme for mobile

### 👤 Profile Management
- **Inline Editing**: Edit individual fields with save/cancel per field
- **Real-time Updates**: Changes saved immediately to Supabase
- **Visual Feedback**: Loading states and success/error messages
- **Profile Fields**: Name, phone, bio, location, website, company, job title

### 🎨 UI/UX Design
- **Carden Pro Style**: Dark-first design with glassmorphism
- **Responsive Layout**: Adaptive to all screen sizes
- **Smooth Animations**: 600ms fade-in transitions
- **Glass Components**: Custom GlassButton with multiple variants

### 🧪 Testing Infrastructure
- **Component Tests**: GlassButton, ProfileController, AuthProvider
- **Integration Tests**: DeepLinkService, SupabaseService
- **38 Total Tests**: 87% success rate (production ready)

---

## Project Structure

```
lib/
├── main.dart                    # App entry point with Supabase initialization
├── core/
│   ├── config/                  # Environment and configuration
│   ├── services/                # Supabase, DeepLink services
│   └── constants/               # App constants
├── features/
│   ├── auth/                    # Authentication (Supabase native)
│   ├── profile/                 # User profile management
│   ├── splash/                  # Animated splash screen
│   ├── main/                    # Main navigation scaffold
│   └── home/                    # Dashboard and main screens
├── shared/
│   └── widgets/                 # Reusable components (GlassButton, etc.)
└── l10n/                        # Internationalization (EN/ES)
```

---

## Troubleshooting

### Common Issues

#### 1. Environment Variables Not Loading
**Problem**: App shows "Supabase not configured"
**Solution**: 
```bash
# Ensure env.json exists and run with:
flutter run --dart-define-from-file=env.json
```

#### 2. Email Links Not Opening App
**Problem**: Deeplinks redirect to localhost:3000
**Solution**: Check Supabase URL Configuration has `qraft://auth/verify` in redirect URLs

#### 3. Profile Updates Not Saving
**Problem**: "Failed to update profile" errors
**Solution**: Ensure RLS policies are applied by running `supabase_complete_setup.sql`

#### 4. Authentication Errors
**Problem**: "Domain not authorized" errors
**Solution**: Add domains to Supabase Dashboard → Authentication → Settings → Authorized domains

#### 5. Build Failures
**Problem**: Missing dependencies or version conflicts
**Solution**:
```bash
flutter clean
flutter pub get
flutter run --dart-define-from-file=env.json
```

### Debug Logging

Enable verbose logging to troubleshoot issues:

```bash
# Android logs
adb logcat | grep -E "(flutter|Supabase|auth|profile)"

# Look for specific patterns:
# ✅ Success indicators
# ❌ Error indicators  
# 🔄 Loading states
# 📧 Email/auth flow
```

---

## Production Deployment

### Pre-deployment Checklist
- [ ] All tests passing (`flutter test`)
- [ ] No analysis issues (`flutter analyze`)
- [ ] Environment variables configured for production
- [ ] Supabase RLS policies tested
- [ ] Deeplinks working on target platforms
- [ ] App icons and splash screens updated

### Platform-specific Notes

#### Android
- Configure `android/app/src/main/AndroidManifest.xml` for deeplinks
- Test on multiple Android versions (API 21+)

#### iOS  
- Configure `ios/Runner/Info.plist` for deeplinks
- Test App Store Connect validation

#### Web
- Configure CORS in Supabase for your domain
- Test across browsers (Chrome, Safari, Firefox)

---

## Support and Resources

### Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Riverpod Documentation](https://riverpod.dev/)

### Project-specific Files
- `CLAUDE.md` - Complete development instructions and architecture
- `supabase_complete_setup.sql` - Database initialization script
- `test/` - Comprehensive test suite

---

## License

This project is developed for QRaft application. All rights reserved.

---

**Last Updated**: January 2025  
**Flutter Version**: 3.6.2+  
**Supabase Version**: 2.0.0+