import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pdf_page_model.dart';

/// Converts an ordered list of pages into a single PDF, and offers
/// save-to-device / share, per PRD section 3.2 ("Convert to PDF").
class PdfService {
  static const int _maxPages = 50;
  static const int _maxImageBytes = 15 * 1024 * 1024;
  static const int _maxTotalInputBytes = 50 * 1024 * 1024;
  static const int _maxImageDimension = 1800;

  Future<File> generatePdf(List<PdfPageModel> pages, {String? fileName}) async {
    if (pages.isEmpty || pages.length > _maxPages) {
      throw ArgumentError('Choose between 1 and $_maxPages images.');
    }

    final doc = pw.Document();
    var totalInputBytes = 0;

    for (final page in pages) {
      final imageSize = await page.imageFile.length();
      if (imageSize == 0 || imageSize > _maxImageBytes) {
        throw ArgumentError(
          'Each image must be at most ${_maxImageBytes ~/ (1024 * 1024)} MB.',
        );
      }
      final bytes = await page.imageFile.readAsBytes();
      totalInputBytes += bytes.length;
      if (bytes.isEmpty || bytes.length > _maxImageBytes) {
        throw ArgumentError(
          'Each image must be at most ${_maxImageBytes ~/ (1024 * 1024)} MB.',
        );
      }
      if (totalInputBytes > _maxTotalInputBytes) {
        throw ArgumentError('The selected images exceed the 50 MB total limit.');
      }

      final compressedBytes = await compute(_optimizeImage, bytes);
      final pdfImage = pw.MemoryImage(compressedBytes);
      doc.addPage(
        pw.Page(
          build: (context) =>
              pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)),
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final requestedName =
        fileName ?? 'EasyPDF_${DateTime.now().microsecondsSinceEpoch}';
    final name = requestedName.replaceFirst(
      RegExp(r'\.pdf$', caseSensitive: false),
      '',
    );
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(name)) {
      throw ArgumentError('The PDF file name contains unsupported characters.');
    }

    final file = File('${dir.path}/$name.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }

  Future<void> shareGeneratedPdf(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Shared via EasyPDF');
  }
}

Uint8List _optimizeImage(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('The selected file is not a supported image.');
  }
  final longestSide =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  final optimized = longestSide > PdfService._maxImageDimension
      ? image.copyResize(
          decoded,
          width: (decoded.width * PdfService._maxImageDimension / longestSide)
              .round(),
          height: (decoded.height * PdfService._maxImageDimension / longestSide)
              .round(),
        )
      : decoded;
  return Uint8List.fromList(image.encodeJpg(optimized, quality: 82));
}
