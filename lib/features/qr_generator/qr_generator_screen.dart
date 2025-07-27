import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'domain/entities/qr_type.dart';
import 'presentation/pages/qr_form_screen.dart';

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
                  children: QRType.values.map((qrType) {
                    final index = QRType.values.indexOf(qrType);
                    return _buildQRTypeCard(
                      qrType: qrType,
                      delay: 200 + (index * 100),
                    );
                  }).toList(),
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
    required QRType qrType,
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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => QRFormScreen(qrType: qrType),
              ),
            );
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
                    gradient: LinearGradient(
                      colors: qrType.gradientColors.map((c) => Color(c)).toList(),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(qrType.gradientColors.first).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIconData(qrType.iconName),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  qrType.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  qrType.description,
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

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person_rounded':
        return Icons.person_rounded;
      case 'link_rounded':
        return Icons.link_rounded;
      case 'wifi_rounded':
        return Icons.wifi_rounded;
      case 'text_fields_rounded':
        return Icons.text_fields_rounded;
      case 'email_rounded':
        return Icons.email_rounded;
      case 'location_on_rounded':
        return Icons.location_on_rounded;
      default:
        return Icons.qr_code_rounded;
    }
  }

}