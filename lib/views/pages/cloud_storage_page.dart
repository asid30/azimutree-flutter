import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/services/cloud_auth_service.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_warning_widget.dart';
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CloudStoragePage extends StatefulWidget {
  const CloudStoragePage({super.key});

  @override
  State<CloudStoragePage> createState() => _CloudStoragePageState();
}

class _CloudStoragePageState extends State<CloudStoragePage> {
  final CloudAuthService _authService = CloudAuthService();
  bool _isProcessing = false;

  Future<void> _signIn() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _authService.signInWithGoogle();
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled) {
        await _showMessage(
          'Login Gagal',
          'Google Sign-In gagal (${error.code.name}). Silakan coba kembali.',
        );
      }
    } on FirebaseAuthException catch (error) {
      await _showMessage(
        'Login Gagal',
        error.message ?? 'Firebase tidak dapat memproses login Google.',
      );
    } catch (_) {
      await _showMessage(
        'Login Gagal',
        'Tidak dapat masuk dengan Google. Periksa koneksi lalu coba kembali.',
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _signOut() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _authService.signOut();
    } catch (_) {
      await _showMessage('Logout Gagal', 'Tidak dapat keluar dari akun.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showMessage(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertWarningWidget(title: title, warningMessage: message),
    );
  }

  Future<void> _showComingSoon(String feature) => _showMessage(
    feature,
    'Tampilan $feature sudah disiapkan. Data awan akan dihubungkan pada tahap berikutnya.',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppbarWidget(title: 'Penyimpanan Awan'),
      body: Stack(
        children: [
          BackgroundAppWidget(
            lightBackgroundImage: 'assets/images/light-bg-notitle.png',
            darkBackgroundImage: 'assets/images/dark-bg-notitle.png',
          ),
          SafeArea(
            child: ValueListenableBuilder<bool>(
              valueListenable: isLightModeNotifier,
              builder: (context, isLight, _) {
                final foreground = isLight ? Colors.black : Colors.white;
                return Column(
                  children: [
                    Row(
                      children: [
                        BackButton(color: foreground),
                        Text(
                          'Kembali',
                          style: TextStyle(fontSize: 18, color: foreground),
                        ),
                      ],
                    ),
                    Expanded(
                      child: StreamBuilder<User?>(
                        stream: _authService.authStateChanges,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            child:
                                snapshot.data == null
                                    ? _buildGuestContent(isLight)
                                    : _buildAuthenticatedContent(
                                      snapshot.data!,
                                      isLight,
                                    ),
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

  Widget _buildGuestContent(bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _informationCard(
          isLight: isLight,
          icon: Icons.cloud_done,
          title: 'Terhubung ke Azimutree Cloud',
          message:
              'Anda dapat melihat dan mengunduh data publik tanpa login. Login diperlukan untuk mengunggah dan mengelola data sendiri.',
        ),
        const SizedBox(height: 20),
        _actionButton(
          label: 'Tampilkan Data Publik',
          icon: Icons.public,
          onPressed: () => _showComingSoon('Data Publik'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isProcessing ? null : _signIn,
          icon:
              _isProcessing
                  ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.login),
          label: const Text('Masuk dengan Google'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isLight ? const Color(0xFF1F4226) : Colors.white,
            side: BorderSide(
              color: isLight ? const Color(0xFF1F4226) : Colors.white70,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedContent(User user, bool isLight) {
    final displayName = user.displayName?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _informationCard(
          isLight: isLight,
          icon: Icons.account_circle,
          title:
              displayName == null || displayName.isEmpty
                  ? 'Pengguna Azimutree'
                  : displayName,
          message: user.email ?? 'Akun Google telah terhubung',
        ),
        const SizedBox(height: 20),
        _actionButton(
          label: 'Tampilkan Data Publik',
          icon: Icons.public,
          onPressed: () => _showComingSoon('Data Publik'),
        ),
        const SizedBox(height: 12),
        _actionButton(
          label: 'Kelola Data Sendiri',
          icon: Icons.cloud_upload,
          onPressed: () => _showComingSoon('Kelola Data Sendiri'),
        ),
        const SizedBox(height: 12),
        _actionButton(
          label: 'Keluar dari akun',
          icon: Icons.logout,
          onPressed: _isProcessing ? null : _signOut,
          backgroundColor: const Color.fromARGB(255, 131, 30, 23),
        ),
      ],
    );
  }

  Widget _informationCard({
    required bool isLight,
    required IconData icon,
    required String title,
    required String message,
  }) {
    final foreground = isLight ? Colors.black87 : Colors.white;
    return Card(
      color:
          isLight
              ? const Color.fromARGB(240, 205, 237, 211)
              : const Color.fromARGB(255, 36, 67, 42),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 48, color: foreground),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: foreground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Color backgroundColor = const Color(0xFF1F4226),
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
