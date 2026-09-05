import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pdf_page_model.dart';

/// Converts an ordered list of pages into a single PDF, and offers
/// save-to-device / share, per PRD section 3.2 ("Convert to PDF").
class PdfService {
  Future<File> generatePdf(List<PdfPageModel> pages, {String? fileName}) async {
    final doc = pw.Document();

    for (final page in pages) {
      final bytes = await page.imageFile.readAsBytes();
      final image = pw.MemoryImage(bytes);
      doc.addPage(
        pw.Page(
          build: (context) =>
              pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final name = fileName ?? 'EasyPDF_${DateTime.now().millisecondsSinceEpoch}';
    final file = File('${dir.path}/$name.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<void> shareGeneratedPdf(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Shared via EasyPDF');
  }
}
