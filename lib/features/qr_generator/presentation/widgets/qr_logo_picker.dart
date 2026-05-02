import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A widget that lets the user pick a logo image from their gallery.
///
/// Security enforcements (per threat model T-05-02-01, T-05-02-02):
///   - Only PNG and JPG/JPEG files are accepted; SVG and other formats are
///     rejected with a user-visible SnackBar to prevent XSS via SVG paths.
///   - Files larger than 2 MB are rejected with a SnackBar — oversized images
///     are a denial-of-service vector during QR rendering.
///
/// The widget calls [onLogoSelected] with the picked file path on valid
/// selection, or with null to signal removal. It does NOT resize the image
/// (resizing is handled in Phase 7 marketplace plan for the 512 px cap).
class QrLogoPickerWidget extends StatelessWidget {
  /// Called with the selected file path on valid pick, or null to remove.
  final ValueChanged<String?> onLogoSelected;

  /// Currently active logo path — shown as a 48×48 CircleAvatar preview.
  final String? currentLogoPath;

  const QrLogoPickerWidget({
    super.key,
    required this.onLogoSelected,
    this.currentLogoPath,
  });

  static const _maxBytes = 2 * 1024 * 1024; // 2 MB
  static const _allowedExtensions = {'.png', '.jpg', '.jpeg'};

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'qr_logo_picker',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Preview or placeholder
          GestureDetector(
            onTap: () => _pickLogo(context),
            child: _buildPreview(),
          ),
          const SizedBox(width: 12),
          // Action buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () => _pickLogo(context),
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: Text(
                  currentLogoPath != null ? 'Change Logo' : 'Add Logo',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (currentLogoPath != null)
                TextButton.icon(
                  onPressed: () => onLogoSelected(null),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (currentLogoPath != null) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: FileImage(File(currentLogoPath!)),
        backgroundColor: Colors.grey[200],
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey[200],
      child: Icon(Icons.image_outlined, size: 24, color: Colors.grey[600]),
    );
  }

  Future<void> _pickLogo(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return; // user cancelled

    // --- T-05-02-01: Extension whitelist (reject SVG, webp, etc.) ---
    final ext = _extension(picked.path).toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only PNG or JPG files are supported')),
        );
      }
      return;
    }

    // --- T-05-02-02: File size limit (reject > 2 MB) ---
    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo must be under 2MB')),
        );
      }
      return;
    }

    onLogoSelected(picked.path);
  }

  /// Extracts the dot-prefixed extension from [path], e.g. ".png".
  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return '';
    return path.substring(dot);
  }
}
