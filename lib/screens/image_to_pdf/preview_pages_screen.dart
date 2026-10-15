import 'dart:io';

import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/pdf_page_model.dart';
import '../../services/api_service.dart';
import '../../services/image_processing_service.dart';
import '../../services/pdf_service.dart';

/// PRD 3.2 Post-Selection Flow: preview all pages, reorder/delete/replace,
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
  final _apiService = ApiService();
  bool _converting = false;
  bool _replacing = false;

  @override
  void initState() {
    super.initState();
    _pages = widget.initialPages;
  }

  void _reorder(int oldIndex, int newIndex) {
    if (_converting || _replacing) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, item);
    });
  }

  void _delete(int index) {
    if (_converting || _replacing) return;
    setState(() => _pages.removeAt(index));
  }

  Future<void> _replacePage(int index) async {
    setState(() => _replacing = true);
    try {
      final replacement = await _imageService.pickReplacementImage();
      if (replacement == null || !mounted) return;
      setState(() {
        _pages[index].imageFile = replacement;
        _pages[index].originalFile = replacement;
      });
    } catch (error) {
      if (mounted) _showMessage('Could not replace the image: $error');
    } finally {
      if (mounted) setState(() => _replacing = false);
    }
  }

  Future<void> _editPage(int index) async {
    final page = _pages[index];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit page ${index + 1}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add text, simple symbols, or an image overlay to this page.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: page.overlays.length >= 20
                            ? null
                            : () async {
                                final overlay = await _promptTextOverlay();
                                if (overlay == null ||
                                    !mounted ||
                                    !sheetContext.mounted) {
                                  return;
                                }
                                setState(() => page.overlays.add(overlay));
                                setSheetState(() {});
                              },
                        icon: const Icon(Icons.text_fields_rounded),
                        label: const Text('Add text'),
                      ),
                      OutlinedButton.icon(
                        onPressed: page.overlays.length >= 20
                            ? null
                            : () async {
                                final overlay = await _promptSymbolOverlay();
                                if (overlay == null ||
                                    !mounted ||
                                    !sheetContext.mounted) {
                                  return;
                                }
                                setState(() => page.overlays.add(overlay));
                                setSheetState(() {});
                              },
                        icon: const Icon(Icons.tag_rounded),
                        label: const Text('Add symbol'),
                      ),
                      OutlinedButton.icon(
                        onPressed: page.overlays.length >= 20
                            ? null
                            : () async {
                                try {
                                  final file = await _imageService
                                      .pickReplacementImage();
                                  if (file == null ||
                                      !mounted ||
                                      !sheetContext.mounted) {
                                    return;
                                  }
                                  setState(
                                    () => page.overlays.add(
                                      PdfPageOverlay(imageFile: file),
                                    ),
                                  );
                                  setSheetState(() {});
                                } catch (error) {
                                  if (mounted) {
                                    _showMessage(
                                      'Could not add the image: $error',
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Add image'),
                      ),
                    ],
                  ),
                  if (page.overlays.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (var overlayIndex = 0;
                        overlayIndex < page.overlays.length;
                        overlayIndex++)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          page.overlays[overlayIndex].imageFile == null
                              ? Icons.text_fields_rounded
                              : Icons.image_outlined,
                        ),
                        title: Text(
                          page.overlays[overlayIndex].text ??
                              'Image overlay',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: page.overlays[overlayIndex].text == null
                            ? null
                            : Text(page.overlays[overlayIndex].fontFamily),
                        trailing: IconButton(
                          tooltip: 'Remove overlay',
                          onPressed: () {
                            setState(
                              () => page.overlays.removeAt(overlayIndex),
                            );
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<PdfPageOverlay?> _promptTextOverlay() async {
    final controller = TextEditingController();
    var fontFamily = 'Helvetica';
    var colorValue = 0xFF212121;
    const colors = {
      'Black': 0xFF212121,
      'Red': 0xFFE53935,
      'Blue': 0xFF1565C0,
      'Green': 0xFF2E7D32,
    };
    final overlay = await showDialog<PdfPageOverlay>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add text'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  hintText: 'Type a note or label',
                ),
              ),
              DropdownButtonFormField<String>(
                value: fontFamily,
                decoration: const InputDecoration(labelText: 'Font'),
                items: const [
                  DropdownMenuItem(value: 'Helvetica', child: Text('Helvetica')),
                  DropdownMenuItem(value: 'Times', child: Text('Times')),
                  DropdownMenuItem(value: 'Courier', child: Text('Courier')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => fontFamily = value);
                },
              ),
              DropdownButtonFormField<int>(
                value: colorValue,
                decoration: const InputDecoration(labelText: 'Color'),
                items: [
                  for (final entry in colors.entries)
                    DropdownMenuItem(
                      value: entry.value,
                      child: Text(entry.key),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => colorValue = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  PdfPageOverlay(
                    text: text,
                    fontFamily: fontFamily,
                    colorValue: colorValue,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return overlay;
  }

  Future<PdfPageOverlay?> _promptSymbolOverlay() {
    const symbols = ['*', '+', '#', '@', '!'];
    return showDialog<PdfPageOverlay>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add a symbol'),
        content: Wrap(
          spacing: 8,
          children: [
            for (final symbol in symbols)
              ActionChip(
                label: Text(
                  symbol,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => Navigator.pop(
                  dialogContext,
                  PdfPageOverlay(text: symbol, fontFamily: 'Helvetica'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _convertAndFinish() async {
    if (_pages.isEmpty || _converting) return;
    setState(() => _converting = true);
    try {
      final pageCount = _pages.length;
      final pdf = await _pdfService.generatePdf(_pages);
      if (!mounted) return;
      var historyWarning = '';
      try {
        await _apiService.recordDocument(
          fileName: pdf.uri.pathSegments.last,
          pageCount: pageCount,
          fileSizeBytes: await pdf.length(),
        );
      } on ApiException catch (error) {
        historyWarning = error.message;
      }
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _ResultSheet(
          file: pdf,
          historyWarning: historyWarning,
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
                    subtitle: page.overlays.isEmpty
                        ? null
                        : Text('${page.overlays.length} edit(s)'),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Page options',
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editPage(index);
                            break;
                          case 'replace':
                            _replacePage(index);
                            break;
                          case 'delete':
                            _delete(index);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit page')),
                        PopupMenuItem(
                          value: 'replace',
                          child: Text('Replace image'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete page'),
                        ),
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
            onPressed: (_pages.isEmpty || _converting || _replacing)
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
  final String historyWarning;
  final VoidCallback onShare;
  const _ResultSheet({
    required this.file,
    required this.historyWarning,
    required this.onShare,
  });

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
            'PDF saved on this device',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            file.path.split('/').last,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (historyWarning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'PDF is saved locally, but recent history could not sync: $historyWarning',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'The PDF stays on this device. Only its name, size, and page count are synced.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
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
