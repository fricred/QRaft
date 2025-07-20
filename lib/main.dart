import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/presentation/pages/auth_flow.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/data/providers/auth_provider.dart';
import 'features/auth/presentation/widgets/forgot_password_dialog.dart';
import 'features/main/main_scaffold.dart';
import 'core/services/deeplink_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: QRaftApp()));
}

Future<void> initializeApp() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized, continue
    // Firebase already initialized, continue
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
    // Initialize Firebase in background but don't wait for it
    initializeApp();
    
    // Initialize deeplink handler
    Future.microtask(() {
      ref.read(deepLinkHandlerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRaft',
      debugShowCheckedModeBanner: false,
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
        cardTheme: CardTheme(
          color: const Color(0xFF2E2E2E),
          elevation: 8,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
          : const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authController = ref.read(authControllerProvider.notifier);
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) {
        if (user != null) {
          // User is authenticated, show home screen
          return const MainScaffold();
        } else {
          // User is not authenticated, show auth flow
          return AuthFlowWithListeners(
            l10n: l10n,
            authController: authController,
          );
        }
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
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
                error.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthFlowWithListeners extends ConsumerWidget {
  final AppLocalizations l10n;
  final AuthController authController;

  const AuthFlowWithListeners({
    super.key,
    required this.l10n,
    required this.authController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state changes for UI feedback
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
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
                authController.clearError();
                ScaffoldMessenger.of(context).clearSnackBars();
              },
            ),
          ),
        );
      }
    });
    
    return AuthFlow(
      onLogin: (email, password) async {
        await authController.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      },
      onSignUp: (name, email, password) async {
        await authController.createUserWithEmailAndPassword(
          email: email,
          password: password,
          displayName: name,
        );
      },
      onForgotPassword: () {
        showForgotPasswordDialog(context);
      },
    );
  }
}

