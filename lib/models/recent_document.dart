class RecentDocument {
  final String id;
  final String fileName;
  final int pageCount;
  final int fileSizeBytes;
  final DateTime createdAt;

  const RecentDocument({
    required this.id,
    required this.fileName,
    required this.pageCount,
    required this.fileSizeBytes,
    required this.createdAt,
  });

  factory RecentDocument.fromJson(Map<String, dynamic> json) {
    return RecentDocument(
      id: json['id'] as String,
      fileName: json['file_name'] as String,
      pageCount: json['page_count'] as int,
      fileSizeBytes: json['file_size_bytes'] as int,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
