import 'package:flutter/material.dart';

import '../../domain/services/qr_bulk_import_service.dart';
import '../controllers/qr_customization_controller.dart';

/// A bottom sheet for importing QR codes in bulk from CSV content.
///
/// ## Usage
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => QrBulkImportSheet(
///     defaultTemplate: kQrTemplates.first,
///     onImportConfirmed: (rows) { /* handle */ },
///   ),
/// );
/// ```
///
/// ## CSV Format
/// Semicolon-delimited, one header row, then data rows:
/// ```
/// name;type;content
/// My Website;url;https://example.com
/// ```
///
/// TODO(Phase 5 enhancement): Replace the CSV paste text field with a file
/// picker using the `file_picker` package once it is added to pubspec.yaml.
/// Add `file_picker: ^8.0.0` to dependencies, then replace the TextField
/// with `FilePicker.platform.pickFiles(type: FileType.custom,
/// allowedExtensions: ['csv'])` and read the file bytes.
class QrBulkImportSheet extends StatefulWidget {
  /// Called with the parsed rows when the user taps "Generate N QRs".
  final ValueChanged<List<BulkQrRow>> onImportConfirmed;

  /// The template to be applied to all bulk-imported QR codes.
  final QrFullTemplate defaultTemplate;

  const QrBulkImportSheet({
    super.key,
    required this.onImportConfirmed,
    required this.defaultTemplate,
  });

  @override
  State<QrBulkImportSheet> createState() => _QrBulkImportSheetState();
}

class _QrBulkImportSheetState extends State<QrBulkImportSheet> {
  final TextEditingController _csvController = TextEditingController();

  /// Parsed rows ready to import (null = not yet parsed / parse failed).
  List<BulkQrRow>? _parsedRows;

  /// Human-readable error from the last parse attempt.
  String? _parseError;

  /// Whether the import is currently processing.
  bool _isImporting = false;

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _onCsvChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _parsedRows = null;
        _parseError = null;
      });
      return;
    }

    try {
      final rows = QrBulkImportService.parseCsv(value);
      setState(() {
        _parsedRows = rows;
        _parseError = null;
      });
    } on QrBulkImportException catch (e) {
      setState(() {
        _parsedRows = null;
        _parseError = _friendlyError(e.code);
      });
    } catch (_) {
      setState(() {
        _parsedRows = null;
        _parseError = 'Invalid CSV format. Check your data and try again.';
      });
    }
  }

  String _friendlyError(String code) => switch (code) {
        'too_many_rows' => 'Maximum 500 QR codes per import.',
        'file_too_large' => 'File must be under 1 MB.',
        _ => 'Import error: $code',
      };

  void _onConfirm() {
    final rows = _parsedRows;
    if (rows == null || rows.isEmpty) return;

    setState(() => _isImporting = true);

    widget.onImportConfirmed(rows);
    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rowCount = _parsedRows?.length ?? 0;
    final hasRows = rowCount > 0;

    return Semantics(
      identifier: 'qr_bulk_import_sheet',
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Import from CSV',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Semicolon-separated (;) format — name;type;content',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 16),

              // CSV input field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _csvController,
                  onChanged: _onCsvChanged,
                  maxLines: 6,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    hintText:
                        'name;type;content\nMy Website;url;https://example.com\nBusiness Card;vcard;BEGIN:VCARD...',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 11),
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Row count preview or error
              if (_parseError != null)
                _ErrorCard(message: _parseError!)
              else if (hasRows)
                _RowCountPreview(count: rowCount),

              const SizedBox(height: 16),

              // Confirm button
              ElevatedButton(
                onPressed: hasRows && !_isImporting ? _onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasRows
                      ? const Color(0xFF00FF88)
                      : const Color(0xFF2E2E2E),
                  foregroundColor:
                      hasRows ? const Color(0xFF1A1A1A) : Colors.white38,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isImporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1A1A1A),
                        ),
                      )
                    : Text(
                        hasRows ? 'Generate $rowCount QRs' : 'Choose CSV content',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _RowCountPreview extends StatelessWidget {
  final int count;

  const _RowCountPreview({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF00FF88), size: 16),
          const SizedBox(width: 8),
          Text(
            'Found $count QR${count == 1 ? '' : 's'} ready to import',
            style: const TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
