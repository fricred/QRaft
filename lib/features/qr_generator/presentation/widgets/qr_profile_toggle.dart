import 'package:flutter/material.dart';
import '../../domain/value_objects/qr_profile.dart';

/// A 3-segment control for selecting the QR output profile.
///
/// Displays three segments: Print-safe / Digital / Tattoo-safe.
/// Uses Flutter's [SegmentedButton] (Material 3).
///
/// Wrap your screen in a [ProviderScope] with a [QRCustomizationController]
/// and pass the current profile value here.
///
/// Example:
/// ```dart
/// QrProfileToggle(
///   profile: QrProfile.printSafe,
///   onChanged: (p) => controller.updateProfile(p),
/// )
/// ```
class QrProfileToggle extends StatelessWidget {
  /// The currently selected profile.
  final QrProfile profile;

  /// Called when the user selects a different segment.
  final ValueChanged<QrProfile> onChanged;

  const QrProfileToggle({
    super.key,
    required this.profile,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'qr_profile_toggle',
      child: SegmentedButton<QrProfile>(
        segments: const [
          ButtonSegment(
            value: QrProfile.printSafe,
            label: Text('Print-safe'),
            icon: Icon(Icons.print_outlined),
          ),
          ButtonSegment(
            value: QrProfile.digitalOnly,
            label: Text('Digital'),
            icon: Icon(Icons.phone_iphone_outlined),
          ),
          ButtonSegment(
            value: QrProfile.tattooSafe,
            label: Text('Tattoo-safe'),
            icon: Icon(Icons.brush_outlined),
          ),
        ],
        selected: {profile},
        onSelectionChanged: (selected) {
          if (selected.isNotEmpty) {
            onChanged(selected.first);
          }
        },
      ),
    );
  }
}
