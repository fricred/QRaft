import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/qraft_logo.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';
import 'package:qraft/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final Function(String email, String password) onLogin;
  final VoidCallback onSignUpPressed;
  final VoidCallback onForgotPasswordPressed;
  final VoidCallback onBackPressed;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onSignUpPressed,
    required this.onForgotPasswordPressed,
    required this.onBackPressed,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      await widget.onLogin(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = ref.watch(supabaseAuthProvider);
    final isLoading = authProvider.isLoading;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Background particles
          ...List.generate(8, (index) => _buildBackgroundParticle(index)),
          
          SafeArea(
            child: Column(
              children: [
                // Top section with back button and header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Back button row
                      Row(
                        children: [
                          IconButton(
                            onPressed: widget.onBackPressed,
                            icon: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF2E2E2E),
                              padding: const EdgeInsets.all(10),
                              minimumSize: const Size(40, 40),
                            ),
                          ).animate()
                            .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                            .slideX(begin: -0.15, duration: 300.ms, curve: Curves.easeOutQuart),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Compact header
                      Row(
                        children: [
                          // Small logo
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A73E8), Color(0xFF00FF88)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const QRaftLogo(
                              size: 32,
                              primaryColor: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Title and subtitle in row
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.welcomeBack,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.signInToContinue,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate()
                        .fadeIn(duration: 300.ms, delay: 100.ms, curve: Curves.easeOutCubic)
                        .slideY(begin: 0.15, duration: 300.ms, delay: 100.ms, curve: Curves.easeOutQuart),
                    ],
                  ),
                ),
                
                // Form section - takes remaining space
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          
                          // Form container
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E2E2E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Email field
                                _buildTextField(
                                  l10n: l10n,
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  label: l10n.email,
                                  hint: l10n.enterEmail,
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: () => _passwordFocusNode.requestFocus(),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.pleaseEnterEmail;
                                    }
                                    if (!value.contains('@')) {
                                      return l10n.pleaseEnterValidEmail;
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Password field
                                _buildTextField(
                                  l10n: l10n,
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  label: l10n.password,
                                  hint: l10n.enterPassword,
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: _handleLogin,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                    icon: Icon(
                                      _obscurePassword 
                                        ? Icons.visibility_off_outlined 
                                        : Icons.visibility_outlined,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.pleaseEnterPassword;
                                    }
                                    if (value.length < 6) {
                                      return l10n.passwordMinLength;
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: widget.onForgotPasswordPressed,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: Text(
                                      l10n.forgotPassword,
                                      style: TextStyle(
                                        color: const Color(0xFF00FF88),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Login button
                                PrimaryGlassButton(
                                  text: l10n.signIn,
                                  onPressed: _handleLogin,
                                  isLoading: isLoading,
                                  width: double.infinity,
                                ),
                              ],
                            ),
                          ).animate()
                            .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOutCubic)
                            .slideY(begin: 0.15, duration: 400.ms, delay: 200.ms, curve: Curves.easeOutQuart),
                          
                          const SizedBox(height: 24),
                          
                          // Sign up link
                          TextButton(
                            onPressed: widget.onSignUpPressed,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              l10n.dontHaveAccount,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ).animate()
                            .fadeIn(duration: 300.ms, delay: 300.ms, curve: Curves.easeOutCubic),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required AppLocalizations l10n,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00FF88), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }


  Widget _buildBackgroundParticle(int index) {
    final positions = [
      const Offset(50, 150),
      const Offset(300, 200),
      const Offset(80, 400),
      const Offset(250, 500),
      const Offset(150, 300),
      const Offset(320, 350),
      const Offset(40, 600),
      const Offset(280, 700),
    ];

    final position = positions[index % positions.length];
    final delay = (index * 300).milliseconds;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFF00FF88).withValues(alpha: 0.15),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF88).withValues(alpha: 0.1),
              blurRadius: 3,
            ),
          ],
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fadeIn(duration: 1500.ms, delay: delay, curve: Curves.easeInOutCubic)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.2, 1.2),
          duration: 2000.ms,
          delay: delay,
          curve: Curves.easeInOutCubic,
        ),
    );
  }
}