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

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openImageWorkflow(source: InitialImageSource.camera);
                },
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text("Scan with camera"),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openImageWorkflow(source: InitialImageSource.gallery);
                },
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text("Choose from gallery"),
              ),
            ],
          ),
        );
      },
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Welcome back, $userName',
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user?.email ?? 'Your documents, ready when you are.',
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildCreateCard(),
            const SizedBox(height: 28),
            const Text(
              'How it works',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildWorkflow(),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent PDFs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Your PDF files stay on this device; only document details sync.',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            _buildRecentDocuments(),
            const SizedBox(height: 20),
            _buildComingSoon(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            size: 38,
            color: Colors.white,
          ),
          const SizedBox(height: 14),
          const Text(
            'Create a PDF',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Scan pages or pick photos. Reorder them, then save and share.',
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _showImagePickerSheet,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Start scanning'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryRed,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    _openImageWorkflow(source: InitialImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose photos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflow() {
    const steps = [
      (Icons.camera_alt_outlined, 'Capture or select'),
      (Icons.swap_vert_rounded, 'Arrange your pages'),
      (Icons.share_outlined, 'Save or share'),
    ];
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            for (var index = 0; index < steps.length; index++) ...[
              Expanded(
                child: Column(
                  children: [
                    Icon(steps[index].$1, color: AppTheme.primaryRed),
                    const SizedBox(height: 8),
                    Text(
                      steps[index].$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textGrey,
                ),
            ],
          ],
        ),
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
      return const Card(
        elevation: 0,
        child: ListTile(
          leading: Icon(Icons.description_outlined, color: AppTheme.textGrey),
          title: Text('No PDFs yet'),
          subtitle: Text('Your recent document details will appear here.'),
        ),
      );
    }
    return Card(
      elevation: 0,
      child: Column(
        children: [
          for (var index = 0; index < _documents!.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.accentRed,
                child: Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryRed),
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
              trailing: IconButton(
                tooltip: 'Remove from history',
                onPressed: () => _removeFromHistory(_documents![index]),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildComingSoon() {
    return const Card(
      elevation: 0,
      color: Color(0xFFEBEFF2),
      child: ListTile(
        leading: Icon(Icons.auto_awesome_outlined, color: AppTheme.textGrey),
        title: Text('More PDF tools'),
        subtitle: Text('PDF conversion, merge, and text extraction are planned.'),
        trailing: Icon(Icons.lock_outline_rounded, color: AppTheme.textGrey),
      ),
    );
  }
}
