import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CloudAuthService {
  CloudAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInitialization;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      return _firebaseAuth.signInWithPopup(GoogleAuthProvider());
    }

    await (_googleInitialization ??= _googleSignIn.initialize());
    final googleUser = await _googleSignIn.authenticate();
    final googleAuthentication = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuthentication.idToken,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> reauthenticateWithGoogle() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('Akun tidak sedang login.');
    if (kIsWeb) {
      await user.reauthenticateWithPopup(GoogleAuthProvider());
      return;
    }

    await (_googleInitialization ??= _googleSignIn.initialize());
    final googleUser = await _googleSignIn.authenticate();
    final authentication = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: authentication.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> deleteCurrentAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('Akun tidak sedang login.');
    await user.delete();
    if (!kIsWeb) {
      try {
        await (_googleInitialization ??= _googleSignIn.initialize());
        await _googleSignIn.signOut();
      } catch (_) {
        // The Firebase account is already deleted. Failure to clear the local
        // Google session must not turn a completed deletion into an error.
      }
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb) {
      await (_googleInitialization ??= _googleSignIn.initialize());
      await _googleSignIn.signOut();
    }
  }
}
