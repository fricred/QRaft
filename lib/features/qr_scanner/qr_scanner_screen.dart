import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/widgets/glass_button.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isFlashOn = false;
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR Scanner',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Point camera at QR code to scan',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Flash toggle
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isFlashOn = !_isFlashOn;
                      });
                    },
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isFlashOn ? const Color(0xFF00FF88) : Colors.white,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF2E2E2E),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ).animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: -0.3, duration: 800.ms),
            ),
            
            // Camera Preview Area
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Camera preview placeholder
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A1A1A),
                            const Color(0xFF2E2E2E),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Scanning grid lines
                          ...List.generate(10, (index) => _buildGridLine(index)),
                          
                          // Center scanning frame
                          Center(
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF00FF88),
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  // Corner indicators
                                  ...List.generate(4, (index) => _buildCornerIndicator(index)),
                                  
                                  // Scanning line animation
                                  if (_isScanning)
                                    Container(
                                      width: double.infinity,
                                      height: 2,
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            const Color(0xFF00FF88),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ).animate(onPlay: (controller) => controller.repeat())
                                      .moveY(
                                        begin: -125,
                                        end: 125,
                                        duration: 2000.ms,
                                        curve: Curves.easeInOut,
                                      ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Coming soon overlay
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    color: const Color(0xFF00FF88),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Camera Access Required',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'QR scanner functionality is under development',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(duration: 1000.ms, delay: 200.ms)
                .scale(begin: const Offset(0.9, 0.9), duration: 800.ms, delay: 200.ms),
            ),
            
            // Bottom controls
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scan button
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00FF88).withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(35),
                          onTap: () {
                            setState(() {
                              _isScanning = !_isScanning;
                            });
                            _showComingSoonDialog();
                          },
                          child: Icon(
                            _isScanning ? Icons.stop_rounded : Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ).animate()
                      .fadeIn(duration: 800.ms, delay: 400.ms)
                      .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, delay: 400.ms),
                    
                    const SizedBox(height: 16),
                    
                    // History button
                    SecondaryGlassButton(
                      text: 'Scan History',
                      icon: Icons.history_rounded,
                      height: 48,
                      onPressed: () => _showComingSoonDialog(),
                    ).animate()
                      .fadeIn(duration: 600.ms, delay: 600.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLine(int index) {
    final positions = [
      Offset(0, 100 + index * 40.0),
      Offset(100 + index * 40.0, 0),
    ];
    
    final isHorizontal = index % 2 == 0;
    final position = positions[isHorizontal ? 0 : 1];
    
    return Positioned(
      left: isHorizontal ? 0 : position.dx,
      top: isHorizontal ? position.dy : 0,
      right: isHorizontal ? 0 : null,
      bottom: isHorizontal ? null : 0,
      child: Container(
        width: isHorizontal ? null : 1,
        height: isHorizontal ? 1 : null,
        color: const Color(0xFF00FF88).withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildCornerIndicator(int index) {
    final positions = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];
    
    return Align(
      alignment: positions[index],
      child: Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color(0xFF00FF88),
              width: 3,
            ),
            left: BorderSide(
              color: const Color(0xFF00FF88),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog() {
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
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scanner Coming Soon!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'QR scanner functionality is under development and will be available soon.',
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