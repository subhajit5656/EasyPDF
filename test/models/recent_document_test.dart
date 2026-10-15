import 'package:flutter_test/flutter_test.dart';
import 'package:easypdf/models/recent_document.dart';

void main() {
  test('parses document history returned by the API', () {
    final document = RecentDocument.fromJson({
      'id': '7e47f6df-1d1f-44df-8774-110a4bb6faed',
      'file_name': 'scan.pdf',
      'page_count': 3,
      'file_size_bytes': 4096,
      'created_at': '2025-01-01T00:00:00Z',
    });

    expect(document.id, '7e47f6df-1d1f-44df-8774-110a4bb6faed');
    expect(document.fileName, 'scan.pdf');
    expect(document.pageCount, 3);
    expect(document.fileSizeBytes, 4096);
    expect(document.createdAt.isUtc, isFalse);
  });
}
