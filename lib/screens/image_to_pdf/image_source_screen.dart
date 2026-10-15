import 'dart:io';

import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../models/pdf_page_model.dart';
import '../../services/image_processing_service.dart';
import 'preview_pages_screen.dart';

enum InitialImageSource { camera, gallery, galleryScan }

/// Provides camera scanning and gallery selection for a PDF document.
class ImageSourceScreen extends StatefulWidget {
  final InitialImageSource? initialSource;

  const ImageSourceScreen({super.key, this.initialSource});

  @override
  State<ImageSourceScreen> createState() => _ImageSourceScreenState();
}

class _ImageSourceScreenState extends State<ImageSourceScreen> {
  final _imageService = ImageProcessingService();
  final List<PdfPageModel> _pages = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.initialSource) {
        case InitialImageSource.camera:
          _useCamera();
          break;
        case InitialImageSource.gallery:
          _useGallery();
          break;
        case InitialImageSource.galleryScan:
          _useGalleryScanner();
          break;
        case null:
          break;
      }
    });
  }

  Future<void> _useCamera() async {
    setState(() => _busy = true);
    try {
      // Loop lets the user capture multiple pages before finalizing.
      bool addAnother = true;
      while (addAnother) {
        File? scanned;
        try {
          scanned = await _imageService.scanWithCamera();
        } catch (_) {
          scanned = await _imageService.captureWithCamera();
          if (scanned != null && mounted) {
            _showError(
              'Auto scan could not start. The camera photo was added without '
              'document auto-cropping.',
            );
          }
        }
        if (!mounted) return;
        if (scanned == null) break; // user backed out
        final capturedPage = scanned;
        setState(() {
          _pages.add(
            PdfPageModel(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              imageFile: capturedPage,
            ),
          );
        });
        if (_pages.length >= 50) {
          _showError('A PDF can contain up to 50 pages.');
          break;
        }
        if (!mounted) return;
        addAnother = await _askCaptureAnother() ?? false;
        if (!mounted) return;
      }
      if (_pages.isNotEmpty) _goToPreview();
    } catch (error) {
      if (mounted) {
        _showError(
          'Could not open the camera. Check camera permission in system '
          'settings and try again ($error).',
        );
      }
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

  Future<void> _useGalleryScanner() async {
    setState(() => _busy = true);
    try {
      var addAnother = true;
      while (addAnother) {
        final scanned = await _imageService.scanFromGallery();
        if (!mounted || scanned == null) break;
        final capturedPage = scanned;
        setState(() {
          _pages.add(
            PdfPageModel(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              imageFile: capturedPage,
            ),
          );
        });
        if (_pages.length >= 50) {
          _showError('A PDF can contain up to 50 pages.');
          break;
        }
        addAnother = await _askCaptureAnother() ?? false;
      }
      if (mounted && _pages.isNotEmpty) _goToPreview();
    } catch (error) {
      if (mounted) _showError('Gallery auto-crop failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _useGallery() async {
    setState(() => _busy = true);
    try {
      final picked = await _imageService.pickFromGallery();
      if (!mounted) return;
      if (picked.length > 50) {
        _showError('Only the first 50 selected images can be added.');
      }
      for (final file in picked.take(50)) {
        _pages.add(
          PdfPageModel(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            imageFile: file,
            originalFile: file,
          ),
        );
      }
      if (!mounted) return;
      if (_pages.isNotEmpty) _goToPreview();
    } catch (_) {
      if (mounted) {
        _showError('Gallery import failed. Try selecting the images again.');
      }
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
            const SizedBox(height: 16),
            _SourceButton(
              icon: Icons.crop_rounded,
              label: 'Gallery auto-crop',
              subtitle: 'Select and crop a document page',
              onTap: _busy ? null : _useGalleryScanner,
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
