import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/qr_type.dart';
import '../widgets/qr_form_factory.dart';
import '../widgets/forms/url_form.dart';
import '../widgets/forms/text_form.dart';
import '../widgets/color_picker_widget.dart';
import '../controllers/qr_customization_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class QRFormScreen extends ConsumerStatefulWidget {
  final QRType qrType;

  const QRFormScreen({
    super.key,
    required this.qrType,
  });

  @override
  ConsumerState<QRFormScreen> createState() => _QRFormScreenState();
}

class _QRFormScreenState extends ConsumerState<QRFormScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () {
            if (_currentPage > 0) {
              // If we're not on the first step, go to previous step
              _previousPage();
            } else {
              // If we're on the first step, go back to home
              Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.qrType.getDisplayName(context),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getStepTitle(_currentPage, context),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(widget.qrType.gradientColors.first).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentPage + 1}/3',
              style: TextStyle(
                color: Color(widget.qrType.gradientColors.first),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(3, (index) {
                final bool isCompleted = index < _currentPage;
                final bool isCurrent = index == _currentPage;
                final bool isValid = index != 0 || _canProceed(0);
                
                Color stepColor;
                if (isCompleted) {
                  // Completed steps - show active color
                  stepColor = Color(widget.qrType.gradientColors.first);
                } else if (isCurrent) {
                  // Current step - show active color if valid, red if invalid
                  stepColor = isValid 
                      ? Color(widget.qrType.gradientColors.first)
                      : const Color(0xFFEF4444);
                } else {
                  // Future steps - show grey
                  stepColor = Colors.grey[700]!;
                }
                
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    height: 4,
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: stepColor,
                    ),
                  ),
                );
              }),
            ),
          ),

          // Page view
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                // Step 1: Form Input
                QRFormFactory.buildForm(widget.qrType, _nextPage),
                
                // Step 2: Customization
                _buildCustomizationStep(),
                
                // Step 3: Preview & Save
                _buildPreviewStep(),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: SecondaryGlassButton(
                      text: 'Back',
                      icon: Icons.arrow_back_rounded,
                      onPressed: _previousPage,
                    ),
                  ),
                
                if (_currentPage > 0) const SizedBox(width: 16),
                
                Expanded(
                  flex: _currentPage == 0 ? 1 : 2,
                  child: Column(
                    children: [
                      PrimaryGlassButton(
                        text: _getButtonText(_currentPage, context),
                        icon: _getButtonIcon(_currentPage),
                        onPressed: _canProceed(_currentPage) 
                            ? (_currentPage == 2 ? _saveQRCode : _nextPage)
                            : null,
                      ),
                      if (!_canProceed(_currentPage) && _currentPage == 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)?.qrFormCompleteFields ?? 'Complete all fields correctly to continue',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize your QR',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Personalize the appearance of your QR code',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 100.ms),
          
          const SizedBox(height: 32),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  // Color selection
                  _buildCustomizationSection(
                    title: 'Colors',
                    icon: Icons.palette_rounded,
                    child: _buildColorPicker(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Size selection
                  _buildCustomizationSection(
                    title: 'Size',
                    icon: Icons.photo_size_select_large_rounded,
                    child: _buildSizePicker(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Logo option
                  _buildCustomizationSection(
                    title: 'Logo',
                    icon: Icons.add_photo_alternate_rounded,
                    child: _buildLogoOption(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview & Save',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Review your QR code and save it to your library',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 100.ms),
          
          const SizedBox(height: 32),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: _buildQRPreview().animate()
                  .fadeIn(duration: 800.ms, delay: 200.ms)
                  .scale(begin: const Offset(0.8, 0.8), duration: 800.ms, delay: 200.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationSection({
    required String title,
    required IconData icon,
    required Widget child,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.qrType.gradientColors.map((c) => Color(c)).toList(),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 300.ms)
      .slideY(begin: 0.3, duration: 600.ms, delay: 300.ms);
  }

  Widget _buildColorPicker() {
    final l10n = AppLocalizations.of(context);
    final customizationState = ref.watch(qrCustomizationControllerProvider);
    final customizationController = ref.read(qrCustomizationControllerProvider.notifier);
    
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.qrType.gradientColors.map((c) => Color(c)).toList(),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[400],
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.brush_rounded,
                        size: 18,
                        color: Color(customizationState.customization.foregroundColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'QR',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Color(customizationState.customization.backgroundColor),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'BG',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        size: 18,
                        color: Color(customizationState.customization.eyeColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Eyes',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tab Views
          SizedBox(
            height: 250, // Slightly increased to prevent overflow
            child: TabBarView(
              children: [
                // Foreground Color Tab
                ColorPickerWidget(
                  title: l10n?.foregroundColor ?? 'Foreground Color',
                  selectedColor: Color(customizationState.customization.foregroundColor),
                  onColorChanged: customizationController.updateForegroundColor,
                ),
                
                // Background Color Tab
                ColorPickerWidget(
                  title: l10n?.backgroundColor ?? 'Background Color',
                  selectedColor: Color(customizationState.customization.backgroundColor),
                  onColorChanged: customizationController.updateBackgroundColor,
                ),
                
                // Eye Color Tab
                ColorPickerWidget(
                  title: l10n?.eyeColor ?? 'Eye Color',
                  selectedColor: Color(customizationState.customization.eyeColor),
                  onColorChanged: customizationController.updateEyeColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizePicker() {
    final customizationState = ref.watch(qrCustomizationControllerProvider);
    final customizationController = ref.read(qrCustomizationControllerProvider.notifier);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QR Code Size',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Slider(
          value: customizationState.customization.size,
          min: 150.0,
          max: 300.0,
          divisions: 6,
          activeColor: Color(widget.qrType.gradientColors.first),
          inactiveColor: Colors.grey[600],
          onChanged: customizationController.updateSize,
        ),
        Text(
          '${customizationState.customization.size.toInt()}px',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoOption() {
    final l10n = AppLocalizations.of(context);
    final customizationState = ref.watch(qrCustomizationControllerProvider);
    final customizationController = ref.read(qrCustomizationControllerProvider.notifier);
    
    return Column(
      children: [
        // Logo Status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Logo Preview or Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: customizationState.customization.hasLogo 
                      ? Colors.transparent 
                      : Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: customizationState.customization.hasLogo && 
                       customizationState.customization.logoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.file(
                          File(customizationState.customization.logoPath!),
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.broken_image_rounded,
                              color: Colors.grey[400],
                              size: 20,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.image_outlined,
                        color: Colors.grey[400],
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customizationState.customization.hasLogo ? 'Logo Added' : 'No Logo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      customizationState.customization.hasLogo 
                          ? 'Your logo will appear in the center'
                          : 'Add a logo to make your QR unique',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Logo Actions
        Row(
          children: [
            if (customizationState.customization.hasLogo) ...[
              Expanded(
                child: SecondaryGlassButton(
                  text: l10n?.removeLogo ?? 'Remove Logo',
                  onPressed: customizationController.removeLogo,
                  icon: Icons.delete_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryGlassButton(
                  text: 'Change',
                  onPressed: () => _handleAddLogo(customizationController),
                  icon: Icons.swap_horizontal_circle_rounded,
                ),
              ),
            ] else ...[
              Expanded(
                child: PrimaryGlassButton(
                  text: l10n?.addLogo ?? 'Add Logo',
                  onPressed: () => _handleAddLogo(customizationController),
                  icon: Icons.add_photo_alternate_rounded,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _handleAddLogo(QRCustomizationController controller) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 85,
      );

      if (image != null) {
        // Update the customization with the selected image
        controller.updateLogo(image.path, 40.0);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo added successfully!'),
              backgroundColor: Color(0xFF00FF88),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildQRPreview() {
    final customizationState = ref.watch(qrCustomizationControllerProvider);
    final customization = customizationState.customization;
    
    // Get QR data based on form state
    String qrData = _getQRData();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(customization.backgroundColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: customization.size,
        backgroundColor: Color(customization.backgroundColor),
        eyeStyle: QrEyeStyle(
          eyeShape: customization.eyeShape == 0 ? QrEyeShape.square : QrEyeShape.circle,
          color: Color(customization.eyeColor),
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: customization.dataShape == 0 
              ? QrDataModuleShape.square 
              : QrDataModuleShape.circle,
          color: Color(customization.foregroundColor),
        ),
        errorCorrectionLevel: [
          QrErrorCorrectLevel.L, 
          QrErrorCorrectLevel.M, 
          QrErrorCorrectLevel.Q, 
          QrErrorCorrectLevel.H
        ][customization.errorCorrectionLevel],
        embeddedImage: customization.hasLogo && customization.logoPath != null
            ? FileImage(File(customization.logoPath!))
            : null,
        embeddedImageStyle: QrEmbeddedImageStyle(
          size: Size(customization.logoSize, customization.logoSize),
        ),
      ),
    );
  }

  String _getQRData() {
    switch (widget.qrType) {
      case QRType.url:
        final urlState = ref.watch(urlFormProvider);
        return ref.read(urlFormProvider.notifier).getFormattedURL(urlState.url);
      case QRType.text:
        final textState = ref.watch(textFormProvider);
        return textState.text;
      case QRType.personalInfo:
      case QRType.wifi:
      case QRType.email:
      case QRType.location:
        return 'Coming soon - ${widget.qrType.getDisplayName(context)}';
    }
  }

  String _getStepTitle(int step, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (step) {
      case 0:
        return l10n?.qrFormStepEnterInfo ?? 'Enter information';
      case 1:
        return l10n?.qrFormStepCustomize ?? 'Customize appearance';
      case 2:
        return l10n?.qrFormStepPreviewSave ?? 'Preview & save';
      default:
        return '';
    }
  }

  String _getButtonText(int step, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (step) {
      case 0:
        return l10n?.qrFormButtonContinue ?? 'Continue';
      case 1:
        return l10n?.qrFormButtonPreview ?? 'Preview';
      case 2:
        return l10n?.qrFormButtonSave ?? 'Save QR Code';
      default:
        return l10n?.qrFormButtonContinue ?? 'Continue';
    }
  }

  IconData _getButtonIcon(int step) {
    switch (step) {
      case 0:
        return Icons.arrow_forward_rounded;
      case 1:
        return Icons.visibility_rounded;
      case 2:
        return Icons.save_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  bool _canProceed(int step) {
    switch (step) {
      case 0: // Form validation step
        return _validateCurrentForm();
      case 1: // Customization step - always allow proceeding
        return true;
      case 2: // Preview step - always allow saving
        return true;
      default:
        return false;
    }
  }

  bool _validateCurrentForm() {
    switch (widget.qrType) {
      case QRType.url:
        final urlState = ref.watch(urlFormProvider);
        return urlState.isValid;
      case QRType.text:
        final textState = ref.watch(textFormProvider);
        return textState.isValid;
      case QRType.personalInfo:
      case QRType.wifi:
      case QRType.email:
      case QRType.location:
        // For "coming soon" forms, always allow proceeding
        return true;
    }
  }

  void _saveQRCode() {
    // TODO: Implement save functionality
    Navigator.of(context).pop();
  }
}