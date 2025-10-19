import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/qr_type.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_button.dart';

class ComingSoonQRScreen extends StatelessWidget {
  final QRType qrType;

  const ComingSoonQRScreen({
    super.key,
    required this.qrType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          qrType.getDisplayName(context),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main icon with animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: qrType.gradientColors.map((c) => Color(c)).toList(),
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Color(qrType.gradientColors.first).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ).animate()
                .scale(duration: 800.ms)
                .then()
                .shimmer(duration: 2000.ms, delay: 500.ms),
              
              const SizedBox(height: 40),
              
              // Coming Soon title
              Text(
                AppLocalizations.of(context)?.comingSoon ?? 'Coming Soon',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(duration: 800.ms, delay: 200.ms)
                .slideY(begin: 0.3, duration: 800.ms, delay: 200.ms),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'This QR type is under development and will be available in a future update.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(duration: 800.ms, delay: 400.ms),
              
              const SizedBox(height: 40),
              
              // Feature preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: qrType.gradientColors.map((c) => Color(c)).toList(),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIconData(qrType.iconName),
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
                                AppLocalizations.of(context)?.plannedFeatures ?? 'Planned Features',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getPlannedFeatures(qrType),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)?.expectedInNextUpdate ?? 'Expected in next major update',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(duration: 800.ms, delay: 600.ms)
                .slideY(begin: 0.3, duration: 800.ms, delay: 600.ms),
              
              const SizedBox(height: 40),
              
              // Back button
              SecondaryGlassButton(
                text: AppLocalizations.of(context)?.backToQRTypes ?? 'Back to QR Types',
                onPressed: () => Navigator.of(context).pop(),
                width: double.infinity,
                height: 56,
              ).animate()
                .fadeIn(duration: 800.ms, delay: 800.ms)
                .slideY(begin: 0.3, duration: 800.ms, delay: 800.ms),
            ],
          ),
        ),
      ),
    );
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

  String _getPlannedFeatures(QRType qrType) {
    switch (qrType) {
      case QRType.wifi:
        return 'Network name, password, security type selection with automatic connection';
      case QRType.email:
        return 'Email address, subject, message body with direct compose integration';
      case QRType.location:
        return 'GPS coordinates, address search, map integration with navigation options';
      case QRType.personalInfo:
        return 'Contact cards, social profiles, professional information with vCard export';
      default:
        return 'Advanced customization options and enhanced functionality';
    }
  }
}