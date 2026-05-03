import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/qr_generator/domain/services/qr_bulk_import_service.dart';

void main() {
  group('QrBulkImportService.parseCsv', () {
    // Helper: build a CSV string with a header + N data rows
    String _buildCsv(int dataRowCount) {
      final buf = StringBuffer('name;type;content\n');
      for (var i = 1; i <= dataRowCount; i++) {
        buf.writeln('Row$i;url;https://example.com/$i');
      }
      return buf.toString();
    }

    test('parses valid 3-row CSV with semicolon separator', () {
      const csv = 'name;type;content\n'
          'QR One;url;https://example.com/1\n'
          'QR Two;text;Hello World\n'
          'QR Three;email;test@example.com\n';

      final rows = QrBulkImportService.parseCsv(csv);

      expect(rows.length, 3);
      expect(rows[0].name, 'QR One');
      expect(rows[0].type, 'url');
      expect(rows[0].content, 'https://example.com/1');
      expect(rows[1].name, 'QR Two');
      expect(rows[2].name, 'QR Three');
    });

    test('parses quoted field with inner semicolon correctly', () {
      // The URL contains a semicolon inside a quoted field — must not split on it
      const csv =
          'name;type;content\n'
          '"Visit Page";url;"https://example.com?a=1;b=2"\n';

      final rows = QrBulkImportService.parseCsv(csv);

      expect(rows.length, 1);
      expect(rows[0].content, 'https://example.com?a=1;b=2');
    });

    test('throws too_many_rows when 501 data rows are provided', () {
      final csv = _buildCsv(501);

      expect(
        () => QrBulkImportService.parseCsv(csv),
        throwsA(
          isA<QrBulkImportException>()
              .having((e) => e.code, 'code', 'too_many_rows'),
        ),
      );
    });

    test('throws file_too_large when raw length exceeds 1MB', () {
      // Build a string just over 1MB
      final largeContent = 'A' * (1024 * 1024 + 1);

      expect(
        () => QrBulkImportService.parseCsv(largeContent),
        throwsA(
          isA<QrBulkImportException>()
              .having((e) => e.code, 'code', 'file_too_large'),
        ),
      );
    });

    test('skips rows where content is empty string', () {
      const csv = 'name;type;content\n'
          'Good Row;url;https://example.com\n'
          'Bad Row;url;\n'; // empty content

      final rows = QrBulkImportService.parseCsv(csv);

      expect(rows.length, 1);
      expect(rows[0].name, 'Good Row');
    });

    test('skips rows where name is empty string', () {
      const csv = 'name;type;content\n'
          ';url;https://example.com\n' // empty name
          'Good;url;https://qraft.co\n';

      final rows = QrBulkImportService.parseCsv(csv);

      expect(rows.length, 1);
      expect(rows[0].name, 'Good');
    });

    test('normalizes type field to lowercase', () {
      const csv = 'name;type;content\n'
          'My QR;URL;https://example.com\n';

      final rows = QrBulkImportService.parseCsv(csv);

      expect(rows.length, 1);
      expect(rows[0].type, 'url');
    });
  });
}
