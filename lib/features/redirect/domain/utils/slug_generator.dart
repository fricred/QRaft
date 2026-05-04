import 'dart:math';

/// Generates cryptographically secure 6-character alphanumeric slugs
/// for use as scanqraft.app/{slug} identifiers.
///
/// Character set: a-z + 0-9 (36 chars → 36^6 = ~2.1 billion combinations).
/// Uses [Random.secure] to avoid predictable sequences.
class SlugGenerator {
  static const String _chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  static const int _length = 6;

  SlugGenerator._(); // Non-instantiable utility class.

  /// Generate a single 6-character slug.
  ///
  /// Call this inside a retry loop via [generateUntilUnique] when a
  /// uniqueness check against the database is required.
  static String generate() {
    final random = Random.secure();
    return List.generate(
      _length,
      (_) => _chars[random.nextInt(_chars.length)],
    ).join();
  }

  /// Generate a slug that is confirmed unique by [isUnique].
  ///
  /// [isUnique] receives a candidate slug and returns `true` if it is
  /// available. Retries up to [maxAttempts] times before throwing.
  ///
  /// Example usage with the repository:
  /// ```dart
  /// final slug = await SlugGenerator.generateUntilUnique(
  ///   isUnique: (s) async => await repository.isSlugAvailable(s),
  /// );
  /// ```
  static Future<String> generateUntilUnique({
    required Future<bool> Function(String slug) isUnique,
    int maxAttempts = 10,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidate = generate();
      if (await isUnique(candidate)) {
        return candidate;
      }
    }
    throw StateError(
      'SlugGenerator: failed to find a unique slug after $maxAttempts attempts.',
    );
  }
}
