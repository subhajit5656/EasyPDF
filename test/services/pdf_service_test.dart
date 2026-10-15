import 'dart:io';

import 'package:easypdf/models/pdf_page_model.dart';
import 'package:easypdf/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = PdfService();

  test('rejects an empty document', () async {
    await expectLater(
      service.generatePdf(const <PdfPageModel>[]),
      throwsArgumentError,
    );
  });

  test('rejects more than 50 pages before reading files', () async {
    final pages = List.generate(
      51,
      (index) => PdfPageModel(
        id: '$index',
        imageFile: File('/does-not-exist-$index.jpg'),
      ),
    );

    await expectLater(
      service.generatePdf(pages),
      throwsArgumentError,
    );
  });
}
