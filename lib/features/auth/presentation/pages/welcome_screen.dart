import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/qraft_logo.dart';
import '../../../../shared/widgets/glass_button.dart';
import 'package:qraft/l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onLoginPressed;
  final VoidCallback onSignUpPressed;

  const WelcomeScreen({
    super.key,
    required this.onLoginPressed,
    required this.onSignUpPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Background particles - fireflies effect
          ...List.generate(15, (index) => _buildBackgroundParticle(index)),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
              const SizedBox(height: 60),
              
              // Logo and Title Section
              _buildHeaderSection(context, l10n).animate()
                .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
                .slideY(begin: 0.15, duration: 400.ms, curve: Curves.easeOutQuart),
              
              const SizedBox(height: 60),
              
              // Features Section - Vertical Layout
              _buildFeaturesSection(context, l10n).animate()
                .fadeIn(duration: 300.ms, delay: 200.ms, curve: Curves.easeOutCubic)
                .slideY(begin: 0.15, duration: 300.ms, delay: 200.ms, curve: Curves.easeOutQuart),
              
              const SizedBox(height: 60),
              
              // Action Buttons
              _buildActionButtons(context, l10n).animate()
                .fadeIn(duration: 300.ms, delay: 400.ms, curve: Curves.easeOutCubic)
                .slideY(begin: 0.15, duration: 300.ms, delay: 400.ms, curve: Curves.easeOutQuart),
              
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        // Logo with enhanced glow
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A73E8), Color(0xFF00FF88)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF88).withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const QRaftLogo(
            size: 80,
            primaryColor: Colors.white,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // App Title
        Text(
          l10n.welcomeTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 36,
            letterSpacing: -1,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.welcomeSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[300],
              fontSize: 18,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        // Features Introduction
        Text(
          l10n.mainFeatures,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Feature Cards - Vertical Layout
        _buildFeatureCard(
          icon: Icons.qr_code_2_rounded,
          title: l10n.featureCreateTitle,
          description: l10n.featureCreateDescription,
          gradient: const LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
          ),
        ),
        
        const SizedBox(height: 24),
        
        _buildFeatureCard(
          icon: Icons.share_rounded,
          title: l10n.featureShareTitle,
          description: l10n.featureShareDescription,
          gradient: const LinearGradient(
            colors: [Color(0xFF00FF88), Color(0xFF00CC6A)],
          ),
        ),
        
        const SizedBox(height: 24),
        
        _buildFeatureCard(
          icon: Icons.precision_manufacturing_rounded,
          title: l10n.featureEngraveTitle,
          description: l10n.featureEngraveDescription,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
  }) {
    return Container(
      width: double.infinity,
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
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        // Primary Button - Sign Up
        PrimaryGlassButton(
          text: l10n.getStarted,
          onPressed: onSignUpPressed,
          width: double.infinity,
        ),
        
        const SizedBox(height: 16),
        
        // Secondary Button - Login
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: onLoginPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.grey[600]!,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              l10n.alreadyHaveAccount,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundParticle(int index) {
    final positions = [
      const Offset(50, 120),
      const Offset(300, 180),
      const Offset(80, 350),
      const Offset(250, 450),
      const Offset(160, 280),
      const Offset(320, 320),
      const Offset(40, 550),
      const Offset(280, 650),
      const Offset(190, 500),
      const Offset(340, 220),
      const Offset(120, 400),
      const Offset(260, 600),
      const Offset(70, 750),
      const Offset(310, 800),
      const Offset(150, 150),
    ];

    final position = positions[index % positions.length];
    final delay = (index * 200).milliseconds;
    final size = (index % 3 == 0) ? 6.0 : 4.0; // Vary sizes
    final opacity = (index % 2 == 0) ? 0.15 : 0.08; // Vary opacity

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF00FF88).withValues(alpha: opacity),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF88).withValues(alpha: opacity * 0.6),
              blurRadius: size,
              spreadRadius: 1,
            ),
          ],
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fadeIn(duration: 1500.ms, delay: delay, curve: Curves.easeInOutCubic)
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1.5, 1.5),
          duration: 2000.ms,
          delay: delay,
          curve: Curves.easeInOutCubic,
        )
        .then() // Chain another animation
        .moveY(
          begin: 0,
          end: -20,
          duration: 4000.ms,
          curve: Curves.easeInOut,
        ),
    );
  }
}