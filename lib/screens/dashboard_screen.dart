import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/recent_document.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'image_to_pdf/image_source_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  List<RecentDocument>? _documents;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _refreshDocuments();
  }

  Future<void> _refreshDocuments() async {
    try {
      final documents = await _apiService.getRecentDocuments();
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _historyError = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _documents = const [];
        _historyError = error.message;
      });
    }
  }

  Future<void> _removeFromHistory(RecentDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from history?'),
        content: Text(
          '${document.fileName} will be removed from your account history. '
          'The PDF file on this device will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _apiService.deleteDocument(document.id);
      await _refreshDocuments();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openImageWorkflow({InitialImageSource? source}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageSourceScreen(initialSource: source),
      ),
    );
    if (mounted) _refreshDocuments();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final userName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'EasyPDF User';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('EasyPDF'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textDark),
            onPressed: () async {
              await AuthService.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDocuments,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR WORKSPACE',
                        style: TextStyle(
                          color: AppTheme.primaryRed,
                          fontSize: 11,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Hi, $userName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.primaryRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Scan, arrange, and share your documents.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 22),
            _buildCreateCard(),
            const SizedBox(height: 26),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent documents',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh history',
                  onPressed: _refreshDocuments,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10, top: 2),
              child: Text(
                'Files stay on this device; only document details sync.',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            _buildRecentDocuments(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'DOCUMENT STUDIO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Paperwork,\nmade simple.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 27,
                        height: 1.08,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.document_scanner_rounded,
                size: 62,
                color: Color(0x66FFFFFF),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Capture pages, fine-tune your document, then save or share.',
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _openImageWorkflow(source: InitialImageSource.camera),
                  icon: const Icon(Icons.document_scanner_rounded, size: 18),
                  label: const Text('Scan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _openImageWorkflow(source: InitialImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Import photos'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openImageWorkflow(
                source: InitialImageSource.galleryScan,
              ),
              icon: const Icon(Icons.crop_rounded, size: 18),
              label: const Text('Auto-crop a gallery photo'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDocuments() {
    if (_documents == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_historyError != null) {
      return Card(
        elevation: 0,
        child: ListTile(
          leading: const Icon(Icons.cloud_off_rounded, color: AppTheme.textGrey),
          title: const Text('History is unavailable'),
          subtitle: Text(_historyError!),
          trailing: IconButton(
            tooltip: 'Retry',
            onPressed: _refreshDocuments,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      );
    }
    if (_documents!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEDEFF2)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 36,
              color: AppTheme.primaryRed,
            ),
            SizedBox(height: 9),
            Text(
              'No PDFs yet',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Your recent document details will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < _documents!.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Container(
                width: 44,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accentRed,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppTheme.primaryRed,
                ),
              ),
              title: Text(
                _documents![index].fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${_documents![index].pageCount} pages · '
                '${_formatDate(_documents![index].createdAt)}',
              ),
              trailing: PopupMenuButton<String>(
                tooltip: 'Document options',
                onSelected: (value) {
                  if (value == 'remove') {
                    _removeFromHistory(_documents![index]);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove from history'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

}
