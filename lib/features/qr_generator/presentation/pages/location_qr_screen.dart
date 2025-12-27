import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/entities/qr_code_entity.dart';
import '../../domain/entities/qr_data_models.dart';
import '../controllers/qr_customization_controller.dart';
import '../controllers/qr_generator_controller.dart';
import '../providers/qr_providers.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';
import '../../../qr_library/presentation/providers/qr_library_providers.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';

/// Location Form State
class LocationFormState {
  final String name;
  final String latitude;
  final String longitude;
  final String? nameError;
  final String? latitudeError;
  final String? longitudeError;
  final bool isLoadingLocation;

  const LocationFormState({
    this.name = '',
    this.latitude = '',
    this.longitude = '',
    this.nameError,
    this.latitudeError,
    this.longitudeError,
    this.isLoadingLocation = false,
  });

  LocationFormState copyWith({
    String? name,
    String? latitude,
    String? longitude,
    String? nameError,
    String? latitudeError,
    String? longitudeError,
    bool? isLoadingLocation,
  }) {
    return LocationFormState(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      nameError: nameError,
      latitudeError: latitudeError,
      longitudeError: longitudeError,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
    );
  }

  bool get isValid => 
      name.isNotEmpty &&
      name.length >= 2 &&
      latitude.isNotEmpty &&
      longitude.isNotEmpty &&
      nameError == null &&
      latitudeError == null &&
      longitudeError == null;

  LocationData get locationData {
    final lat = double.tryParse(latitude) ?? 0.0;
    final lng = double.tryParse(longitude) ?? 0.0;
    return LocationData(
      latitude: lat,
      longitude: lng,
      name: name.isEmpty ? null : name,
    );
  }
}

/// Location Form Controller
class LocationFormController extends StateNotifier<LocationFormState> {
  LocationFormController() : super(const LocationFormState());

  void updateName(String name, [AppLocalizations? localizations]) {
    String? error;
    if (name.isEmpty) {
      error = localizations?.locationNameRequired ?? 'Location name is required';
    } else if (name.length < 2) {
      error = localizations?.locationNameTooShort ?? 'Location name must be at least 2 characters';
    }
    
    state = state.copyWith(
      name: name,
      nameError: error,
    );
  }

  void updateLatitude(String latitude, [AppLocalizations? localizations]) {
    String? error;
    if (latitude.isEmpty) {
      error = localizations?.latitudeRequired ?? 'Latitude is required';
    } else {
      final lat = double.tryParse(latitude);
      if (lat == null) {
        error = localizations?.latitudeInvalid ?? 'Please enter a valid latitude (-90 to 90)';
      } else if (lat < -90 || lat > 90) {
        error = localizations?.latitudeInvalid ?? 'Please enter a valid latitude (-90 to 90)';
      }
    }
    
    state = state.copyWith(
      latitude: latitude,
      latitudeError: error,
    );
  }

  void updateLongitude(String longitude, [AppLocalizations? localizations]) {
    String? error;
    if (longitude.isEmpty) {
      error = localizations?.longitudeRequired ?? 'Longitude is required';
    } else {
      final lng = double.tryParse(longitude);
      if (lng == null) {
        error = localizations?.longitudeInvalid ?? 'Please enter a valid longitude (-180 to 180)';
      } else if (lng < -180 || lng > 180) {
        error = localizations?.longitudeInvalid ?? 'Please enter a valid longitude (-180 to 180)';
      }
    }
    
    state = state.copyWith(
      longitude: longitude,
      longitudeError: error,
    );
  }

  void setLocation(double latitude, double longitude, [String? name, AppLocalizations? localizations]) {
    // Don't auto-populate name from GPS/map - keep existing name only if user entered it
    String? updatedName = state.name;
    String? nameError;
    
    // Always validate the name field - it must be manually entered by user
    if (updatedName.isEmpty) {
      nameError = localizations?.locationNameRequired ?? 'Location name is required';
    } else if (updatedName.length < 2) {
      nameError = localizations?.locationNameTooShort ?? 'Location name must be at least 2 characters';
    }
    
    state = state.copyWith(
      latitude: latitude.toStringAsFixed(6),
      longitude: longitude.toStringAsFixed(6),
      name: updatedName,
      nameError: nameError,
      latitudeError: null,
      longitudeError: null,
      isLoadingLocation: false,
    );
  }

  void setLoadingLocation(bool loading) {
    state = state.copyWith(isLoadingLocation: loading);
  }

  void reset() {
    state = const LocationFormState();
  }

  /// Load form data from an existing QR code entity (for edit mode)
  void loadFromEntity(LocationData locationData, String qrName, [AppLocalizations? l10n]) {
    state = LocationFormState(
      name: qrName,
      latitude: locationData.latitude.toString(),
      longitude: locationData.longitude.toString(),
      nameError: null,
      latitudeError: null,
      longitudeError: null,
      isLoadingLocation: false,
    );

    // Trigger validation if l10n available
    if (l10n != null) {
      updateName(qrName, l10n);
      updateLatitude(locationData.latitude.toString(), l10n);
      updateLongitude(locationData.longitude.toString(), l10n);
    }
  }
}

/// Location Form Provider
final locationFormProvider = StateNotifierProvider<LocationFormController, LocationFormState>((ref) {
  return LocationFormController();
});

class LocationQRScreen extends ConsumerStatefulWidget {
  final QRCodeEntity? editingQRCode;

  const LocationQRScreen({
    super.key,
    this.editingQRCode,
  });

  @override
  ConsumerState<LocationQRScreen> createState() => _LocationQRScreenState();
}

class _LocationQRScreenState extends ConsumerState<LocationQRScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
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

        // Parse location data from QR code
        final locationData = _parseLocationData(qrToEdit.data);
        ref.read(locationFormProvider.notifier).loadFromEntity(locationData, qrToEdit.name, l10n);
        ref.read(qrCustomizationControllerProvider.notifier).loadFromEntity(qrToEdit);

        // Pre-fill text controllers
        _nameController.text = qrToEdit.name;
        _latitudeController.text = locationData.latitude.toString();
        _longitudeController.text = locationData.longitude.toString();
      } else {
        // CREATE MODE: Reset providers
        ref.read(locationFormProvider.notifier).reset();
        ref.read(qrCustomizationControllerProvider.notifier).reset();
      }
    });
  }

  /// Parse location data from QR code string
  /// Format: geo:latitude,longitude?q=latitude,longitude(name)
  LocationData _parseLocationData(String geoString) {
    double latitude = 0.0;
    double longitude = 0.0;
    String? name;

    try {
      // Remove geo: prefix
      final data = geoString.replaceAll('geo:', '');

      // Split by ? to separate coordinates from query
      final parts = data.split('?');

      // Parse coordinates
      if (parts.isNotEmpty) {
        final coords = parts[0].split(',');
        if (coords.length >= 2) {
          latitude = double.tryParse(coords[0]) ?? 0.0;
          longitude = double.tryParse(coords[1]) ?? 0.0;
        }
      }

      // Parse name from query parameter if exists
      if (parts.length > 1) {
        final query = parts[1];
        if (query.contains('(') && query.contains(')')) {
          final start = query.indexOf('(');
          final end = query.indexOf(')');
          name = Uri.decodeComponent(query.substring(start + 1, end));
        }
      }
    } catch (e) {
      debugPrint('Error parsing location data: $e');
    }

    return LocationData(
      latitude: latitude,
      longitude: longitude,
      name: name,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationFormProvider);

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
            ? 'Edit QR Code'
            : (AppLocalizations.of(context)?.qrTypeLocation ?? 'Location QR'),
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
                  text: widget.editingQRCode != null
                    ? 'Save Changes'
                    : (AppLocalizations.of(context)?.qrFormButtonSave ?? 'Save QR Code'),
                  icon: widget.editingQRCode != null ? Icons.check_rounded : Icons.save_rounded,
                  isLoading: _isSaving,
                  onPressed: locationState.isValid ? _saveQRCode : null,
                  width: double.infinity,
                ),
                
                if (!locationState.isValid) ...[
                  const SizedBox(height: 8),
                  Text(
                    _getValidationMessage(locationState, context),
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
    final state = ref.watch(locationFormProvider);
    final controller = ref.read(locationFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.locationFormTitle ?? 'Location Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, duration: 600.ms),
          
          const SizedBox(height: 8),
          
          Text(
            AppLocalizations.of(context)?.locationFormDescription ?? 'Share your location or any GPS coordinates with a QR code',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 100.ms),
          
          const SizedBox(height: 32),
          
          // Location Name Field
          _buildTextField(
            controller: _nameController,
            label: '${AppLocalizations.of(context)?.locationNameLabel ?? 'Location Name'} *',
            hint: AppLocalizations.of(context)?.locationNameHint ?? 'My Location',
            error: state.nameError,
            onChanged: (value) => controller.updateName(value, AppLocalizations.of(context)),
            icon: Icons.place_rounded,
          ).animate()
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideX(begin: -0.3, duration: 600.ms, delay: 200.ms),
          
          const SizedBox(height: 20),
          
          // Location Options Section
          Text(
            AppLocalizations.of(context)?.locationOptions ?? 'Location Options',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 300.ms),
          
          const SizedBox(height: 12),
          
          // Location Option Cards
          Column(
            children: [
              // Current Location Card
              _buildLocationOptionCard(
                title: AppLocalizations.of(context)?.useCurrentLocation ?? 'Use Current Location',
                description: AppLocalizations.of(context)?.currentLocationDesc ?? 'Use device GPS location',
                icon: Icons.my_location_rounded,
                isLoading: state.isLoadingLocation,
                onPressed: _getCurrentLocation,
              ).animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .slideX(begin: -0.3, duration: 600.ms, delay: 400.ms),
              
              const SizedBox(height: 12),
              
              // Map Picker Card
              _buildLocationOptionCard(
                title: AppLocalizations.of(context)?.pickFromMap ?? 'Pick from Map',
                description: AppLocalizations.of(context)?.mapLocationDesc ?? 'Select point on interactive map',
                icon: Icons.map_rounded,
                onPressed: _pickFromMap,
              ).animate()
                .fadeIn(duration: 600.ms, delay: 450.ms)
                .slideX(begin: -0.3, duration: 600.ms, delay: 450.ms),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Manual Entry Section
          Text(
            AppLocalizations.of(context)?.manualEntry ?? 'Manual Entry',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 500.ms),
          
          const SizedBox(height: 12),
          
          // Latitude Field
          _buildTextField(
            controller: _latitudeController,
            label: AppLocalizations.of(context)?.latitudeLabel ?? 'Latitude *',
            hint: AppLocalizations.of(context)?.latitudeHint ?? '40.7128',
            error: state.latitudeError,
            onChanged: (value) => controller.updateLatitude(value, AppLocalizations.of(context)),
            icon: Icons.location_on_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 600.ms)
            .slideX(begin: -0.3, duration: 600.ms, delay: 600.ms),
          
          const SizedBox(height: 20),
          
          // Longitude Field
          _buildTextField(
            controller: _longitudeController,
            label: AppLocalizations.of(context)?.longitudeLabel ?? 'Longitude *',
            hint: AppLocalizations.of(context)?.longitudeHint ?? '-74.0060',
            error: state.longitudeError,
            onChanged: (value) => controller.updateLongitude(value, AppLocalizations.of(context)),
            icon: Icons.location_on_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          ).animate()
            .fadeIn(duration: 600.ms, delay: 700.ms)
            .slideX(begin: -0.3, duration: 600.ms, delay: 700.ms),
          
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
              
              if (ref.watch(locationFormProvider).isValid)
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
    final locationState = ref.watch(locationFormProvider);
    final qrSize = isSmallPreview ? 150.0 : customizationState.customization.size;
    
    if (!locationState.isValid) {
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
      data: locationState.locationData.qrData,
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
    TextInputType keyboardType = TextInputType.text,
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
            keyboardType: keyboardType,
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
            Column(
              children: [
                SecondaryGlassButton(
                  text: AppLocalizations.of(context)?.change ?? 'Change Logo',
                  icon: Icons.swap_horizontal_circle,
                  onPressed: () => _handleAddLogo(controller),
                  width: double.infinity,
                ),
                const SizedBox(height: 12),
                SecondaryGlassButton(
                  text: AppLocalizations.of(context)?.remove ?? 'Remove Logo',
                  icon: Icons.delete_outline,
                  onPressed: controller.removeLogo,
                  width: double.infinity,
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

  Future<void> _getCurrentLocation() async {
    final controller = ref.read(locationFormProvider.notifier);
    controller.setLoadingLocation(true);

    try {
      final localizations = mounted ? AppLocalizations.of(context) : null;
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(localizations?.locationServiceDisabled ?? 'Location services are disabled');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(localizations?.locationPermissionRequired ?? 'Location permission is required');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(localizations?.locationPermissionRequired ?? 'Location permission is required');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      // Update form fields
      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);
      
      controller.setLocation(
        position.latitude, 
        position.longitude,
        null, // Don't auto-populate name
        localizations
      );

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations?.locationObtained ?? 'Location obtained successfully!'),
            backgroundColor: const Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      controller.setLoadingLocation(false);
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations?.failedToGetLocation(e.toString()) ?? 'Failed to get location: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _pickFromMap() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPickerScreen(),
      ),
    );

    if (result != null && mounted) {
      final controller = ref.read(locationFormProvider.notifier);
      final localizations = AppLocalizations.of(context);
      
      _latitudeController.text = result.latitude.toStringAsFixed(6);
      _longitudeController.text = result.longitude.toStringAsFixed(6);
      
      controller.setLocation(
        result.latitude, 
        result.longitude,
        null, // Don't auto-populate name
        localizations
      );
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

      final locationState = ref.read(locationFormProvider);
      if (!locationState.isValid) {
        throw Exception('Invalid form data');
      }

      final customizationState = ref.read(qrCustomizationControllerProvider);

      if (widget.editingQRCode != null) {
        // EDIT MODE: Update existing QR code
        final controller = ref.read(qrGeneratorControllerProvider.notifier);
        final updatedQR = widget.editingQRCode!.copyWith(
          name: locationState.name.isEmpty ? 'Location QR' : locationState.name,
          data: locationState.locationData.qrData,
          displayData: locationState.locationData.displayText,
          customization: customizationState.customization,
          updatedAt: DateTime.now(),
        );

        await controller.updateQRCode(updatedQR);

        // Invalidate provider to refresh UI across app
        ref.invalidate(userQRCodesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Location QR code "${locationState.name.isEmpty ? 'Location QR' : locationState.name}" updated successfully!'),
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
          name: locationState.name.isEmpty ? 'Location QR' : locationState.name,
          type: QRType.location,
          data: locationState.locationData,
          userId: authProvider.currentUser!.id,
          customization: customizationState.customization,
        );

        // Invalidate provider to refresh UI across app
        ref.invalidate(userQRCodesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Location QR code "${locationState.name.isEmpty ? 'Location QR' : locationState.name}" saved successfully!'),
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

  Widget _buildLocationOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1A73E8),
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          icon,
                          color: const Color(0xFF1A73E8),
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
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
                  color: Colors.grey[500],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _getValidationMessage(LocationFormState state, BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    if (state.name.isEmpty) {
      return localizations?.locationNameRequired ?? 'Location name is required';
    }
    if (state.name.length < 2) {
      return localizations?.locationNameTooShort ?? 'Location name must be at least 2 characters';
    }
    if (state.latitude.isEmpty) {
      return localizations?.latitudeRequired ?? 'Latitude is required';
    }
    if (state.longitude.isEmpty) {
      return localizations?.longitudeRequired ?? 'Longitude is required';
    }
    if (state.latitudeError != null) {
      return state.latitudeError!;
    }
    if (state.longitudeError != null) {
      return state.longitudeError!;
    }
    if (state.nameError != null) {
      return state.nameError!;
    }
    
    return localizations?.qrFormCompleteFields ?? 'Complete all fields to save QR code';
  }
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  String? _locationError;
  
  // Default location (New York City) as fallback
  static const LatLng _defaultLocation = LatLng(40.7128, -74.0060);
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocationForMap();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocationForMap() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        
        // Move map to current location
        _mapController.move(_currentLocation!, 15.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Failed to get location: ${e.toString()}';
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)?.selectLocationOnMap ?? 'Select Location on Map',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Instruction and Status
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2E2E2E),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingLocation) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF1A73E8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)?.gettingCurrentLocation ?? 'Getting your location...',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ] else if (_locationError != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off_rounded,
                        color: Colors.orange[400],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationError!,
                          style: TextStyle(
                            color: Colors.orange[400],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)?.usingDefaultLocation ?? 'Using default location - tap to select',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (_currentLocation != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFF00FF88),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)?.currentLocationFound ?? 'Current location found',
                        style: TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  AppLocalizations.of(context)?.tapMapToSelectLocation ?? 'Tap on the map to select a location',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? _defaultLocation,
                initialZoom: _currentLocation != null ? 15.0 : 10.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedLocation = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'io.gothcorp.qraft',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    // Current location marker (blue with different icon)
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        width: 35,
                        height: 35,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF88),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    
                    // Selected location marker (blue with location pin)
                    if (_selectedLocation != null)
                      Marker(
                        point: _selectedLocation!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A73E8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Selected location info and confirm button
          Container(
            padding: const EdgeInsets.all(16),
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
                // Selected location info
                if (_selectedLocation != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF1A73E8),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context)?.selectedLocation ?? 'Selected Location',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons - horizontal icon row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_currentLocation != null && !_isLoadingLocation)
                      _buildActionButton(
                        icon: Icons.my_location_rounded,
                        label: AppLocalizations.of(context)?.useCurrent ?? 'Current',
                        onPressed: () {
                          setState(() => _selectedLocation = _currentLocation);
                          _mapController.move(_currentLocation!, 15.0);
                        },
                        delayMs: 250,
                      ),
                    if (_currentLocation != null && !_isLoadingLocation)
                      _buildActionButton(
                        icon: Icons.center_focus_strong_rounded,
                        label: 'Center',
                        onPressed: () => _mapController.move(_currentLocation!, 15.0),
                        delayMs: 275,
                      ),
                    _buildActionButton(
                      icon: Icons.check_circle_rounded,
                      label: AppLocalizations.of(context)?.confirmLocation ?? 'Confirm',
                      onPressed: _selectedLocation != null ? _confirmLocation : null,
                      isPrimary: true,
                      delayMs: 300,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.of(context).pop(_selectedLocation);
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isLoading = false,
    int delayMs = 0,
  }) {
    final iconColor = isPrimary
        ? const Color(0xFF00FF88)
        : Colors.white;
    final labelColor = isPrimary
        ? const Color(0xFF00FF88)
        : Colors.grey[400];
    final borderColor = isPrimary
        ? const Color(0xFF00FF88).withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.12);

    const buttonRadius = BorderRadius.all(Radius.circular(16));
    final isDisabled = onPressed == null && !isLoading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: label,
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: buttonRadius,
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: buttonRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E).withValues(alpha: 0.7),
                      borderRadius: buttonRadius,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onPressed,
                        borderRadius: buttonRadius,
                        child: Center(
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                                  ),
                                )
                              : Icon(icon, color: iconColor, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ).animate()
            .fadeIn(duration: 300.ms, delay: Duration(milliseconds: delayMs))
            .scale(
              begin: const Offset(0.9, 0.9),
              duration: 300.ms,
              delay: Duration(milliseconds: delayMs),
            ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ).animate()
            .fadeIn(duration: 200.ms, delay: Duration(milliseconds: delayMs + 100)),
      ],
    );
  }
}