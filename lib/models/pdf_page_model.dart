import 'dart:io';

/// Represents a single scanned/selected page before final PDF conversion.
class PdfPageModel {
  final String id;
  File imageFile; // cropped/scanned version shown in preview
  File? originalFile; // pre-crop original, kept for re-crop
  final List<PdfPageOverlay> overlays;

  PdfPageModel({
    required this.id,
    required this.imageFile,
    this.originalFile,
    List<PdfPageOverlay>? overlays,
  }) : overlays = overlays ?? [];
}

class PdfPageOverlay {
  final String? text;
  final File? imageFile;
  final String fontFamily;
  final int colorValue;

  const PdfPageOverlay({
    this.text,
    this.imageFile,
    this.fontFamily = 'Helvetica',
    this.colorValue = 0xFF212121,
  }) : assert(text != null || imageFile != null);
}
