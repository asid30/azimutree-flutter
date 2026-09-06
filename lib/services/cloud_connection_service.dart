import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class CloudConnectionResult {
  final bool isConnected;
  final String message;

  const CloudConnectionResult({
    required this.isConnected,
    required this.message,
  });
}

class CloudConnectionService {
  CloudConnectionService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  Future<CloudConnectionResult> checkConnection() async {
    if (Firebase.apps.isEmpty) {
      return const CloudConnectionResult(
        isConnected: false,
        message: 'Firebase belum berhasil diinisialisasi.',
      );
    }

    try {
      final snapshot = await (_firestore ?? FirebaseFirestore.instance)
          .collection('system')
          .doc('status')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));

      if (!snapshot.exists) {
        return const CloudConnectionResult(
          isConnected: false,
          message:
              'Dokumen status layanan belum tersedia di Firebase. Buat dokumen system/status terlebih dahulu.',
        );
      }

      final data = snapshot.data();
      if (data?['cloudEnabled'] != true) {
        final serverMessage = data?['message'];
        return CloudConnectionResult(
          isConnected: false,
          message:
              serverMessage is String && serverMessage.trim().isNotEmpty
                  ? serverMessage
                  : 'Layanan penyimpanan awan sedang dinonaktifkan.',
        );
      }

      final serverMessage = data?['message'];
      return CloudConnectionResult(
        isConnected: true,
        message:
            serverMessage is String && serverMessage.trim().isNotEmpty
                ? serverMessage
                : 'Aplikasi berhasil terhubung ke layanan penyimpanan awan.',
      );
    } on TimeoutException {
      return const CloudConnectionResult(
        isConnected: false,
        message:
            'Waktu koneksi habis. Periksa jaringan internet lalu coba kembali.',
      );
    } on FirebaseException catch (error) {
      return CloudConnectionResult(
        isConnected: false,
        message: _firebaseErrorMessage(error),
      );
    } catch (_) {
      return const CloudConnectionResult(
        isConnected: false,
        message:
            'Tidak dapat terhubung ke layanan penyimpanan awan. Silakan coba kembali.',
      );
    }
  }

  String _firebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Akses ke status layanan ditolak. Periksa Firestore Security Rules.';
      case 'unavailable':
        return 'Layanan Firebase tidak tersedia atau perangkat sedang offline.';
      case 'failed-precondition':
        return 'Cloud Firestore belum dibuat atau belum siap digunakan.';
      default:
        return 'Koneksi Firebase gagal (${error.code}). Silakan coba kembali.';
    }
  }
}
