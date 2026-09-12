import 'dart:async';

import 'package:azimutree/data/models/app_version_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads application release notes and version metadata from Firestore.
class AppVersionService {
  AppVersionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<AppVersionModel>> getPublishedVersions() async {
    final snapshot = await _firestore
        .collection('appVersions')
        .where('isPublished', isEqualTo: true)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 10));
    final versions = snapshot.docs.map(AppVersionModel.fromFirestore).toList();
    versions.sort((a, b) {
      final dateComparison = (b.publishedAt ?? DateTime(0)).compareTo(
        a.publishedAt ?? DateTime(0),
      );
      return dateComparison != 0
          ? dateComparison
          : b.version.compareTo(a.version);
    });
    return versions;
  }
}
