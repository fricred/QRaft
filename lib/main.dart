import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/services/observability_service.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/presentation/pages/auth_flow.dart';
import 'features/auth/presentation/widgets/forgot_password_dialog.dart';
import 'features/auth/data/providers/supabase_auth_provider.dart';
import 'features/main/main_scaffold.dart';
import 'features/subscription/presentation/providers/purchase_providers.dart';
import 'features/ads/presentation/providers/ad_providers.dart';
import 'features/consent/presentation/providers/consent_providers.dart';
import 'features/consent/presentation/widgets/ump_gate.dart';
import 'core/services/deeplink_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/supabase_service.dart';
import 'core/config/env_config.dart';
import 'core/providers/locale_provider.dart';
import 'package:qraft/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase before starting the app
  await initializeApp();

  // Register background message handler BEFORE runApp.
  // FCM requires this to be called as early as possible so the background
  // isolate can be attached before the app is fully started.
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

  runApp(const ProviderScope(child: QRaftApp()));
}

Future<void> initializeApp() async {
  try {
    // Debug environment configuration
    EnvConfig.debugConfig();

    // Initialize Supabase only
    await SupabaseService.initialize();
    debugPrint('✅ QRaft initialized with Supabase-only authentication');

    // Initialize Firebase (Phase 1: minimum wiring per D-01)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');

    // Wire Crashlytics + Analytics error handlers (D-01: activated Phase 12).
    FlutterError.onError = ObservabilityService.onFlutterError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // NOTE: AdMob SDK init is intentionally NOT called here (D-04). UMP
    // consent must resolve first; AdMob init is triggered via
    // adMobInitProvider once umpConsentReadyProvider flips true (see
    // ref.listen in _QRaftAppState.build below).
  } catch (e) {
    // Service already initialized or error occurred, continue
    debugPrint('Initialization error: $e');
  }
}

class QRaftApp extends ConsumerStatefulWidget {
  const QRaftApp({super.key});

  @override
  ConsumerState<QRaftApp> createState() => _QRaftAppState();
}

class _QRaftAppState extends ConsumerState<QRaftApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize deeplink handler after widget is built
    Future.microtask(() {
      ref.read(deepLinkHandlerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    // Trigger AdMob init only after UMP resolves. (D-04)
    // adMobInitProvider is idempotent (see AdMobService.initialize()).
    ref.listen<bool>(umpConsentReadyProvider, (prev, next) {
      if (next == true && prev != true) {
        // UMP just resolved — kick off AdMob init.
        ref.read(adMobInitProvider.future);
      }
    });

    return MaterialApp(
      title: 'QRaft',
      navigatorKey: appNavigatorKey, // used by DeepLinkHandler for payment-result cold-launch
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('es', ''), // Spanish
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        cardTheme: const CardThemeData(
          color: Color(0xFF2E2E2E),
          elevation: 8,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        useMaterial3: true,
      ),
      home: _showSplash
          ? SplashScreen(
              onInitializationComplete: () {
                setState(() {
                  _showSplash = false;
                });
              },
            )
          // UmpGate ensures UMP consent resolves before AuthWrapper mounts.
          : const UmpGate(child: AuthWrapper()),
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = ref.watch(supabaseAuthProvider);
    final currentUser = authProvider.currentUser;

    // Initialize deeplink handler
    ref.watch(deepLinkHandlerProvider);

    // Initialize RevenueCat, Subscription Realtime, and FCM when user authenticates
    if (currentUser != null && _lastUserId != currentUser.id) {
      _lastUserId = currentUser.id;
      Future.microtask(() {
        initializeRevenueCat(ref, currentUser.id);
        startSubscriptionRealtime(ref, currentUser.id);
        // Register FCM token now that a user is signed in (Phase 10 plan 01).
        ref.read(fcmServiceProvider).initialize();
        // Identify user in Crashlytics + Analytics (D-01, Phase 12).
        ObservabilityService.setUserId(currentUser.id);
      });
    }

    // Stop realtime listener when user logs out
    if (currentUser == null && _lastUserId != null) {
      _lastUserId = null;
      Future.microtask(() {
        stopSubscriptionRealtime(ref);
        // Clear observability user identity on sign-out.
        ObservabilityService.clearUserId();
      });
    }

    if (authProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
          ),
        ),
      );
    }
    
    if (authProvider.errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[400],
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Error',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    if (currentUser != null) {
      // User is authenticated, show home screen
      return const MainScaffold();
    } else {
      // User is not authenticated, show auth flow
      return AuthFlowWithListeners(
        l10n: l10n,
        authProvider: authProvider,
      );
    }
  }
}

class AuthFlowWithListeners extends ConsumerWidget {
  final AppLocalizations l10n;
  final SupabaseAuthProvider authProvider;

  const AuthFlowWithListeners({
    super.key,
    required this.l10n,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth provider changes for UI feedback
    ref.listen<SupabaseAuthProvider>(supabaseAuthProvider, (previous, next) {
      // Clear any previous error messages
      if (previous?.errorMessage != null && next.errorMessage == null) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
      
      // Show error messages
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                authProvider.clearError();
                ScaffoldMessenger.of(context).clearSnackBars();
              },
            ),
          ),
        );
      }
    });
    
    return AuthFlow(
      onLogin: (email, password) async {
        await authProvider.signIn(
          email: email,
          password: password,
        );
      },
      onSignUp: (name, email, password) async {
        await authProvider.signUp(
          email: email,
          password: password,
          displayName: name,
        );
      },
      onForgotPassword: () {
        // Uses the refactored ForgotPasswordDialog (lib/features/auth/presentation/widgets/
        // forgot_password_dialog.dart) which is wired to ForgotPasswordController via Riverpod
        // and exposes the Maestro selectors (forgot_password_dialog_root, forgot_password_email_field,
        // forgot_password_send_button, forgot_password_cancel_button, forgot_password_success_state).
        showForgotPasswordDialog(context);
      },
    );
  }
}
