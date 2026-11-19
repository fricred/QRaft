import 'dart:async' show unawaited;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qraft/l10n/app_localizations.dart';
import 'providers/qr_scanner_provider.dart';
import 'models/scan_result.dart';
import 'scan_result_screen.dart';
import 'widgets/scan_history_screen.dart';
import '../main/main_scaffold.dart' show navigationIndexProvider;

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen>
    with WidgetsBindingObserver {
  // Design constants for bottom controls
  static const double _sideButtonSize = 52.0;
  static const double _mainButtonSize = 70.0;
  static const double _labelSpacing = 8.0;
  static const double _labelHeight = 18.0;

  MobileScannerController? _controller;
  bool _isControllerInitialized = false;
  bool _isPermissionPermanentlyDenied = false;
  bool _isPermissionDenied = false;
  bool _setupStarted = false;

  /// Index of this screen in the main IndexedStack.
  static const int _scannerTabIndex = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The scanner lives in an IndexedStack, so it is built at app start. Only ask for
    // the camera once the user actually opens this tab (QRAFT-35): creating a QR must
    // never depend on the camera permission.
    if (ref.read(navigationIndexProvider) == _scannerTabIndex) {
      _setupStarted = true;
      _checkPermissionsAndSetupController();
    }
    ref.listenManual<int>(navigationIndexProvider, (previous, next) {
      if (next != _scannerTabIndex) return;
      if (!_setupStarted || (_controller == null && _isPermissionDenied)) {
        _setupStarted = true;
        _checkPermissionsAndSetupController(askAgain: !_isPermissionDenied);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    // Coming back from Settings after granting the camera: set the scanner up.
    if (state == AppLifecycleState.resumed && controller == null && _isPermissionDenied) {
      _checkPermissionsAndSetupController(askAgain: false);
      return;
    }
    if (controller == null || !_isControllerInitialized) return;
    switch (state) {
      case AppLifecycleState.inactive:
        unawaited(controller.stop());
      case AppLifecycleState.resumed:
        unawaited(controller.start());
      default:
        break;
    }
  }

  void _checkPermissionsAndSetupController({bool askAgain = true}) async {
    try {
      // Check camera permissions first
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = askAgain ? await Permission.camera.request() : status;
        if (!result.isGranted) {
          // Shown inline in the scanner area, never as a floating message: a snackbar
          // would sit on top of other tabs' buttons (QRAFT-35).
          if (mounted) {
            setState(() {
              _isPermissionDenied = true;
              _isPermissionPermanentlyDenied = result.isPermanentlyDenied;
            });
          }
          return;
        }
      }
      if (mounted && _isPermissionDenied) {
        setState(() {
          _isPermissionDenied = false;
          _isPermissionPermanentlyDenied = false;
        });
      }

      // Create controller with autoStart: true - it will start when MobileScanner widget is built
      _controller = MobileScannerController(
        formats: [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
        detectionTimeoutMs: 1000,
        autoStart: true, // Auto-start when attached to MobileScanner widget
      );

      if (mounted) {
        setState(() {
          _isControllerInitialized = true;
        });
      }
    } catch (error) {
      debugPrint('Error setting up camera controller: $error');
      if (mounted) {
        // Use generic error messages here since we don't have context yet
        // These will be shown through the provider's error state
        String errorKey = 'cameraInitFailed';
        if (error.toString().contains('No camera found') ||
            error.toString().contains('failed to open camera')) {
          errorKey = 'noCameraAvailable';
        }
        ref.read(qrScannerProvider.notifier).logDetailedError('Camera Initialization', errorKey);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      // Scanner messages belong to the scanner tab only.
      if (next != null && ref.read(navigationIndexProvider) == _scannerTabIndex) {
        _showErrorSnackBar(next);
      }
    });

    return Semantics(
      identifier: 'qr_scanner_screen_root',
      container: true,
      child: Scaffold(
      key: const Key('qr_scanner_screen_root'),
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(l10n, isFlashOn),
            
            // Camera Preview Area
            Expanded(
              flex: 2,
              child: _buildCameraPreview(isScanning),
            ),
            
            // Bottom controls
            Expanded(
              flex: 1,
              child: _buildBottomControls(l10n, isScanning),
            ),
          ],
        ),
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
          Semantics(
            identifier: 'scanner_flash_button',
            child: IconButton(
              key: const Key('scanner_flash_button'),
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
          ),
        ],
      ).animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
        .slideY(begin: -0.15, duration: 300.ms, curve: Curves.easeOutQuart),
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
            if (_isPermissionDenied)
              _buildPermissionDeniedView()
            else if (_controller != null && _isControllerInitialized)
              MobileScanner(
                controller: _controller,
                tapToFocus: true,
                onDetect: (BarcodeCapture capture) {
                  // Always detect QR codes when camera is active
                  _handleBarcodeDetection(capture);
                },
                errorBuilder: (context, error) {
                  // Handle camera errors (e.g., simulator has no camera)
                  String errorKey = 'cameraError';
                  if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                    errorKey = 'cameraPermissionDenied';
                  } else if (error.errorCode == MobileScannerErrorCode.unsupported) {
                    errorKey = 'noCameraAvailable';
                  } else {
                    errorKey = error.errorDetails?.message ?? 'cameraInitFailed';
                  }
                  return _buildCameraErrorWidget(errorKey);
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
      .fadeIn(duration: 400.ms, delay: 100.ms, curve: Curves.easeOutCubic)
      .scale(begin: const Offset(0.9, 0.9), duration: 400.ms, delay: 100.ms, curve: Curves.easeOutBack);
  }

  Widget _buildCameraPlaceholder() {
    final errorMessage = ref.watch(scannerErrorProvider);
    final hasError = errorMessage != null && errorMessage.isNotEmpty;
    
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
            if (hasError) ...[
              Icon(
                Icons.videocam_off_rounded,
                color: Colors.grey[400],
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.cameraUnavailable,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _getLocalizedError(context, errorMessage),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00FF88)),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.initializingCamera,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraErrorWidget(String errorMessage) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2E2E2E),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.cameraUnavailable,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _getLocalizedError(context, errorMessage),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF2E2E2E)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography_rounded,
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              Localizations.localeOf(context).languageCode == 'es'
                  ? 'Sin acceso a la cámara'
                  : 'No camera access',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                Localizations.localeOf(context).languageCode == 'es'
                    ? 'Para escanear códigos, permite el acceso a la cámara. Crear y guardar QR funciona sin ella.'
                    : 'To scan codes, allow camera access. Creating and saving QR codes works without it.',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              identifier: 'scanner_open_settings_button',
              child: ElevatedButton.icon(
                key: const Key('scanner_open_settings_button'),
                onPressed: _isPermissionPermanentlyDenied
                    ? _openAppSettings
                    : () => _checkPermissionsAndSetupController(),
                icon: Icon(_isPermissionPermanentlyDenied
                    ? Icons.settings_rounded
                    : Icons.photo_camera_rounded),
                label: Text(_isPermissionPermanentlyDenied
                    ? l10n.openSettings
                    : (Localizations.localeOf(context).languageCode == 'es'
                        ? 'Permitir cámara'
                        : 'Allow camera')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                      duration: 1200.ms,
                      curve: Curves.easeInOutCubic,
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
                AppLocalizations.of(context)!.tapToScan,
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

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required int delayMs,
    double size = 52,
    double iconSize = 22,
    String? semanticsIdentifier,
    String? semanticsLabel,
  }) {
    final container = Container(
      key: semanticsIdentifier != null ? Key(semanticsIdentifier) : null,
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms, delay: Duration(milliseconds: delayMs))
      .scale(begin: const Offset(0.9, 0.9), duration: 300.ms, delay: Duration(milliseconds: delayMs));

    if (semanticsIdentifier != null) {
      return Semantics(
        identifier: semanticsIdentifier,
        button: true,
        label: semanticsLabel,
        child: container,
      );
    }
    return container;
  }

  Widget _buildBottomControls(AppLocalizations l10n, bool isScanning) {
    // Total height based on tallest element (main button + label)
    const double totalHeight = _mainButtonSize + _labelSpacing + _labelHeight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Gallery button (left)
          SizedBox(
            width: 80,
            height: totalHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildGlassIconButton(
                  icon: Icons.photo_library_rounded,
                  onPressed: () => _scanFromGallery(),
                  size: _sideButtonSize,
                  iconSize: 22,
                  delayMs: 250,
                  semanticsIdentifier: 'scanner_gallery_button',
                  semanticsLabel: l10n.gallery,
                ),
                const SizedBox(height: _labelSpacing),
                Text(
                  l10n.gallery,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ).animate()
                  .fadeIn(duration: 200.ms, delay: 350.ms),
              ],
            ),
          ),

          // Scan button (center, larger)
          SizedBox(
            width: 90,
            height: totalHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildScanButton(isScanning),
                const SizedBox(height: _labelSpacing),
                Text(
                  l10n.scanner,
                  style: TextStyle(
                    color: isScanning ? Colors.red[300] : const Color(0xFF00FF88),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ).animate()
                  .fadeIn(duration: 200.ms, delay: 300.ms),
              ],
            ),
          ),

          // History button (right)
          SizedBox(
            width: 80,
            height: totalHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildGlassIconButton(
                  icon: Icons.history_rounded,
                  onPressed: () => _navigateToHistory(),
                  size: _sideButtonSize,
                  iconSize: 22,
                  delayMs: 300,
                  semanticsIdentifier: 'scanner_history_button',
                  semanticsLabel: l10n.scans,
                ),
                const SizedBox(height: _labelSpacing),
                Text(
                  l10n.scans,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ).animate()
                  .fadeIn(duration: 200.ms, delay: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(bool isScanning) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    return Semantics(
      identifier: 'scanner_scan_button',
      button: true,
      label: isScanning
          ? (es ? 'Detener escaneo' : 'Stop scanning')
          : (es ? 'Escanear' : 'Scan'),
      child: Container(
      key: const Key('scanner_scan_button'),
      width: _mainButtonSize,
      height: _mainButtonSize,
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
          borderRadius: BorderRadius.circular(_mainButtonSize / 2),
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
      .fadeIn(duration: 300.ms, delay: 200.ms, curve: Curves.easeOutCubic)
      .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, delay: 200.ms, curve: Curves.easeOutBack),
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
    ScanResultScreen.push(context, scanResult);
  }

  void _showErrorSnackBar(String rawError) {
    // The provider has no BuildContext, so it reports some failures as l10n
    // keys rather than prose. Resolve those here; anything unrecognised is
    // already a human-readable message.
    final l10n = AppLocalizations.of(context)!;
    final error = switch (rawError) {
      'noQRFoundInImage' => l10n.noQRFoundInImage,
      'galleryScanFailed' => Localizations.localeOf(context).languageCode == 'es'
          ? 'No pudimos leer esa imagen. Inténtalo de nuevo.'
          : "We couldn't read that image. Please try again.",
      _ => rawError,
    };

    // Check if this is a permission-related error
    final isPermissionError = error.toLowerCase().contains('permission');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
      SnackBar(
        // An action makes a snackbar stay forever under accessibility services, which
        // blocked every later message (QRAFT-13). Force the timeout.
        persist: false,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Icon(
              isPermissionError ? Icons.lock_outlined : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(error)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: isPermissionError
          ? SnackBarAction(
              label: AppLocalizations.of(context)!.openSettings,
              textColor: Colors.white,
              onPressed: () {
                ref.read(qrScannerProvider.notifier).clearError();
                _openAppSettings();
              },
            )
          : SnackBarAction(
              label: AppLocalizations.of(context)!.dismissButton,
              textColor: Colors.white,
              onPressed: () {
                ref.read(qrScannerProvider.notifier).clearError();
              },
            ),
      ),
    );
  }

  void _openAppSettings() {
    // Import permission_handler to open app settings
    try {
      openAppSettings();
    } catch (e) {
      debugPrint('❌ Failed to open app settings: $e');
    }
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
    if (_controller == null) return;
    ref.read(qrScannerProvider.notifier).scanFromGallery(_controller!);
    HapticFeedback.lightImpact();
  }

  String _getLocalizedError(BuildContext context, String? errorKey) {
    if (errorKey == null || errorKey.isEmpty) return '';
    final l10n = AppLocalizations.of(context)!;
    switch (errorKey) {
      case 'cameraInitFailed':
        return l10n.cameraInitFailed;
      case 'noCameraAvailable':
        return l10n.noCameraAvailable;
      case 'cameraPermissionDenied':
        return l10n.cameraPermissionDeniedMessage;
      case 'cameraError':
        return l10n.cameraError;
      default:
        return errorKey; // Fall back to the original message if not a key
    }
  }
}