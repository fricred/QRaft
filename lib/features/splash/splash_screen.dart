import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/widgets/qraft_logo.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const SplashScreen({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();

    // Complete initialization after 2.5 seconds (optimized)
    Future.delayed(const Duration(milliseconds: 2500), () {
      widget.onInitializationComplete();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Animated background particles
          ...List.generate(20, (index) => _buildParticle(index)),
          
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated QR logo with glow effect
                AnimatedBuilder(
                  animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1A73E8),
                              const Color(0xFF00FF88),
                            ],
                            transform: GradientRotation(_rotationAnimation.value),
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
                    );
                  },
                ).animate()
                  .scale(begin: const Offset(0.0, 0.0), end: const Offset(1.0, 1.0), duration: 500.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic),
                
                const SizedBox(height: 32),
                
                // App name with typing animation
                Text(
                  'QRaft',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                ).animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.15, duration: 400.ms, delay: 200.ms, curve: Curves.easeOutQuart),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'QR Code Generation & Marketplace',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ).animate()
                  .fadeIn(duration: 400.ms, delay: 500.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.15, duration: 400.ms, delay: 500.ms, curve: Curves.easeOutQuart),
                
                const SizedBox(height: 48),
                
                // Loading indicator
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                        .scaleX(
                          begin: 0,
                          duration: 1800.ms,
                          curve: Curves.easeInOutCubic,
                        ),
                    ],
                  ),
                ).animate()
                  .fadeIn(duration: 300.ms, delay: 800.ms, curve: Curves.easeOutCubic),
                
                const SizedBox(height: 16),
                
                // Loading text
                Text(
                  'Initializing...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF00FF88),
                    fontWeight: FontWeight.w500,
                  ),
                ).animate()
                  .fadeIn(duration: 300.ms, delay: 1000.ms, curve: Curves.easeOutCubic)
                  .shimmer(duration: 1500.ms, delay: 1200.ms),
              ],
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = Random(index);
    final size = random.nextDouble() * 4 + 2;
    final opacity = random.nextDouble() * 0.3 + 0.1;
    final duration = random.nextInt(3000) + 2000;
    
    return Positioned(
      left: random.nextDouble() * 400 + 50, // Fixed width instead of MediaQuery
      top: random.nextDouble() * 800 + 50,  // Fixed height instead of MediaQuery
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF00FF88).withValues(alpha: opacity),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF88).withValues(alpha: opacity * 0.5),
              blurRadius: 4,
            ),
          ],
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fadeIn(duration: Duration(milliseconds: duration))
        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), duration: Duration(milliseconds: duration)),
    );
  }
}