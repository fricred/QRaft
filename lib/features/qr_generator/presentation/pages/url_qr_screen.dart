import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/entities/qr_code_entity.dart';
import '../../domain/entities/qr_data_models.dart';
import '../widgets/forms/url_form.dart';
import '../controllers/qr_customization_controller.dart';
import '../controllers/qr_generator_controller.dart';
import '../providers/qr_providers.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';
import '../../../qr_library/presentation/providers/qr_library_providers.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class URLQRScreen extends ConsumerStatefulWidget {
  final QRCodeEntity? editingQRCode;

  const URLQRScreen({
    super.key,
    this.editingQRCode,
  });

  @override
  ConsumerState<URLQRScreen> createState() => _URLQRScreenState();
}

class _URLQRScreenState extends ConsumerState<URLQRScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize form and customization state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final qrToEdit = widget.editingQRCode;

      if (qrToEdit != null) {
        // EDIT MODE: Pre-fill form and customization
        final l10n = AppLocalizations.of(context);
        final urlData = URLData(url: qrToEdit.data);
        ref.read(urlFormProvider.notifier).loadFromEntity(urlData, qrToEdit.name, l10n);
        ref.read(qrCustomizationControllerProvider.notifier).loadFromEntity(qrToEdit);
      } else {
        // CREATE MODE: Reset providers
        ref.read(urlFormProvider.notifier).reset();
        ref.read(qrCustomizationControllerProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urlState = ref.watch(urlFormProvider);

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
          widget.editingQRCode != null
            ? (AppLocalizations.of(context)?.editQRCode ?? 'Edit QR Code')
            : (AppLocalizations.of(context)?.qrTypeWebsiteUrl ?? 'Website URL QR'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1A73E8),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          tabs: [
            Tab(
              icon: const Icon(Icons.edit_rounded),
              text: AppLocalizations.of(context)?.qrFormStepEnterInfo ?? 'Form',
            ),
            Tab(
              icon: const Icon(Icons.palette_rounded),
              text: AppLocalizations.of(context)?.qrFormStepCustomize ?? 'Style',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Form Tab
                URLForm(onContinue: () => _tabController.animateTo(1)),
                
                // Style Tab
                _buildStyleTab(),
              ],
            ),
          ),
          
          // Bottom action area
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Save button
                PrimaryGlassButton(
                  text: widget.editingQRCode != null
                    ? (AppLocalizations.of(context)?.saveChanges ?? 'Save Changes')
                    : (AppLocalizations.of(context)?.qrFormButtonSave ?? 'Save QR Code'),
                  icon: widget.editingQRCode != null ? Icons.check_rounded : Icons.save_rounded,
                  isLoading: _isSaving,
                  onPressed: urlState.isValid ? _saveQRCode : null,
                  width: double.infinity,
                ),
                
                if (!urlState.isValid) ...[
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.qrFormCompleteFields ?? 'Complete the form to save QR code',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleTab() {
    final customizationState = ref.watch(qrCustomizationControllerProvider);
    final customizationController = ref.read(qrCustomizationControllerProvider.notifier);
    
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context)?.customizeQR ?? 'Customize your QR',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, duration: 600.ms),
        ),
        
        // QR Preview - Fixed at top with expand button
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(customizationState.customization.backgroundColor),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // QR Preview
              _buildQRPreviewWidget(customizationState, isSmallPreview: true),
              const SizedBox(height: 12),
              
              // Expand button
              if (ref.watch(urlFormProvider).isValid)
                GestureDetector(
                  onTap: () => _showFullSizePreview(customizationState),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.zoom_in_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)?.viewFullSize ?? 'View Full Size',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ).animate()
          .fadeIn(duration: 800.ms, delay: 200.ms)
          .scale(begin: const Offset(0.8, 0.8), duration: 800.ms, delay: 200.ms),
        
        // Customization Controls with Tabs
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A73E8), Color(0xFF6366F1)],
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
                              Icons.palette_rounded,
                              size: 18,
                            ),
                            const SizedBox(height: 2),
                            Text(AppLocalizations.of(context)?.styleColors ?? 'Colors', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_size_select_large_rounded,
                              size: 18,
                            ),
                            const SizedBox(height: 2),
                            Text(AppLocalizations.of(context)?.qrSize ?? 'Size', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 18,
                            ),
                            const SizedBox(height: 2),
                            Text(AppLocalizations.of(context)?.logo ?? 'Logo', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tab Views
                Expanded(
                  child: TabBarView(
                    children: [
                      // Colors Tab
                      _buildColorsTabContent(customizationController, customizationState),
                      
                      // Size Tab
                      _buildSizeTabContent(customizationController, customizationState),
                      
                      // Logo Tab
                      _buildLogoTabContent(customizationController, customizationState),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRPreviewWidget(QRCustomizationState customizationState, {bool isSmallPreview = false}) {
    final urlState = ref.watch(urlFormProvider);
    final qrSize = isSmallPreview ? 150.0 : customizationState.customization.size;
    
    if (!urlState.isValid) {
      return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_rounded,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.completeFormToSeePreview ?? 'Complete form\nto see preview',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return QrImageView(
      data: ref.read(urlFormProvider.notifier).getFormattedURL(urlState.url),
      version: QrVersions.auto,
      size: qrSize,
      backgroundColor: Color(customizationState.customization.backgroundColor),
      eyeStyle: QrEyeStyle(
        eyeShape: customizationState.customization.eyeShape == 0 
            ? QrEyeShape.square 
            : QrEyeShape.circle,
        color: Color(customizationState.customization.eyeColor),
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: customizationState.customization.dataShape == 0
            ? QrDataModuleShape.square
            : QrDataModuleShape.circle,
        color: Color(customizationState.customization.foregroundColor),
      ),
      embeddedImage: customizationState.customization.hasLogo && 
                   customizationState.customization.logoPath != null
          ? FileImage(File(customizationState.customization.logoPath!))
          : null,
      embeddedImageStyle: QrEmbeddedImageStyle(
        size: Size(customizationState.customization.logoSize, 
                  customizationState.customization.logoSize),
      ),
    );
  }

  Widget _buildColorsTabContent(QRCustomizationController controller, QRCustomizationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildColorRow(
            AppLocalizations.of(context)?.foregroundColor ?? 'QR Color',
            Color(state.customization.foregroundColor),
            controller.updateForegroundColor,
          ),
          const SizedBox(height: 20),
          _buildColorRow(
            AppLocalizations.of(context)?.backgroundColor ?? 'Background',
            Color(state.customization.backgroundColor),
            controller.updateBackgroundColor,
          ),
          const SizedBox(height: 20),
          _buildColorRow(
            AppLocalizations.of(context)?.eyeColor ?? 'Eye Color',
            Color(state.customization.eyeColor),
            controller.updateEyeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSizeTabContent(QRCustomizationController controller, QRCustomizationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)?.qrCodeSizeTitle ?? 'QR Code Size',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${state.customization.size.toInt()}px',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          Slider(
            value: state.customization.size,
            min: 150.0,
            max: 500.0,
            divisions: 14,
            activeColor: const Color(0xFF1A73E8),
            inactiveColor: Colors.grey[600],
            onChanged: controller.updateSize,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('150px', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              Text(AppLocalizations.of(context)?.sizeSmall ?? 'Small', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              Text(AppLocalizations.of(context)?.sizeMedium ?? 'Medium', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              Text(AppLocalizations.of(context)?.sizeLarge ?? 'Large', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              Text('500px', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoTabContent(QRCustomizationController controller, QRCustomizationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo preview
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: state.customization.hasLogo 
                  ? Colors.transparent 
                  : Colors.grey[700],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: state.customization.hasLogo && 
                   state.customization.logoPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(state.customization.logoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                    ),
                  )
                : Icon(
                    Icons.add_photo_alternate_rounded,
                    color: Colors.grey[400],
                    size: 48,
                  ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            state.customization.hasLogo
                ? (AppLocalizations.of(context)?.logoAddedTitle ?? 'Logo Added')
                : (AppLocalizations.of(context)?.noLogoTitle ?? 'No Logo'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            state.customization.hasLogo
                ? (AppLocalizations.of(context)?.logoWillAppearInCenter ?? 'Your logo will appear in the center of the QR code')
                : (AppLocalizations.of(context)?.addLogoToPersonalize ?? 'Add a logo to personalize your QR code'),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          // Logo actions
          if (state.customization.hasLogo) ...[
            Row(
              children: [
                Expanded(
                  child: SecondaryGlassButton(
                    text: AppLocalizations.of(context)?.remove ?? 'Remove',
                    icon: Icons.delete_outline,
                    onPressed: controller.removeLogo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SecondaryGlassButton(
                    text: AppLocalizations.of(context)?.change ?? 'Change',
                    icon: Icons.swap_horizontal_circle,
                    onPressed: () => _handleAddLogo(controller),
                  ),
                ),
              ],
            ),
          ] else ...[
            PrimaryGlassButton(
              text: AppLocalizations.of(context)?.addLogo ?? 'Add Logo',
              icon: Icons.add_photo_alternate,
              onPressed: () => _handleAddLogo(controller),
              width: double.infinity,
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildColorRow(String title, Color selectedColor, Function(Color) onChanged) {
    const predefinedColors = [
      Color(0xFF000000), Color(0xFFFFFFFF), Color(0xFF808080),
      Color(0xFF1A73E8), Color(0xFF00FF88), Color(0xFF6366F1),
      Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFF10B981),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Selected color display
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Color options
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: predefinedColors.map((color) {
                  final isSelected = color == selectedColor;
                  return GestureDetector(
                    onTap: () => onChanged(color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF00FF88)
                              : Colors.white.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: isSelected ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ) : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }


  void _showFullSizePreview(QRCustomizationState customizationState) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Blur background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
            
            // QR Code centered with scrollable area
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(customizationState.customization.backgroundColor),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Size indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${customizationState.customization.size.toInt()}px',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Full size QR
                        _buildQRPreviewWidget(customizationState, isSmallPreview: false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Close button
            Positioned(
              top: 60,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        controller.updateLogo(image.path, 40.0);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.logoUpdatedSuccessfully ?? 'Logo updated successfully!'),
              backgroundColor: const Color(0xFF00FF88),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.failedToPickImage(e.toString()) ?? 'Failed to pick image: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _saveQRCode() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = ref.read(supabaseAuthProvider);
      if (authProvider.currentUser == null) {
        throw Exception('User not authenticated');
      }

      final urlState = ref.read(urlFormProvider);
      if (!urlState.isValid) {
        throw Exception('Invalid form data');
      }

      final customizationState = ref.read(qrCustomizationControllerProvider);

      if (widget.editingQRCode != null) {
        // EDIT MODE: Update existing QR code
        final controller = ref.read(qrGeneratorControllerProvider.notifier);
        final updatedQR = widget.editingQRCode!.copyWith(
          name: urlState.name,
          data: ref.read(urlFormProvider.notifier).getFormattedURL(urlState.url),
          displayData: ref.read(urlFormProvider.notifier).getFormattedURL(urlState.url),
          customization: customizationState.customization,
          updatedAt: DateTime.now(),
        );

        await controller.updateQRCode(updatedQR);

        // Invalidate provider to refresh UI across app
        ref.invalidate(userQRCodesProvider);

        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(l10n?.qrUpdatedSuccess(urlState.name) ?? 'QR code "${urlState.name}" updated successfully!'),
                ],
              ),
              backgroundColor: const Color(0xFF00FF88),
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.of(context).pop(updatedQR);
        }
      } else {
        // CREATE MODE: Generate new QR code
        final generateQRUseCase = ref.read(generateQRUseCaseProvider);
        final savedQRCode = await generateQRUseCase.execute(
          name: urlState.name,
          type: QRType.url,
          data: urlState.urlData,
          userId: authProvider.currentUser!.id,
          customization: customizationState.customization,
        );

        // Invalidate provider to refresh UI across app
        ref.invalidate(userQRCodesProvider);

        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(l10n?.qrSavedSuccess(urlState.name) ?? 'QR code "${urlState.name}" saved successfully!'),
                ],
              ),
              backgroundColor: const Color(0xFF00FF88),
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.of(context).pop(savedQRCode);
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n?.failedToSaveQR(e.toString()) ?? 'Failed to save QR code: ${e.toString()}')),
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
}