import 'dart:math' show log;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../auth/data/providers/supabase_auth_provider.dart';
import '../profile/presentation/pages/profile_screen.dart';
import '../main/main_scaffold.dart';
import 'providers/dashboard_providers.dart';
import '../../shared/widgets/qraft_logo.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authProvider = ref.watch(supabaseAuthProvider);
    final currentUser = authProvider.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Background particles
          ...List.generate(6, (index) => _buildBackgroundParticle(index)),
          
          SafeArea(
            child: SingleChildScrollView(
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
                            if (currentUser?.userMetadata?['display_name'] != null)
                              Text(
                                'Welcome back, ${currentUser!.userMetadata!['display_name']}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Profile/Settings button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                        onLongPress: () {
                          _showQuickActionsMenu(context, ref);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E2E2E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_circle_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ).animate()
                    .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                    .slideY(begin: -0.15, duration: 300.ms, curve: Curves.easeOutQuart),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final qrCodesCount = ref.watch(qrCodesCountProvider);
                            return qrCodesCount.when(
                              data: (count) => _buildStatsCard(
                                title: 'QR Codes',
                                value: '$count',
                                icon: Icons.qr_code_rounded,
                                color: const Color(0xFF00FF88),
                              ),
                              loading: () => _buildStatsCard(
                                title: 'QR Codes',
                                value: '...',
                                icon: Icons.qr_code_rounded,
                                color: const Color(0xFF00FF88),
                              ),
                              error: (_, __) => _buildStatsCard(
                                title: 'QR Codes',
                                value: '0',
                                icon: Icons.qr_code_rounded,
                                color: const Color(0xFF00FF88),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final scanHistoryCount = ref.watch(scanHistoryCountProvider);
                            return scanHistoryCount.when(
                              data: (count) => _buildStatsCard(
                                title: 'Scans',
                                value: '$count',
                                icon: Icons.qr_code_scanner_rounded,
                                color: const Color(0xFF1A73E8),
                              ),
                              loading: () => _buildStatsCard(
                                title: 'Scans',
                                value: '...',
                                icon: Icons.qr_code_scanner_rounded,
                                color: const Color(0xFF1A73E8),
                              ),
                              error: (_, __) => _buildStatsCard(
                                title: 'Scans',
                                value: '0',
                                icon: Icons.qr_code_scanner_rounded,
                                color: const Color(0xFF1A73E8),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ).animate()
                    .fadeIn(duration: 300.ms, delay: 100.ms, curve: Curves.easeOutCubic)
                    .slideY(begin: 0.15, duration: 300.ms, delay: 100.ms, curve: Curves.easeOutQuart),
                  
                  const SizedBox(height: 24),
                  
                  // Recent QR Codes Section
                  Consumer(
                    builder: (context, ref, child) {
                      final recentQRCodes = ref.watch(recentQRCodesProvider);
                      return recentQRCodes.when(
                        data: (qrCodes) {
                          if (qrCodes.isEmpty) {
                            return const SizedBox.shrink(); // Don't show section if empty
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent QR Codes',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _navigateToTab(ref, 3),
                                    child: Text(
                                      'View All',
                                      style: TextStyle(
                                        color: const Color(0xFF00FF88),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 90, // Reduced height to prevent overflow
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: qrCodes.length > 5 ? 5 : qrCodes.length,
                                  itemBuilder: (context, index) {
                                    return _buildRecentQRCard(qrCodes[index], index, ref);
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ).animate()
                    .fadeIn(duration: 300.ms, delay: 200.ms, curve: Curves.easeOutCubic)
                    .slideY(begin: 0.15, duration: 300.ms, delay: 200.ms, curve: Curves.easeOutQuart),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ).animate()
                    .fadeIn(duration: 300.ms, delay: 250.ms, curve: Curves.easeOutCubic),
                  
                  const SizedBox(height: 12),
                  
                  // Action Cards Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.25,
                    children: [
                        _buildActionCard(
                          title: 'Create QR',
                          subtitle: 'Generate new QR code',
                          icon: Icons.add_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                          ),
                          index: 0,
                          onTap: () => _navigateToTab(ref, 1),
                        ),
                        _buildActionCard(
                          title: 'Scan QR',
                          subtitle: 'Open camera scanner',
                          icon: Icons.camera_alt_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A73E8), Color(0xFF6366F1)],
                          ),
                          index: 1,
                          onTap: () => _navigateToTab(ref, 2),
                        ),
                        _buildActionCard(
                          title: 'My Library',
                          subtitle: 'View saved QR codes',
                          icon: Icons.library_books_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF1A73E8)],
                          ),
                          index: 2,
                          onTap: () => _navigateToTab(ref, 3),
                        ),
                        _buildActionCard(
                          title: 'Marketplace',
                          subtitle: 'Order laser engraving',
                          icon: Icons.shopping_bag_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFF8B5CF6)],
                          ),
                          index: 3,
                          onTap: () => _navigateToTab(ref, 4),
                        ),
                      ],
                    ),

                  // Bottom padding for safe scrolling
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTab(WidgetRef ref, int tabIndex) {
    ref.read(navigationIndexProvider.notifier).state = tabIndex;
  }

  void _showQuickActionsMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.person_rounded, color: const Color(0xFF00FF88)),
              title: Text(
                'View Profile',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_rounded, color: Colors.grey[400]),
              title: Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            Divider(color: Colors.grey[700]),
            ListTile(
              leading: Icon(Icons.exit_to_app_rounded, color: Colors.red[400]),
              title: Text(
                'Sign Out',
                style: TextStyle(color: Colors.red[400]),
              ),
              onTap: () {
                Navigator.pop(context);
                _showQuickSignOutDialog(context, ref);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuickSignOutDialog(BuildContext context, WidgetRef ref) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.exit_to_app_rounded,
              color: Colors.red[400],
            ),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final authProvider = ref.watch(supabaseAuthProvider);
              return TextButton(
                onPressed: authProvider.isLoading ? null : () async {
                  Navigator.pop(context);
                  
                  // Show loading snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Signing out...'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2E2E2E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  
                  try {
                    await authProvider.signOut();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to sign out. Please try again.'),
                          backgroundColor: Colors.red[700],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red[400]),
                ),
              );
            },
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2E2E2E).withValues(alpha: 0.7),
                  const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required int index,
    VoidCallback? onTap,
  }) {
    final delay = (100 + (40.0 * log(index + 2))).toInt();
    final colors = (gradient as LinearGradient).colors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.first.withValues(alpha: 0.7),
                  colors.last.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms, delay: delay.ms, curve: Curves.easeOutCubic)
      .slideY(begin: 0.15, duration: 300.ms, delay: delay.ms, curve: Curves.easeOutQuart)
      .scale(begin: const Offset(0.95, 0.95), duration: 300.ms, delay: delay.ms);
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

  Widget _buildRecentQRCard(Map<String, dynamic> qrData, int index, WidgetRef ref) {
    final qrType = qrData['qr_type'] ?? 'text';
    final title = qrData['title'] ?? 'QR Code';
    final iconData = _getQRTypeIcon(qrType);
    final color = _getQRTypeColor(qrType);
    final delay = (100 + (40.0 * log(index + 2))).toInt();

    return Container(
      width: 70,
      height: 90,
      margin: EdgeInsets.only(right: index < 4 ? 12 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2E2E2E).withValues(alpha: 0.7),
                  const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _navigateToTab(ref, 3),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          iconData,
                          color: color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms, delay: delay.ms, curve: Curves.easeOutCubic)
      .slideX(begin: 0.15, duration: 300.ms, delay: delay.ms, curve: Curves.easeOutQuart)
      .scale(begin: const Offset(0.95, 0.95), duration: 300.ms, delay: delay.ms);
  }

  IconData _getQRTypeIcon(String qrType) {
    switch (qrType.toLowerCase()) {
      case 'url': return Icons.link_rounded;
      case 'wifi': return Icons.wifi_rounded;
      case 'email': return Icons.email_rounded;
      case 'phone': return Icons.phone_rounded;
      case 'sms': return Icons.sms_rounded;
      case 'vcard': return Icons.person_rounded;
      case 'location': return Icons.location_on_rounded;
      case 'text': default: return Icons.text_fields_rounded;
    }
  }

  Color _getQRTypeColor(String qrType) {
    switch (qrType.toLowerCase()) {
      case 'url': return const Color(0xFF1A73E8);
      case 'wifi': return const Color(0xFF8B5CF6);
      case 'email': return const Color(0xFFF59E0B);
      case 'phone': return const Color(0xFF10B981);
      case 'sms': return const Color(0xFFEF4444);
      case 'vcard': return const Color(0xFF00FF88);
      case 'location': return const Color(0xFF10B981);
      case 'text': default: return const Color(0xFF6366F1);
    }
  }
}