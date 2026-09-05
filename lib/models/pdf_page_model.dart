import 'dart:io';

/// Represents a single scanned/selected page before final PDF conversion.
class PdfPageModel {
  final String id;
  File imageFile; // cropped/scanned version shown in preview
  File? originalFile; // pre-crop original, kept for re-crop

  PdfPageModel({required this.id, required this.imageFile, this.originalFile});
}
