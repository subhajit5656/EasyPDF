import 'dart:io';
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../models/pdf_page_model.dart';
import '../../services/image_processing_service.dart';
import '../../services/pdf_service.dart';

/// PRD 3.2 Post-Selection Flow: preview all pages, reorder/delete/re-crop,
/// then "Convert to PDF" → Save / Share.
class PreviewPagesScreen extends StatefulWidget {
  final List<PdfPageModel> initialPages;
  const PreviewPagesScreen({super.key, required this.initialPages});

  @override
  State<PreviewPagesScreen> createState() => _PreviewPagesScreenState();
}

class _PreviewPagesScreenState extends State<PreviewPagesScreen> {
  late List<PdfPageModel> _pages;
  final _pdfService = PdfService();
  final _imageService = ImageProcessingService();
  bool _converting = false;

  @override
  void initState() {
    super.initState();
    _pages = widget.initialPages;
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, item);
    });
  }

  void _delete(int index) {
    setState(() => _pages.removeAt(index));
  }

  Future<void> _recrop(int index) async {
    final source = _pages[index].originalFile ?? _pages[index].imageFile;
    final recropped = await _imageService.autoCropExistingImage(source);
    setState(() {
      _pages[index].imageFile = recropped;
    });
  }

  Future<void> _convertAndFinish() async {
    if (_pages.isEmpty) return;
    setState(() => _converting = true);
    try {
      final pdf = await _pdfService.generatePdf(_pages);
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _ResultSheet(
          file: pdf,
          onShare: () => _pdfService.shareGeneratedPdf(pdf),
        ),
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Conversion failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _converting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Preview (${_pages.length})')),
      body: _pages.isEmpty
          ? const Center(child: Text('No pages yet'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pages.length,
              onReorder: _reorder,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Card(
                  key: ValueKey(page.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(page.imageFile.path),
                        width: 56,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text('Page ${index + 1}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.crop_rounded),
                          tooltip: 'Re-crop',
                          onPressed: () => _recrop(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          tooltip: 'Delete',
                          onPressed: () => _delete(index),
                        ),
                        const Icon(Icons.drag_handle_rounded),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: (_pages.isEmpty || _converting)
                ? null
                : _convertAndFinish,
            child: _converting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Convert to PDF'),
          ),
        ),
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  final File file;
  final VoidCallback onShare;
  const _ResultSheet({required this.file, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          const Text(
            'PDF saved to device',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            file.path.split('/').last,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              onShare();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share PDF'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
