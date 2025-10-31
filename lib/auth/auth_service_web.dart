import 'package:firebase_auth/firebase_auth.dart';

class AuthServiceWeb {
  final _auth = FirebaseAuth.instance;

  Stream<User?> authState() => _auth.authStateChanges();

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Google Sign-In for WEB using popup (no google_sign_in package required)
  Future<UserCredential> signInWithGooglePopup() {
    return _auth.signInWithPopup(GoogleAuthProvider());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authWeb = AuthServiceWeb();
