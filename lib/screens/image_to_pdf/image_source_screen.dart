import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../models/pdf_page_model.dart';
import '../../services/image_processing_service.dart';
import 'preview_pages_screen.dart';

/// PRD 3.2: tapping "Image to PDF" opens Camera or Gallery options, each
/// piped through auto crop/scan before landing on the Preview screen.
class ImageSourceScreen extends StatefulWidget {
  const ImageSourceScreen({super.key});

  @override
  State<ImageSourceScreen> createState() => _ImageSourceScreenState();
}

class _ImageSourceScreenState extends State<ImageSourceScreen> {
  final _imageService = ImageProcessingService();
  final List<PdfPageModel> _pages = [];
  bool _busy = false;

  Future<void> _useCamera() async {
    setState(() => _busy = true);
    try {
      // Loop lets the user capture multiple pages before finalizing.
      bool addAnother = true;
      while (addAnother) {
        final scanned = await _imageService.scanWithCamera();
        if (scanned == null) break; // user backed out
        setState(() {
          _pages.add(
            PdfPageModel(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              imageFile: scanned,
            ),
          );
        });
        if (!mounted) return;
        addAnother = await _askCaptureAnother() ?? false;
      }
      if (_pages.isNotEmpty) _goToPreview();
    } catch (e) {
      _showError('Camera scan failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _askCaptureAnother() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add another page?'),
        content: const Text('Scan another page for this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Scan Another'),
          ),
        ],
      ),
    );
  }

  Future<void> _useGallery() async {
    setState(() => _busy = true);
    try {
      final picked = await _imageService.pickFromGallery();
      for (final file in picked) {
        final cropped = await _imageService.autoCropExistingImage(file);
        _pages.add(
          PdfPageModel(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            imageFile: cropped,
            originalFile: file,
          ),
        );
      }
      if (_pages.isNotEmpty) _goToPreview();
    } catch (e) {
      _showError('Gallery import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goToPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewPagesScreen(initialPages: List.of(_pages)),
      ),
    );
    _pages.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image to PDF')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SourceButton(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              subtitle: 'Scan pages with auto crop',
              onTap: _busy ? null : _useCamera,
            ),
            const SizedBox(height: 20),
            _SourceButton(
              icon: Icons.photo_library_rounded,
              label: 'Gallery',
              subtitle: 'Pick one or more images',
              onTap: _busy ? null : _useGallery,
            ),
            if (_busy) ...[
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
