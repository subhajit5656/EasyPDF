import 'dart:io';
import 'package:edge_detection/edge_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles capturing/picking images and running edge-detection auto-crop,
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

    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final success = await EdgeDetection.detectEdge(
        outputPath,
        canUseGallery: false,
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

  /// Lets the user pick one or more images from the gallery. Each picked
  /// image is then passed through auto-crop individually.
  Future<List<File>> pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    return picked.map((x) => File(x.path)).toList();
  }

  /// Runs auto-crop/edge-detection on an already-selected gallery image.
  Future<File> autoCropExistingImage(File source) async {
    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final success = await EdgeDetection.detectEdge(
        outputPath,
        canUseGallery: true,
        androidScanTitle: 'Scan',
        androidCropTitle: 'Crop',
        androidCropBlackWhiteTitle: 'Black White',
        androidCropReset: 'Reset',
      );
      if (success == true) return File(outputPath);
    } catch (_) {
      // fall through to returning the original if cropping fails
    }
    return source;
  }
}
