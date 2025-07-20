import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthFlow extends StatefulWidget {
  final Function(String email, String password) onLogin;
  final Function(String name, String email, String password) onSignUp;
  final VoidCallback onForgotPassword;

  const AuthFlow({
    super.key,
    required this.onLogin,
    required this.onSignUp,
    required this.onForgotPassword,
  });

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  int _currentIndex = 0; // 0: Welcome, 1: Login, 2: SignUp

  void _navigateToLogin() {
    setState(() => _currentIndex = 1);
  }

  void _navigateToSignUp() {
    setState(() => _currentIndex = 2);
  }

  void _navigateToWelcome() {
    setState(() => _currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        // Welcome Screen
        WelcomeScreen(
          onLoginPressed: _navigateToLogin,
          onSignUpPressed: _navigateToSignUp,
        ),
        
        // Login Screen
        LoginScreen(
          onLogin: widget.onLogin,
          onSignUpPressed: _navigateToSignUp,
          onForgotPasswordPressed: widget.onForgotPassword,
          onBackPressed: _navigateToWelcome,
        ),
        
        // Sign Up Screen
        SignUpScreen(
          onSignUp: widget.onSignUp,
          onLoginPressed: _navigateToLogin,
          onBackPressed: _navigateToWelcome,
        ),
      ],
    );
  }
}