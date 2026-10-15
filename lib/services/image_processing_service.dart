import 'dart:io';
import 'package:edge_detection/edge_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles capturing/scanning and selecting page images,
/// per PRD section 3.2 ("Auto Crop & Scan").
///
/// NOTE: `edge_detection` opens its own native scanner camera UI (with
/// built-in crop) on both platforms, which is why capture + crop are
/// combined into a single call below. If you swap in a different scanner
/// package, split this into "capture" then "crop" steps instead.
class ImageProcessingService {
  /// Launches the native document scanner (camera) and returns the
  /// auto-cropped scan, or null if the user cancelled.
  Future<File?> scanWithCamera() async {
    final cameraGranted = await Permission.camera.request();
    if (!cameraGranted.isGranted) {
      throw Exception('Camera permission denied');
    }

    return _runDocumentScanner(canUseGallery: false);
  }

  /// Opens the native scanner with its gallery-selection option enabled.
  Future<File?> scanFromGallery() => _runDocumentScanner(canUseGallery: true);

  /// Captures a photo with the platform camera if the document scanner fails.
  Future<File?> captureWithCamera() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2200,
      maxHeight: 2200,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    return picked == null ? null : File(picked.path);
  }

  Future<File?> _runDocumentScanner({required bool canUseGallery}) async {
    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final success = await EdgeDetection.detectEdge(
        outputPath,
        canUseGallery: canUseGallery,
        androidScanTitle: 'Scan Document',
        androidCropTitle: 'Crop',
        androidCropBlackWhiteTitle: 'Black White',
        androidCropReset: 'Reset',
      );
      if (success != true) return null;
      return File(outputPath);
    } catch (e) {
      throw Exception('Edge detection failed: $e');
    }
  }

  /// Lets the user pick one or more images from the gallery.
  Future<List<File>> pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      maxWidth: 2200,
      maxHeight: 2200,
      imageQuality: 85,
      limit: 50,
      requestFullMetadata: false,
    );
    return picked.map((x) => File(x.path)).toList();
  }

  /// Lets the user replace a page with a specific gallery image.
  Future<File?> pickReplacementImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2200,
      maxHeight: 2200,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    return picked == null ? null : File(picked.path);
  }
}
