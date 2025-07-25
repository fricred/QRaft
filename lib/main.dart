import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/presentation/pages/auth_flow.dart';
import 'features/auth/data/providers/supabase_auth_provider.dart';
import 'features/main/main_scaffold.dart';
import 'core/services/deeplink_service.dart';
import 'core/services/supabase_service.dart';
import 'core/config/env_config.dart';
import 'core/providers/locale_provider.dart';
import 'package:qraft/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase before starting the app
  await initializeApp();
  
  runApp(const ProviderScope(child: QRaftApp()));
}

Future<void> initializeApp() async {
  try {
    // Debug environment configuration
    EnvConfig.debugConfig();
    
    // Initialize Supabase only
    await SupabaseService.initialize();
    debugPrint('✅ QRaft initialized with Supabase-only authentication');
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
    
    return MaterialApp(
      title: 'QRaft',
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
          : const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = ref.watch(supabaseAuthProvider);
    final currentUser = authProvider.currentUser;
    
    // Initialize deeplink handler
    ref.watch(deepLinkHandlerProvider);
    
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
        _showSupabaseForgotPasswordDialog(context, authProvider);
      },
    );
  }
  
  void _showSupabaseForgotPasswordDialog(BuildContext context, SupabaseAuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => SupabaseForgotPasswordDialog(authProvider: authProvider),
    );
  }
}

class SupabaseForgotPasswordDialog extends StatefulWidget {
  final SupabaseAuthProvider authProvider;
  
  const SupabaseForgotPasswordDialog({
    super.key,
    required this.authProvider,
  });

  @override
  State<SupabaseForgotPasswordDialog> createState() => _SupabaseForgotPasswordDialogState();
}

class _SupabaseForgotPasswordDialogState extends State<SupabaseForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendResetEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      await widget.authProvider.resetPassword(_emailController.text);
      
      if (widget.authProvider.errorMessage == null) {
        setState(() {
          _emailSent = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_emailSent) ...[
              Icon(
                Icons.lock_reset,
                color: const Color(0xFF1A73E8),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Reset Password',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1A73E8)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[400]!),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[400]!),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.authProvider.isLoading ? null : _handleSendResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: widget.authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Send Reset Email'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Icon(
                Icons.mark_email_read,
                color: const Color(0xFF00FF88),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Email Sent!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your email for a password reset link.',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

