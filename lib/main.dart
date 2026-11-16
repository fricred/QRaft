import 'package:flutter/foundation.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
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
import 'features/auth/presentation/pages/reset_password_screen.dart';
import 'features/auth/data/providers/supabase_auth_provider.dart';
import 'core/utils/friendly_error.dart';
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

  _enableAndroidPhotoPicker();

  // Initialize Supabase before starting the app
  await initializeApp();

  // QRAFT-3: know before the first frame whether a password recovery is pending.
  await SupabaseAuthProvider.preloadRecoveryFlag();

  // Register background message handler BEFORE runApp.
  // FCM requires this to be called as early as possible so the background
  // isolate can be attached before the app is fully started.
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

  runApp(const ProviderScope(child: QRaftApp()));
}

/// Opts every `image_picker` gallery call into the Android Photo Picker.
///
/// image_picker_android still defaults `useAndroidPhotoPicker` to false and
/// falls back to the legacy ACTION_GET_CONTENT chooser. The Photo Picker is the
/// selector Google's Photo and Video Permissions policy points apps at for
/// one-off picks: it needs no runtime permission, and it is backported to older
/// releases through Google Play services. The flag is global, so setting it
/// once here covers every pickImage call in the app.
void _enableAndroidPhotoPicker() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  final picker = ImagePickerPlatform.instance;
  if (picker is ImagePickerAndroid) {
    picker.useAndroidPhotoPicker = true;
  }
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
    // Messages built without a BuildContext (auth errors, notices) follow the app's
    // chosen language, not the OS one.
    appLanguageCode = locale.languageCode;

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
  bool _recoveryRoutesCleared = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = ref.watch(supabaseAuthProvider);
    final currentUser = authProvider.currentUser;

    // Initialize deeplink handler
    ref.watch(deepLinkHandlerProvider);

    // Initialize RevenueCat, Subscription Realtime, and FCM when user authenticates
    // A recovery session for another account while someone was signed in: stop the
    // previous user's services so nothing stays bound to them during the reset.
    if (authProvider.isRecovering && _lastUserId != null && _lastUserId != currentUser?.id) {
      _lastUserId = null;
      Future.microtask(() {
        stopSubscriptionRealtime(ref);
        logoutRevenueCat(ProviderScope.containerOf(context, listen: false));
        ObservabilityService.clearUserId();
      });
    }

    // Not for a password-recovery session: services start once a real session exists.
    if (currentUser != null && !authProvider.isRecovering && _lastUserId != currentUser.id) {
      _lastUserId = currentUser.id;
      Future.microtask(() {
        initializeRevenueCat(ProviderScope.containerOf(context, listen: false), currentUser.id);
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
        // Unbind RevenueCat from the signed-out user so a shared device never shows or
        // records purchases against them.
        logoutRevenueCat(ProviderScope.containerOf(context, listen: false));
        // Clear observability user identity on sign-out.
        ObservabilityService.clearUserId();
      });
    }

    if (!authProvider.isRecovering) _recoveryRoutesCleared = false;
    // QRAFT-3: a recovery link opens a temporary session; force a new-password step.
    if (authProvider.isRecovering) {
      // Close any route pushed above home (editor, sheets, dialogs) so the recovery
      // session cannot keep using the app without choosing a new password.
      // Only once per recovery, so dialogs the reset screen opens are not closed later.
      if (!_recoveryRoutesCleared) {
        _recoveryRoutesCleared = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
        });
      }
      return const ResetPasswordScreen();
    }

    // A request while signed in (e.g. sign-out) still uses the full-screen spinner.
    if (authProvider.isLoading && currentUser != null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
          ),
        ),
      );
    }

    if (currentUser != null) {
      // Errors raised while signed in (e.g. sign-out failing offline) still need a
      // visible message; the auth-flow listener is not mounted here.
      final notice = authProvider.takeNotice();
      if (notice != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(notice, style: const TextStyle(color: Colors.white, fontSize: 14)),
              backgroundColor: const Color(0xFF14532D),
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
      final error = authProvider.takeErrorForSnackbar();
      if (error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(error, style: const TextStyle(color: Colors.white, fontSize: 14)),
              backgroundColor: const Color(0xFFB42318),
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
      return const MainScaffold();
    }

    // QRAFT-4: the auth flow is ALWAYS the first child of the same Stack, so a login or
    // sign-up in flight only adds an overlay and never rebuilds AuthFlow (which would reset
    // the user to the welcome screen and drop what they typed). Errors and notices are
    // shown by AuthFlowWithListeners' listener, once per change.
    return Stack(
      children: [
        AuthFlowWithListeners(l10n: l10n, authProvider: authProvider),
        if (authProvider.isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x99000000),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
                ),
              ),
            ),
          ),
      ],
    );
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
      // Each error is shown once, after its request finished (the provider tracks it;
      // previous/next are the same ChangeNotifier instance, so they can't be compared).
      final error = next.takeErrorForSnackbar();
      if (error != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            backgroundColor: const Color(0xFFB42318),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            // QRAFT-15: an unconfirmed account gets a way out: resend the email.
            action: next.unconfirmedEmail != null
                ? SnackBarAction(
                    label: Localizations.localeOf(context).languageCode == 'es'
                        ? 'Reenviar correo'
                        : 'Resend email',
                    textColor: Colors.white,
                    onPressed: () => authProvider.resendConfirmation(),
                  )
                : SnackBarAction(
                    label: MaterialLocalizations.of(context).closeButtonLabel,
                    textColor: Colors.white,
                    onPressed: () {
                      authProvider.clearError();
                      ScaffoldMessenger.of(context).clearSnackBars();
                    },
                  ),
            duration: Duration(seconds: next.unconfirmedEmail != null ? 10 : 4),
          ),
        );
      }

      // Non-error notices (e.g. "confirm your email" after sign-up), shown once.
      final notice = next.takeNotice();
      if (notice != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notice),
            backgroundColor: const Color(0xFF14532D),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
