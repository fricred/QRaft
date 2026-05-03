import 'package:csv/csv.dart';

/// Thrown by [QrBulkImportService.parseCsv] when the input violates a
/// hard constraint.
///
/// [code] values:
///  - `'file_too_large'` — raw content exceeds 1MB
///  - `'too_many_rows'`  — valid (non-empty) data rows exceed 500
class QrBulkImportException implements Exception {
  final String code;
  const QrBulkImportException(this.code);

  @override
  String toString() => 'QrBulkImportException($code)';
}

/// A single parsed row from a bulk CSV import.
class BulkQrRow {
  final String name;
  final String type;
  final String content;

  const BulkQrRow({
    required this.name,
    required this.type,
    required this.content,
  });
}

/// Service for parsing semicolon-delimited CSV files for bulk QR code creation.
///
/// ## CSV Format
/// ```
/// name;type;content
/// My QR;url;https://example.com
/// Business;vcard;BEGIN:VCARD...
/// ```
/// Columns: `name` (required), `type` (optional, normalised to lowercase),
/// `content` (required).
///
/// ## Constraints
/// - File size cap: 1MB (checked on raw string length before parsing)
/// - Row count cap: 500 valid (non-empty) data rows
/// - Rows with empty name OR empty content are silently skipped
///
/// ## Threat mitigations
/// - T-05-05-02: 1MB size check before CsvCodec runs (DoS via oversized file)
/// - T-05-05-03: 500-row hard cap (DoS via too many rows)
class QrBulkImportService {
  QrBulkImportService._();

  static const int _maxBytes = 1024 * 1024; // 1 MB
  static const int _maxRows = 500;
  // autoDetect: false ensures the semicolon delimiter is always respected
  // (the Csv constructor passes fieldDelimiter to the decoder only when
  // autoDetect is false — see csv 8.0.0 source).
  static final Csv _codec = Csv(fieldDelimiter: ';', autoDetect: false);

  /// Parses [raw] CSV content (semicolon-delimited) and returns a list of
  /// [BulkQrRow] objects.
  ///
  /// Throws [QrBulkImportException('file_too_large')] if [raw.length] > 1MB.
  /// Throws [QrBulkImportException('too_many_rows')] if valid data rows > 500.
  static List<BulkQrRow> parseCsv(String raw) {
    // T-05-05-02: size cap — check before parsing to prevent CPU abuse
    if (raw.length > _maxBytes) throw const QrBulkImportException('file_too_large');

    final allRows = _codec.decoder.convert(raw);
    if (allRows.isEmpty) return [];

    // Skip header row (index 0); all subsequent rows are data rows
    final dataRows = allRows.skip(1).toList();

    // Count only valid (non-empty name + content) rows for the cap
    final validCount = dataRows.where((r) {
      if (r.length < 3) return false;
      final name = r[0].toString().trim();
      final content = r[2].toString().trim();
      return name.isNotEmpty && content.isNotEmpty;
    }).length;

    // T-05-05-03: row count cap
    if (validCount > _maxRows) throw const QrBulkImportException('too_many_rows');

    return dataRows
        .where((r) => r.length >= 3)
        .map((r) => BulkQrRow(
              name: r[0].toString().trim(),
              type: r[1].toString().trim().toLowerCase(),
              content: r[2].toString().trim(),
            ))
        .where((row) => row.name.isNotEmpty && row.content.isNotEmpty)
        .toList();
  }
}
