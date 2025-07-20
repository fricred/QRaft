import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import '../auth/data/providers/auth_provider.dart';
import '../../shared/widgets/qraft_logo.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final authController = ref.read(authControllerProvider.notifier);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Background particles
          ...List.generate(6, (index) => _buildBackgroundParticle(index)),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
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
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            if (currentUser?.displayName != null)
                              Text(
                                'Welcome back, ${currentUser!.displayName}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Profile/Settings button
                      IconButton(
                        onPressed: () async {
                          await authController.signOut();
                        },
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF2E2E2E),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ).animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(begin: -0.3, duration: 800.ms),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatsCard(
                          title: 'QR Codes',
                          value: '12',
                          icon: Icons.qr_code_rounded,
                          color: const Color(0xFF00FF88),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatsCard(
                          title: 'Scans',
                          value: '47',
                          icon: Icons.qr_code_scanner_rounded,
                          color: const Color(0xFF1A73E8),
                        ),
                      ),
                    ],
                  ).animate()
                    .fadeIn(duration: 800.ms, delay: 200.ms)
                    .slideY(begin: 0.3, duration: 800.ms, delay: 200.ms),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms),
                  
                  const SizedBox(height: 12),
                  
                  // Action Cards Grid
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildActionCard(
                          title: 'Create QR',
                          subtitle: 'Generate new QR code',
                          icon: Icons.add_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                          ),
                          delay: 500,
                        ),
                        _buildActionCard(
                          title: 'Scan QR',
                          subtitle: 'Open camera scanner',
                          icon: Icons.camera_alt_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A73E8), Color(0xFF6366F1)],
                          ),
                          delay: 600,
                        ),
                        _buildActionCard(
                          title: 'My Library',
                          subtitle: 'View saved QR codes',
                          icon: Icons.library_books_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF1A73E8)],
                          ),
                          delay: 700,
                        ),
                        _buildActionCard(
                          title: 'Marketplace',
                          subtitle: 'Order laser engraving',
                          icon: Icons.shopping_bag_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFF8B5CF6)],
                          ),
                          delay: 800,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required int delay,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: delay.ms)
      .slideY(begin: 0.3, duration: 600.ms, delay: delay.ms);
  }

  Widget _buildBackgroundParticle(int index) {
    final positions = [
      const Offset(50, 150),
      const Offset(300, 200),
      const Offset(80, 400),
      const Offset(250, 500),
      const Offset(160, 300),
      const Offset(320, 350),
    ];

    final position = positions[index % positions.length];
    final delay = (index * 400).milliseconds;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: 3,
        height: 3,
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
        .fadeIn(duration: 2500.ms, delay: delay)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.2, 1.2),
          duration: 3500.ms,
          delay: delay,
        ),
    );
  }
}