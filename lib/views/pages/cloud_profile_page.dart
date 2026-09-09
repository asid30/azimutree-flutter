import 'dart:async';

import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/services/cloud_account_deletion_service.dart';
import 'package:azimutree/services/cloud_auth_service.dart';
import 'package:azimutree/services/cloud_user_profile_service.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_confirmation_widget.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/app_alert_service.dart';
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CloudProfilePage extends StatefulWidget {
  const CloudProfilePage({super.key});

  @override
  State<CloudProfilePage> createState() => _CloudProfilePageState();
}

class _CloudProfilePageState extends State<CloudProfilePage> {
  final _authService = CloudAuthService();
  final _profileService = CloudUserProfileService();
  final _deletionService = CloudAccountDeletionService();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _initializedUid;
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initializeName(User user, CloudUserProfile? profile) {
    if (_initializedUid == user.uid) return;
    _initializedUid = user.uid;
    final profileName = profile?.displayName.trim();
    final googleName = user.displayName?.trim();
    _nameController.text =
        profileName?.isNotEmpty == true
            ? profileName!
            : googleName?.isNotEmpty == true
            ? googleName!
            : 'Pengguna Azimutree';
  }

  Future<void> _saveName(User user) async {
    if (_isProcessing || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isProcessing = true);
    try {
      await _profileService.updateDisplayName(
        uid: user.uid,
        displayName: _nameController.text,
      );
      if (mounted) {
        await showAppSuccess(context, 'Nama tampilan berhasil diperbarui.');
      }
    } on TimeoutException {
      if (mounted) {
        await showAppWarning(
          context,
          'Server belum memberi konfirmasi. Periksa kembali nama yang tampil sebelum mencoba lagi.',
          title: 'Koneksi Lambat',
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        await showAppError(
          context,
          error.message ?? 'Profil tidak dapat diperbarui.',
          title: 'Gagal Mengubah Nama',
        );
      }
    } catch (error) {
      if (mounted) {
        await showAppError(context, error, title: 'Gagal Mengubah Nama');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteAccount(User user) async {
    if (_isProcessing) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => const AlertConfirmationWidget(
                title: 'Hapus Akun Penyimpanan Awan?',
                message:
                    'Seluruh lokasi penelitian, klaster publik maupun privat, profil, dan akun penyimpanan awan Anda akan dihapus permanen. Data lokal di perangkat tidak ikut dihapus. Tindakan ini tidak dapat dibatalkan.',
                confirmText: 'Hapus Permanen',
                cancelText: 'Batal',
                backgroundColor: Color.fromARGB(255, 255, 205, 210),
                keepBackgroundColorInDarkMode: true,
              ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    final accountEmail = user.email?.trim();
    final reauthenticationConfirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => AlertConfirmationWidget(
                title: 'Autentikasi Ulang Google',
                message:
                    'Untuk keamanan, Google akan meminta Anda memilih akun sekali lagi. Pilih akun yang sama dengan akun yang sedang terhubung:\n\n${accountEmail?.isNotEmpty == true ? accountEmail : 'Akun Google saat ini'}\n\nJika memilih akun lain, penghapusan akan dibatalkan.',
                confirmText: 'Lanjutkan',
                cancelText: 'Batal',
                backgroundColor: const Color.fromARGB(255, 255, 205, 210),
                keepBackgroundColorInDarkMode: true,
              ),
        ) ??
        false;
    if (!reauthenticationConfirmed || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await _authService.reauthenticateWithGoogle();
      await _deletionService.deleteAllOwnedData(user.uid);
      await _authService.deleteCurrentAccount();
      if (!mounted) return;
      await showAppSuccess(
        context,
        'Akun dan seluruh data penyimpanan awan berhasil dihapus.',
        title: 'Akun Dihapus',
      );
      if (mounted) Navigator.pop(context);
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled && mounted) {
        await showAppError(
          context,
          'Autentikasi Google gagal (${error.code.name}). Silakan coba kembali.',
          title: 'Penghapusan Gagal',
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        await showAppError(
          context,
          error.message ?? 'Firebase tidak dapat menghapus akun.',
          title: 'Penghapusan Gagal',
        );
      }
    } on TimeoutException {
      if (mounted) {
        await showAppError(
          context,
          'Koneksi terlalu lambat. Sebagian proses mungkin sudah berjalan; gunakan akun yang sama lalu coba kembali.',
          title: 'Koneksi Bermasalah',
        );
      }
    } catch (error) {
      if (mounted) {
        await showAppError(
          context,
          'Akun belum berhasil dihapus. Silakan coba kembali.\n$error',
          title: 'Penghapusan Gagal',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppbarWidget(title: 'Edit Profil'),
      drawer: const SidebarWidget(),
      body: Stack(
        children: [
          const BackgroundAppWidget(
            lightBackgroundImage: 'assets/images/light-bg-notitle.png',
            darkBackgroundImage: 'assets/images/dark-bg-notitle.png',
          ),
          SafeArea(
            child: ValueListenableBuilder<bool>(
              valueListenable: isLightModeNotifier,
              builder: (context, isLight, _) {
                final foreground = isLight ? Colors.black87 : Colors.white;
                return Column(
                  children: [
                    Row(
                      children: [
                        BackButton(
                          color: foreground,
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Penyimpanan Awan',
                          style: TextStyle(fontSize: 18, color: foreground),
                        ),
                      ],
                    ),
                    Expanded(
                      child: StreamBuilder<User?>(
                        stream: _authService.authStateChanges,
                        builder: (context, authSnapshot) {
                          final user = authSnapshot.data;
                          if (authSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (user == null) {
                            return Center(
                              child: Text(
                                'Akun sudah tidak terhubung.',
                                style: TextStyle(color: foreground),
                              ),
                            );
                          }
                          return StreamBuilder<CloudUserProfile?>(
                            stream: _profileService.watchProfile(user.uid),
                            builder: (context, profileSnapshot) {
                              if (profileSnapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !profileSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              _initializeName(user, profileSnapshot.data);
                              return _content(user, isLight, foreground);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(User user, bool isLight, Color foreground) {
    final cardColor =
        isLight
            ? const Color.fromARGB(240, 205, 237, 211)
            : const Color.fromARGB(255, 36, 67, 42);
    final fieldBorder = isLight ? Colors.grey : Colors.white54;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_isProcessing) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
        ],
        Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.account_circle, size: 54, color: foreground),
                  const SizedBox(height: 8),
                  Text(
                    user.email ?? 'Akun Google',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: foreground),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isProcessing,
                    maxLength: 20,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: foreground),
                    cursorColor: foreground,
                    validator:
                        (value) => CloudUserProfileService.validateDisplayName(
                          value ?? '',
                        ),
                    decoration: InputDecoration(
                      labelText: 'Nama tampilan',
                      labelStyle: TextStyle(
                        color: foreground.withValues(alpha: 0.72),
                      ),
                      counterStyle: TextStyle(
                        color: foreground.withValues(alpha: 0.72),
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: fieldBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: foreground, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _saveName(user),
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Nama'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor:
                          isLight
                              ? const Color(0xFF1F4226)
                              : const Color(0xFF14351D),
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hapus Akun',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Menghapus akun akan menghapus seluruh data yang pernah Anda unggah. Data lokal di perangkat tetap tersimpan.',
                  style: TextStyle(color: foreground.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _deleteAccount(user),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Hapus Akun dan Data Awan'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromARGB(255, 131, 30, 23),
                    disabledForegroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
