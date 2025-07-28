import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/entities/qr_data_models.dart';
import '../widgets/qr_form_factory.dart';
import '../widgets/forms/url_form.dart';
import '../widgets/forms/text_form.dart';
import '../widgets/forms/colombian_tax_form.dart';
import '../widgets/forms/colombian_personal_step.dart';
import '../widgets/forms/colombian_address_step.dart';
import '../widgets/color_picker_widget.dart';
import '../controllers/qr_customization_controller.dart';
import '../providers/qr_providers.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class QRWizardStep {
  final String title;
  final IconData icon;
  final Widget widget;
  final bool isRequired;
  
  QRWizardStep({
    required this.title,
    required this.icon,
    required this.widget,
    this.isRequired = false,
  });
}

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
  bool _isSaving = false;
  
  // Dynamic step configuration based on QR type
  List<QRWizardStep>? _steps;
  int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
  }
  

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<QRWizardStep> _getStepsForQRType(QRType qrType) {
    switch (qrType) {
      case QRType.personalInfo:
        return [
          QRWizardStep(
            title: 'Personal',
            icon: Icons.person_rounded,
            widget: ColombianPersonalStep(onContinue: _nextPage),
            isRequired: true,
          ),
          QRWizardStep(
            title: 'Contact',
            icon: Icons.location_on_rounded,
            widget: ColombianAddressStep(onContinue: _nextPage),
            isRequired: true,
          ),
          QRWizardStep(
            title: 'Style',
            icon: Icons.palette_rounded,
            widget: _buildCustomizationStep(),
            isRequired: false,
          ),
          QRWizardStep(
            title: 'Save',
            icon: Icons.save_rounded,
            widget: _buildPreviewStep(),
            isRequired: false,
          ),
        ];
      default:
        return [
          QRWizardStep(
            title: 'Info',
            icon: Icons.edit_rounded,
            widget: QRFormFactory.buildForm(qrType, _nextPage),
            isRequired: true,
          ),
          QRWizardStep(
            title: 'Style',
            icon: Icons.palette_rounded,
            widget: _buildCustomizationStep(),
            isRequired: false,
          ),
          QRWizardStep(
            title: 'Save',
            icon: Icons.save_rounded,
            widget: _buildPreviewStep(),
            isRequired: false,
          ),
        ];
    }
  }

  void _nextPage() {
    if (_currentPage < _totalSteps - 1) {
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
    // Configure steps based on QR type
    if (_steps == null) {
      _steps = _getStepsForQRType(widget.qrType);
      _totalSteps = _steps!.length;
    }
    
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
              '${_currentPage + 1}/$_totalSteps',
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
          // Progress indicator with icons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(_steps?.length ?? 3, (index) {
                final bool isCompleted = index < _currentPage;
                final bool isCurrent = index == _currentPage;
                final bool isValid = _canProceed(index);
                final step = _steps![index];
                
                Color stepColor;
                Color iconColor;
                if (isCompleted) {
                  stepColor = Color(widget.qrType.gradientColors.first);
                  iconColor = Colors.white;
                } else if (isCurrent) {
                  stepColor = isValid 
                      ? Color(widget.qrType.gradientColors.first)
                      : const Color(0xFFEF4444);
                  iconColor = Colors.white;
                } else {
                  stepColor = Colors.grey[700]!;
                  iconColor = Colors.grey[500]!;
                }
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        // Container with padding for badge overflow
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Step circle with icon
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: stepColor,
                                  border: step.isRequired && !isValid && isCurrent
                                      ? Border.all(color: const Color(0xFFEF4444), width: 2)
                                      : null,
                                ),
                                child: Icon(
                                  isCompleted ? Icons.check_rounded : step.icon,
                                  color: iconColor,
                                  size: 20,
                                ),
                              ),
                              // Required indicator badge
                              if (step.isRequired && !isValid && !isCompleted)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFEF4444),
                                      border: Border.all(
                                        color: const Color(0xFF1A1A1A),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.priority_high,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Step title
                        Text(
                          step.title,
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.grey[500],
                            fontSize: 10,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
              physics: !_canProceed(_currentPage)
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: _steps?.map((step) => step.widget).toList() ?? [],
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
                        isLoading: _currentPage == 2 ? _isSaving : false,
                        onPressed: _canProceed(_currentPage) 
                            ? (_currentPage == _totalSteps - 1 ? _saveQRCode : _nextPage)
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
        final colombianState = ref.watch(colombianTaxFormProvider);
        return colombianState.taxData.qrData;
      case QRType.wifi:
      case QRType.email:
      case QRType.location:
        return 'Coming soon - ${widget.qrType.getDisplayName(context)}';
    }
  }

  String _getStepTitle(int step, BuildContext context) {
    if (_steps != null && step < _steps!.length) {
      return _steps![step].title;
    }
    return '';
  }

  String _getButtonText(int step, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (step == _totalSteps - 1) {
      return l10n?.qrFormButtonSave ?? 'Save QR Code';
    } else if (step == _totalSteps - 2) {
      return l10n?.qrFormButtonPreview ?? 'Preview';
    } else {
      return l10n?.qrFormButtonContinue ?? 'Continue';
    }
  }

  IconData _getButtonIcon(int step) {
    if (_steps != null && step < _steps!.length) {
      if (step == _totalSteps - 1) {
        return Icons.save_rounded;
      } else if (step == _totalSteps - 2) {
        return Icons.visibility_rounded;
      } else {
        return Icons.arrow_forward_rounded;
      }
    }
    return Icons.arrow_forward_rounded;
  }

  bool _canProceed(int step) {
    if (_steps == null || step >= _steps!.length) return false;
    
    final currentStep = _steps![step];
    
    // For Colombian tax form, validate based on step requirements
    if (widget.qrType == QRType.personalInfo) {
      switch (step) {
        case 0: // Personal info - required
        case 1: // Address info - required
          return _validateColombianTaxForm();
        case 2: // Tax info - optional
        case 3: // Preview
        case 4: // Customization
        case 5: // Save
          return _validateColombianTaxForm(); // Basic validation for core fields
        default:
          return false;
      }
    }
    
    // For other QR types
    if (currentStep.isRequired) {
      return _validateCurrentForm();
    }
    
    return true; // Optional steps always allow proceeding
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
        return _validateColombianTaxForm();
      case QRType.wifi:
      case QRType.email:
      case QRType.location:
        // For "coming soon" forms, always allow proceeding
        return true;
    }
  }
  
  bool _validateColombianTaxForm() {
    final state = ref.watch(colombianTaxFormProvider);
    
    // Validate based on current step
    switch (_currentPage) {
      case 0: // Personal info step
        return state.isPersonalInfoValid;
      case 1: // Contact info step
        return state.isPersonalInfoValid && state.isAddressInfoValid;
      case 2: // Style step - require basic validation
      case 3: // Save step - require basic validation
        return state.isPersonalInfoValid && state.isAddressInfoValid;
      default:
        return state.isPersonalInfoValid && state.isAddressInfoValid;
    }
  }

  void _saveQRCode() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Get current user
      final authProvider = ref.read(supabaseAuthProvider);
      if (authProvider.currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Get form data based on QR type
      final qrData = _getQRDataModel();
      if (qrData == null) {
        throw Exception('Invalid form data');
      }
      
      // Get QR name from form
      final qrName = _getQRName();
      if (qrName.isEmpty) {
        throw Exception('QR name is required');
      }
      
      // Get customization
      final customizationState = ref.read(qrCustomizationControllerProvider);
      
      // Save QR code using use case
      final generateQRUseCase = ref.read(generateQRUseCaseProvider);
      final savedQRCode = await generateQRUseCase.execute(
        name: qrName,
        type: widget.qrType,
        data: qrData,
        userId: authProvider.currentUser!.id,
        customization: customizationState.customization,
      );
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('QR code "$qrName" saved successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF00FF88),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate back to home
        Navigator.of(context).pop(savedQRCode);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to save QR code: ${e.toString()}')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  QRDataModel? _getQRDataModel() {
    switch (widget.qrType) {
      case QRType.url:
        final urlState = ref.read(urlFormProvider);
        if (!urlState.isValid) return null;
        return urlState.urlData;
      case QRType.text:
        final textState = ref.read(textFormProvider);
        if (!textState.isValid) return null;
        return textState.textData;
      case QRType.personalInfo:
        final colombianState = ref.read(colombianTaxFormProvider);
        if (!colombianState.isValid) return null;
        return colombianState.taxData;
      case QRType.wifi:
      case QRType.email:
      case QRType.location:
        // For "coming soon" forms, return a placeholder
        return URLData(url: 'https://qraft.app/coming-soon');
    }
  }
  
  String _getQRName() {
    switch (widget.qrType) {
      case QRType.url:
        final urlState = ref.read(urlFormProvider);
        return urlState.name;
      case QRType.text:
        final textState = ref.read(textFormProvider);
        return textState.name;
      case QRType.personalInfo:
        final colombianState = ref.read(colombianTaxFormProvider);
        return colombianState.qrName;
      case QRType.wifi:
      case QRType.email:
      case QRType.location:
        return 'Coming Soon - ${widget.qrType.getDisplayName(context)}';
    }
  }
}

