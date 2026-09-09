import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/services/cloud_auth_service.dart';
import 'package:azimutree/services/cloud_user_profile_service.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_warning_widget.dart';
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:azimutree/views/widgets/cloud_storage_widget/owned_cloud_data_widget.dart';
import 'package:azimutree/views/widgets/cloud_storage_widget/public_cloud_browser_widget.dart';
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
  final CloudUserProfileService _profileService = CloudUserProfileService();
  bool _isProcessing = false;
  bool _showPublicForAuthenticated = false;
  bool _showOwnedData = false;
  String? _profileInitializedUid;

  @override
  void initState() {
    super.initState();
    selectedPageNotifier.value = 'cloud_storage_page';
  }

  Future<void> _signIn() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final credential = await _authService.signInWithGoogle();
      final user = credential.user;
      if (user != null) {
        await _profileService.ensureProfile(user);
        _profileInitializedUid = user.uid;
      }
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
      _profileInitializedUid = null;
      _showPublicForAuthenticated = false;
      _showOwnedData = false;
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

  void _ensureProfile(User user) {
    if (_profileInitializedUid == user.uid) return;
    _profileInitializedUid = user.uid;
    _profileService.ensureProfile(user).catchError((_) {
      if (_profileInitializedUid == user.uid) {
        _profileInitializedUid = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppbarWidget(title: 'Penyimpanan Awan'),
      drawer: const SidebarWidget(),
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
                        BackButton(
                          color: foreground,
                          onPressed: () {
                            if (_showPublicForAuthenticated || _showOwnedData) {
                              setState(() {
                                _showPublicForAuthenticated = false;
                                _showOwnedData = false;
                              });
                              return;
                            }
                            selectedPageNotifier.value = 'home';
                            Navigator.popAndPushNamed(context, 'home');
                          },
                        ),
                        Text(
                          _showPublicForAuthenticated || _showOwnedData
                              ? 'Menu akun'
                              : 'Kembali',
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
                          final user = snapshot.data;
                          if (user == null) {
                            return PublicCloudBrowserWidget(
                              showLogin: true,
                              onLogin: _signIn,
                              loginInProgress: _isProcessing,
                            );
                          }
                          if (_showPublicForAuthenticated) {
                            return PublicCloudBrowserWidget(
                              showLogin: false,
                              onLogin: _signIn,
                              loginInProgress: _isProcessing,
                            );
                          }
                          if (_showOwnedData) {
                            return StreamBuilder<CloudUserProfile?>(
                              stream: _profileService.watchProfile(user.uid),
                              builder: (context, profileSnapshot) {
                                final customName =
                                    profileSnapshot.data?.displayName.trim();
                                final googleName = user.displayName?.trim();
                                final ownerName =
                                    customName?.isNotEmpty == true
                                        ? customName!
                                        : (googleName?.isNotEmpty == true
                                            ? googleName!
                                            : 'Pengguna Azimutree');
                                return OwnedCloudDataWidget(
                                  user: user,
                                  ownerName: ownerName,
                                );
                              },
                            );
                          }
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            child: _buildAuthenticatedContent(user, isLight),
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

  Widget _buildAuthenticatedContent(User user, bool isLight) {
    _ensureProfile(user);
    return StreamBuilder<CloudUserProfile?>(
      stream: _profileService.watchProfile(user.uid),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final googleName = user.displayName?.trim();
        final displayName =
            profile?.displayName.isNotEmpty == true
                ? profile!.displayName
                : (googleName == null || googleName.isEmpty
                    ? 'Pengguna Azimutree'
                    : googleName);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isProcessing) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            _informationCard(
              isLight: isLight,
              icon: Icons.account_circle,
              title: displayName,
              message:
                  profile?.email.isNotEmpty == true
                      ? profile!.email
                      : (user.email ?? 'Akun Google telah terhubung'),
              actionTooltip: 'Edit profil',
              onActionPressed:
                  _isProcessing
                      ? null
                      : () =>
                          Navigator.pushNamed(context, 'cloud_profile_page'),
            ),
            const SizedBox(height: 12),
            _actionButton(
              label: 'Tampilkan Data Publik',
              icon: Icons.public,
              onPressed:
                  () => setState(() => _showPublicForAuthenticated = true),
            ),
            const SizedBox(height: 12),
            _actionButton(
              label: 'Kelola Data Sendiri',
              icon: Icons.cloud_upload,
              onPressed: () => setState(() => _showOwnedData = true),
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
      },
    );
  }

  Widget _informationCard({
    required bool isLight,
    required IconData icon,
    required String title,
    required String message,
    String? actionTooltip,
    VoidCallback? onActionPressed,
  }) {
    final foreground = isLight ? Colors.black87 : Colors.white;
    return Card(
      color:
          isLight
              ? const Color.fromARGB(240, 205, 237, 211)
              : const Color.fromARGB(255, 36, 67, 42),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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
          ),
          if (actionTooltip != null)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      isLight
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color.fromARGB(255, 18, 43, 25),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onActionPressed,
                  tooltip: actionTooltip,
                  color: foreground,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  iconSize: 19,
                  icon: const Icon(Icons.edit),
                ),
              ),
            ),
        ],
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
