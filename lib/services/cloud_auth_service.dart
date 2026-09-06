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

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb) {
      await (_googleInitialization ??= _googleSignIn.initialize());
      await _googleSignIn.signOut();
    }
  }
}
