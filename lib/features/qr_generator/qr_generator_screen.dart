import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/widgets/glass_button.dart';

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Generate QR',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ).animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: -0.3, duration: 800.ms),
              
              const SizedBox(height: 8),
              
              Text(
                'Create QR codes for various purposes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ).animate()
                .fadeIn(duration: 800.ms, delay: 100.ms),
              
              const SizedBox(height: 32),
              
              // QR Type Selection Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _buildQRTypeCard(
                      title: 'Personal Info',
                      subtitle: 'Contact details\nvCard format',
                      icon: Icons.person_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                      ),
                      delay: 200,
                    ),
                    _buildQRTypeCard(
                      title: 'Website URL',
                      subtitle: 'Links to websites\nand web pages',
                      icon: Icons.link_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A73E8), Color(0xFF6366F1)],
                      ),
                      delay: 300,
                    ),
                    _buildQRTypeCard(
                      title: 'WiFi Network',
                      subtitle: 'Share WiFi\ncredentials easily',
                      icon: Icons.wifi_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF1A73E8)],
                      ),
                      delay: 400,
                    ),
                    _buildQRTypeCard(
                      title: 'Text Message',
                      subtitle: 'Plain text content\nfor any purpose',
                      icon: Icons.text_fields_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFF8B5CF6)],
                      ),
                      delay: 500,
                    ),
                    _buildQRTypeCard(
                      title: 'Email',
                      subtitle: 'Send email with\npre-filled content',
                      icon: Icons.email_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                      ),
                      delay: 600,
                    ),
                    _buildQRTypeCard(
                      title: 'Location',
                      subtitle: 'GPS coordinates\nand map points',
                      icon: Icons.location_on_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF00FF88)],
                      ),
                      delay: 700,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Template Library Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Template Library',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Browse pre-designed QR templates',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(duration: 800.ms, delay: 800.ms)
                .slideY(begin: 0.3, duration: 800.ms, delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required int delay,
  }) {
    return Container(
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
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigate to specific QR generator form
            _showComingSoonDialog(context, title);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    height: 1.3,
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

  void _showComingSoonDialog(BuildContext context, String qrType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Coming Soon!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$qrType QR generator is under development and will be available soon.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PrimaryGlassButton(
                  text: 'Got it',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}