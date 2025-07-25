import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../../shared/widgets/glass_button.dart';
import 'providers/qr_scanner_provider.dart';
import 'models/scan_result.dart';
import 'widgets/scan_result_dialog.dart';
import 'widgets/scan_history_screen.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  MobileScannerController? _controller;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: 1000,
      autoStart: true, // Auto-start camera
    );
    
    // Initialize controller and wait for it to be ready
    _controller!.start().then((_) {
      if (mounted) {
        setState(() {
          _isControllerInitialized = true;
        });
        // Auto-start scanning when camera is ready
        ref.read(qrScannerProvider.notifier).startScanning();
      }
    }).catchError((error) {
      debugPrint('Error initializing camera: $error');
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isScanning = ref.watch(isScanningProvider);
    final isFlashOn = ref.watch(isFlashOnProvider);

    // Listen to scan results
    ref.listen<ScanResult?>(lastScanResultProvider, (previous, next) {
      if (next != null && previous != next) {
        _showScanResultDialog(next);
      }
    });

    // Listen to errors
    ref.listen<String?>(scannerErrorProvider, (previous, next) {
      if (next != null) {
        _showErrorSnackBar(next);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(l10n, isFlashOn),
            
            // Camera Preview Area
            Expanded(
              flex: 3,
              child: _buildCameraPreview(isScanning),
            ),
            
            // Bottom controls
            _buildBottomControls(l10n, isScanning),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, bool isFlashOn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.qrScanner,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.pointCameraAtQR,
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
              ref.read(qrScannerProvider.notifier).toggleFlash();
              _controller?.toggleTorch();
            },
            icon: Icon(
              isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: isFlashOn ? const Color(0xFF00FF88) : Colors.white,
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
    );
  }

  Widget _buildCameraPreview(bool isScanning) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Camera preview
            if (_controller != null && _isControllerInitialized)
              MobileScanner(
                controller: _controller,
                onDetect: (BarcodeCapture capture) {
                  // Always detect QR codes when camera is active
                  _handleBarcodeDetection(capture);
                },
              )
            else
              _buildCameraPlaceholder(),
            
            // Scanning overlay
            _buildScanningOverlay(isScanning),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 1000.ms, delay: 200.ms)
      .scale(begin: const Offset(0.9, 0.9), duration: 800.ms, delay: 200.ms);
  }

  Widget _buildCameraPlaceholder() {
    return Container(
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00FF88)),
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing Camera...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay(bool isScanning) {
    return Stack(
      children: [
        // Scanning grid lines
        if (isScanning) ...List.generate(10, (index) => _buildGridLine(index)),
        
        // Center scanning frame
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: isScanning ? const Color(0xFF00FF88) : Colors.white.withValues(alpha: 0.5),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Corner indicators
                ...List.generate(4, (index) => _buildCornerIndicator(index, isScanning)),
                
                // Scanning line animation
                if (isScanning)
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
        
        // Status text
        if (!isScanning && _isControllerInitialized)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 300),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Tap the scan button to start detecting QR codes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomControls(AppLocalizations l10n, bool isScanning) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scan button
            _buildScanButton(isScanning),
            
            const SizedBox(height: 16),
            
            // Action buttons row
            Row(
              children: [
                // Gallery button
                Expanded(
                  child: SecondaryGlassButton(
                    text: "Gallery",
                    icon: Icons.photo_library_rounded,
                    height: 48,
                    onPressed: () => _scanFromGallery(),
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 500.ms),
                ),
                
                const SizedBox(width: 12),
                
                // History button
                Expanded(
                  child: SecondaryGlassButton(
                    text: l10n.scanHistory,
                    icon: Icons.history_rounded,
                    height: 48,
                    onPressed: () => _navigateToHistory(),
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 600.ms),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton(bool isScanning) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isScanning 
            ? [Colors.red[400]!, Colors.red[600]!]
            : [const Color(0xFF00FF88), const Color(0xFF1A73E8)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isScanning ? Colors.red[400]! : const Color(0xFF00FF88))
                .withValues(alpha: 0.4),
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
            if (isScanning) {
              ref.read(qrScannerProvider.notifier).stopScanning();
            } else {
              ref.read(qrScannerProvider.notifier).startScanning();
            }
            HapticFeedback.mediumImpact();
          },
          child: Icon(
            isScanning ? Icons.stop_rounded : Icons.qr_code_scanner_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 800.ms, delay: 400.ms)
      .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, delay: 400.ms);
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

  Widget _buildCornerIndicator(int index, bool isActive) {
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
              color: isActive ? const Color(0xFF00FF88) : Colors.white.withValues(alpha: 0.5),
              width: 3,
            ),
            left: BorderSide(
              color: isActive ? const Color(0xFF00FF88) : Colors.white.withValues(alpha: 0.5),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }

  void _handleBarcodeDetection(BarcodeCapture capture) {
    final isScanning = ref.read(isScanningProvider);
    if (capture.barcodes.isNotEmpty && isScanning) {
      ref.read(qrScannerProvider.notifier).processScanResult(capture);
      HapticFeedback.lightImpact();
    }
  }

  void _showScanResultDialog(ScanResult scanResult) {
    showDialog(
      context: context,
      builder: (context) => ScanResultDialog(scanResult: scanResult),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ref.read(qrScannerProvider.notifier).clearError();
          },
        ),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanHistoryScreen(),
      ),
    );
  }

  void _scanFromGallery() {
    ref.read(qrScannerProvider.notifier).scanFromGallery();
    HapticFeedback.lightImpact();
  }
}