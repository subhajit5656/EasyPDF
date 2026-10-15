import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:pdf/pdf.dart' as pdf;
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
  static const int _maxOverlaysPerPage = 20;

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
      if (page.overlays.length > _maxOverlaysPerPage) {
        throw ArgumentError(
          'Each page can have at most $_maxOverlaysPerPage edits.',
        );
      }
      final overlays = <pw.Widget>[];
      for (var index = 0; index < page.overlays.length; index++) {
        final overlay = page.overlays[index];
        if (overlay.text case final text?) {
          if (text.length > 120) {
            throw ArgumentError('Each text overlay must be at most 120 characters.');
          }
          overlays.add(
            pw.Positioned(
              left: 24,
              right: 24,
              top: 24 + index * 34,
              child: pw.Text(
                text,
                style: pw.TextStyle(
                  font: _fontFor(overlay.fontFamily),
                  fontSize: 20,
                  color: _pdfColor(overlay.colorValue),
                ),
              ),
            ),
          );
        } else if (overlay.imageFile case final sticker?) {
          final stickerSize = await sticker.length();
          if (stickerSize == 0 || stickerSize > _maxImageBytes) {
            throw ArgumentError(
              'Each added image must be at most '
              '${_maxImageBytes ~/ (1024 * 1024)} MB.',
            );
          }
          final stickerBytes = await sticker.readAsBytes();
          if (stickerBytes.isEmpty || stickerBytes.length > _maxImageBytes) {
            throw ArgumentError(
              'Each added image must be at most '
              '${_maxImageBytes ~/ (1024 * 1024)} MB.',
            );
          }
          totalInputBytes += stickerBytes.length;
          if (totalInputBytes > _maxTotalInputBytes) {
            throw ArgumentError('The selected images exceed the 50 MB total limit.');
          }
          overlays.add(
            pw.Positioned(
              right: 24,
              bottom: 24 + (index % 5) * 46,
              child: pw.Image(
                pw.MemoryImage(await compute(_optimizeImage, stickerBytes)),
                width: 72,
                height: 72,
                fit: pw.BoxFit.contain,
              ),
            ),
          );
        }
      }
      doc.addPage(
        pw.Page(
          build: (context) => pw.Stack(
            fit: pw.StackFit.expand,
            children: [
              pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)),
              ...overlays,
            ],
          ),
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

  pw.Font _fontFor(String family) => switch (family) {
    'Courier' => pw.Font.courier(),
    'Times' => pw.Font.times(),
    _ => pw.Font.helvetica(),
  };

  pdf.PdfColor _pdfColor(int colorValue) => pdf.PdfColor(
    ((colorValue >> 16) & 0xFF) / 255,
    ((colorValue >> 8) & 0xFF) / 255,
    (colorValue & 0xFF) / 255,
  );
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
