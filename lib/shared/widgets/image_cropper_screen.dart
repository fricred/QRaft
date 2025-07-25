import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../widgets/glass_button.dart';

class ImageCropperScreen extends StatefulWidget {
  final Uint8List imageData;
  final double aspectRatio;
  final bool withCircleUi;

  const ImageCropperScreen({
    super.key,
    required this.imageData,
    this.aspectRatio = 1.0, // Default to square for profile photos
    this.withCircleUi = true, // Default to circular for profile photos
  });

  @override
  State<ImageCropperScreen> createState() => _ImageCropperScreenState();
}

class _ImageCropperScreenState extends State<ImageCropperScreen> {
  final _controller = CropController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.cropImage,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _cropImage,
              child: Text(
                l10n.crop,
                style: const TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Crop instruction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.cropInstruction,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Crop area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Crop(
                image: widget.imageData,
                controller: _controller,
                aspectRatio: widget.aspectRatio,
                withCircleUi: widget.withCircleUi,
                baseColor: const Color(0xFF1A1A1A),
                maskColor: Colors.black.withValues(alpha: 0.7),
                radius: 8,
                onCropped: (result) {
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                    
                    switch (result) {
                      case CropSuccess(:final croppedImage):
                        Navigator.of(context).pop(croppedImage);
                        break;
                      case CropFailure():
                        // Don't show SnackBar here as it interferes with UI
                        // Return null to indicate crop failure
                        Navigator.of(context).pop(null);
                        break;
                    }
                  }
                },
                cornerDotBuilder: (size, edgeAlignment) => const DotControl(
                  color: Color(0xFF00FF88),
                ),
                interactive: true,
                fixCropRect: false,
                willUpdateScale: (newScale) => newScale < 5,
              ),
            ),
          ),
          
          // Bottom action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryGlassButton(
                    text: l10n.cancel,
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    height: 48,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryGlassButton(
                    text: _isProcessing ? l10n.processingImage : l10n.crop,
                    onPressed: _isProcessing ? null : _cropImage,
                    isLoading: _isProcessing,
                    height: 48,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _cropImage() {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      _controller.crop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // Don't show SnackBar here as it interferes with UI
        // The onCropped callback will handle the result
        debugPrint('❌ Error triggering crop: $e');
      }
    }
  }
}

/// Custom dot control for crop corners with QRaft styling
class DotControl extends StatelessWidget {
  final Color color;
  final double size;

  const DotControl({
    super.key,
    required this.color,
    this.size = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}