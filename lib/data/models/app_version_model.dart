import 'package:cloud_firestore/cloud_firestore.dart';

class AppVersionModel {
  const AppVersionModel({
    required this.version,
    required this.title,
    required this.changes,
    this.publishedAt,
  });

  final String version;
  final String title;
  final List<String> changes;
  final DateTime? publishedAt;

  factory AppVersionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final rawChanges = data['changes'];
    final changes =
        rawChanges is List
            ? rawChanges
                .whereType<String>()
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList()
            : rawChanges is String
            ? rawChanges
                .split('\n')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList()
            : <String>[];
    final timestamp = data['publishedAt'];

    return AppVersionModel(
      version:
          (data['version'] as String?)?.trim().isNotEmpty == true
              ? (data['version'] as String).trim()
              : document.id,
      title: (data['title'] as String?)?.trim() ?? '',
      changes: changes,
      publishedAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
