import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/entities/qr_data_models.dart';
import '../controllers/qr_customization_controller.dart';
import '../providers/qr_providers.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// WiFi Form State
class WiFiFormState {
  final String networkName;
  final String password;
  final String security;
  final bool hidden;
  final String? networkNameError;
  final String? passwordError;

  const WiFiFormState({
    this.networkName = '',
    this.password = '',
    this.security = 'WPA',
    this.hidden = false,
    this.networkNameError,
    this.passwordError,
  });

  WiFiFormState copyWith({
    String? networkName,
    String? password,
    String? security,
    bool? hidden,
    String? networkNameError,
    String? passwordError,
  }) {
    return WiFiFormState(
      networkName: networkName ?? this.networkName,
      password: password ?? this.password,
      security: security ?? this.security,
      hidden: hidden ?? this.hidden,
      networkNameError: networkNameError,
      passwordError: passwordError,
    );
  }

  bool get isValid => networkName.isNotEmpty && networkNameError == null && passwordError == null;

  WiFiData get wifiData => WiFiData(
    networkName: networkName,
    password: password,
    security: security,
    hidden: hidden,
  );
}

/// WiFi Form Controller
class WiFiFormController extends StateNotifier<WiFiFormState> {
  WiFiFormController() : super(const WiFiFormState());

  void updateNetworkName(String name, [AppLocalizations? localizations]) {
    String? error;
    if (name.isEmpty) {
      error = localizations?.networkNameRequired ?? 'Network name is required';
    } else if (name.length > 32) {
      error = localizations?.networkNameTooLong ?? 'Network name must be 32 characters or less';
    }
    
    state = state.copyWith(
      networkName: name,
      networkNameError: error,
    );
  }

  void updatePassword(String password, [AppLocalizations? localizations]) {
    String? error;
    if (state.security != 'nopass' && password.isEmpty) {
      error = localizations?.passwordRequiredForSecuredNetworks ?? 'Password is required for secured networks';
    } else if (password.length > 63) {
      error = localizations?.passwordTooLong ?? 'Password must be 63 characters or less';
    }
    
    state = state.copyWith(
      password: password,
      passwordError: error,
    );
  }

  void updateSecurity(String security) {
    state = state.copyWith(
      security: security,
      passwordError: security == 'nopass' ? null : state.passwordError,
    );
    
    updatePassword(state.password, null);
  }

  void updateHidden(bool hidden) {
    state = state.copyWith(hidden: hidden);
  }

  void reset() {
    state = const WiFiFormState();
  }
}

/// WiFi Form Provider
final wifiFormProvider = StateNotifierProvider<WiFiFormController, WiFiFormState>((ref) {
  return WiFiFormController();
});

class WiFiQRScreen extends ConsumerStatefulWidget {
  const WiFiQRScreen({super.key});

  @override
  ConsumerState<WiFiQRScreen> createState() => _WiFiQRScreenState();
}

class _WiFiQRScreenState extends ConsumerState<WiFiQRScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _networkController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wifiFormProvider.notifier).reset();
      ref.read(qrCustomizationControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _networkController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wifiState = ref.watch(wifiFormProvider);

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
          AppLocalizations.of(context)?.qrTypeWifi ?? 'WiFi QR',
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
                _buildFormTab(),
                _buildStyleTab(),
              ],
            ),
          ),
          
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
                PrimaryGlassButton(
                  text: AppLocalizations.of(context)?.qrFormButtonSave ?? 'Save QR Code',
                  icon: Icons.save_rounded,
                  isLoading: _isSaving,
                  onPressed: wifiState.isValid ? _saveQRCode : null,
                  width: double.infinity,
                ),
                
                if (!wifiState.isValid) ...[
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

  Widget _buildFormTab() {
    final state = ref.watch(wifiFormProvider);
    final controller = ref.read(wifiFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.wifiNetworkDetails ?? 'WiFi Network Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            AppLocalizations.of(context)?.wifiFormDescription ?? 'Enter WiFi network details to create a QR code for easy sharing',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 100.ms),
          
          const SizedBox(height: 32),
          
          _buildTextField(
            controller: _networkController,
            label: AppLocalizations.of(context)?.networkNameLabel ?? 'Network Name (SSID) *',
            hint: AppLocalizations.of(context)?.networkNameHint ?? 'Enter WiFi network name',
            error: state.networkNameError,
            onChanged: (value) => controller.updateNetworkName(value, AppLocalizations.of(context)),
            icon: Icons.wifi_rounded,
          ).animate()
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideX(begin: -0.3, duration: 600.ms, delay: 200.ms),
          
          const SizedBox(height: 20),
          
          _buildSecuritySelector(controller, state.security).animate()
            .fadeIn(duration: 600.ms, delay: 300.ms)
            .slideX(begin: -0.3, duration: 600.ms, delay: 300.ms),
          
          const SizedBox(height: 20),
          
          if (state.security != 'nopass') ...[
            _buildPasswordField(
              controller: _passwordController,
              label: AppLocalizations.of(context)?.wifiPasswordLabel ?? 'Password *',
              hint: AppLocalizations.of(context)?.wifiPasswordHint ?? 'Enter WiFi password',
              error: state.passwordError,
              onChanged: (value) => controller.updatePassword(value, AppLocalizations.of(context)),
            ).animate()
              .fadeIn(duration: 600.ms, delay: 400.ms)
              .slideX(begin: -0.3, duration: 600.ms, delay: 400.ms),
            
            const SizedBox(height: 20),
          ],
          
          _buildHiddenToggle(controller, state.hidden).animate()
            .fadeIn(duration: 600.ms, delay: 500.ms)
            .slideX(begin: -0.3, duration: 600.ms, delay: 500.ms),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStyleTab() {
    final customizationState = ref.watch(qrCustomizationControllerProvider);
    final customizationController = ref.read(qrCustomizationControllerProvider.notifier);
    
    return Column(
      children: [
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
              _buildQRPreviewWidget(customizationState, isSmallPreview: true),
              const SizedBox(height: 12),
              
              if (ref.watch(wifiFormProvider).isValid)
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
                        const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)?.viewFullSize ?? 'View Full Size',
                          style: const TextStyle(
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
        
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
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
                            Icon(Icons.palette_rounded, size: 18),
                            SizedBox(height: 2),
                            Text(AppLocalizations.of(context)?.styleColors ?? 'Colors', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_size_select_large_rounded, size: 18),
                            SizedBox(height: 2),
                            Text(AppLocalizations.of(context)?.qrSize ?? 'Size', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, size: 18),
                            SizedBox(height: 2),
                            Text(AppLocalizations.of(context)?.logo ?? 'Logo', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildColorsTabContent(customizationController, customizationState),
                      _buildSizeTabContent(customizationController, customizationState),
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
    final wifiState = ref.watch(wifiFormProvider);
    final qrSize = isSmallPreview ? 150.0 : customizationState.customization.size;
    
    if (!wifiState.isValid) {
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
      data: wifiState.wifiData.qrData,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    required IconData icon,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: error != null 
                ? const Color(0xFFEF4444)
                : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(icon, color: const Color(0xFF1A73E8), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: error != null 
                ? const Color(0xFFEF4444)
                : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF1A73E8), size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[400],
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSecuritySelector(WiFiFormController controller, String currentSecurity) {
    final securityTypes = [
      {'value': 'WPA', 'label': AppLocalizations.of(context)?.securityWpaRecommended ?? 'WPA/WPA2 (Recommended)', 'icon': Icons.security_rounded},
      {'value': 'WEP', 'label': AppLocalizations.of(context)?.securityWepLegacy ?? 'WEP (Legacy)', 'icon': Icons.shield_rounded},
      {'value': 'nopass', 'label': AppLocalizations.of(context)?.securityOpenNetwork ?? 'Open Network (No Password)', 'icon': Icons.wifi_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.securityType ?? 'Security Type',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...securityTypes.map((type) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => controller.updateSecurity(type['value'] as String),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: currentSecurity == type['value'] 
                    ? const Color(0xFF1A73E8).withValues(alpha: 0.2)
                    : const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentSecurity == type['value'] 
                      ? const Color(0xFF1A73E8)
                      : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      color: currentSecurity == type['value'] 
                        ? const Color(0xFF1A73E8)
                        : Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        type['label'] as String,
                        style: TextStyle(
                          color: currentSecurity == type['value'] 
                            ? Colors.white
                            : Colors.grey[300],
                          fontSize: 14,
                          fontWeight: currentSecurity == type['value'] 
                            ? FontWeight.w600
                            : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (currentSecurity == type['value'])
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF1A73E8),
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildHiddenToggle(WiFiFormController controller, bool isHidden) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_off_rounded,
            color: isHidden ? const Color(0xFF1A73E8) : Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.hiddenNetwork ?? 'Hidden Network',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)?.hiddenNetworkDescription ?? 'Network name is not broadcasted publicly',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isHidden,
            onChanged: controller.updateHidden,
            activeColor: const Color(0xFF1A73E8),
          ),
        ],
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
            style: TextStyle(
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
            state.customization.hasLogo ? (AppLocalizations.of(context)?.logoAddedTitle ?? 'Logo Added') : (AppLocalizations.of(context)?.noLogoTitle ?? 'No Logo'),
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
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
            
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
                        
                        _buildQRPreviewWidget(customizationState, isSmallPreview: false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
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
              backgroundColor: Color(0xFF00FF88),
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
      
      final wifiState = ref.read(wifiFormProvider);
      if (!wifiState.isValid) {
        throw Exception('Invalid form data');
      }
      
      final customizationState = ref.read(qrCustomizationControllerProvider);
      
      final generateQRUseCase = ref.read(generateQRUseCaseProvider);
      final savedQRCode = await generateQRUseCase.execute(
        name: 'WiFi: ${wifiState.networkName}',
        type: QRType.wifi,
        data: wifiState.wifiData,
        userId: authProvider.currentUser!.id,
        customization: customizationState.customization,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('WiFi QR code "${wifiState.networkName}" saved successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF00FF88),
            duration: const Duration(seconds: 3),
          ),
        );
        
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
}