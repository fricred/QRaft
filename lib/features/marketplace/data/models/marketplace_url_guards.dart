/// Shared URL/path guards for marketplace media (mitigation T-07-02).
///
/// Extracted from MaterialModel so product images enforce the same invariant
/// instead of re-implementing it.
library;

/// Accepts only an empty string or an `https://` URL; anything else is
/// sanitized to `''` (fail-safe), which callers render as a gradient fallback.
String sanitizeHttpsUrl(String? raw) {
  final value = raw ?? '';
  return value.isEmpty || value.startsWith('https://') ? value : '';
}

final RegExp _schemePrefix = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://');

/// Storage paths are relative to their bucket. Rejects absolute URLs, root-
/// anchored paths and traversal.
///
/// This is the Dart mirror of the `product_images_path_relative` CHECK. It
/// matters because the absolute URL is built by concatenating the project host:
/// a poisoned row holding `https://evil.example.com/x` would pass the plain
/// https guard, but cannot pass this one.
bool isSafeStoragePath(String path) =>
    path.isNotEmpty &&
    !path.startsWith('/') &&
    !path.contains('..') &&
    !_schemePrefix.hasMatch(path);
