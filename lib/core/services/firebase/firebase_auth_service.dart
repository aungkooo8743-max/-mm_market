import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../errors/app_exception.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  const FirebaseAuthService(this._auth, this._googleSignIn);
  User? get currentUser => _auth.currentUser;
  /// Exposes the underlying [FirebaseAuth] instance for credential-based sign-ins
  /// (e.g. Facebook) that are not wrapped by this service.
  FirebaseAuth get firebaseAuth => _auth;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> verifyPhoneNumber({required String phoneNumber, required PhoneCodeSent codeSent, required PhoneVerificationFailed verificationFailed, PhoneVerificationCompleted? verificationCompleted, PhoneCodeAutoRetrievalTimeout? codeAutoRetrievalTimeout}) async {
    try {
      await _auth.verifyPhoneNumber(phoneNumber: phoneNumber, verificationCompleted: verificationCompleted ?? (_) {}, verificationFailed: verificationFailed, codeSent: codeSent, codeAutoRetrievalTimeout: codeAutoRetrievalTimeout ?? (_) {});
    } on FirebaseAuthException catch (e, st) {
      throw AppException(message: e.message ?? 'Phone verification failed', code: e.code, cause: e, stackTrace: st);
    }
  }

  Future<UserCredential> signInWithOtp({required String verificationId, required String smsCode}) async {
    try {
      final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
      return _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e, st) {
      throw AppException(message: e.message ?? 'OTP verification failed', code: e.code, cause: e, stackTrace: st);
    }
  }

  /// Signs in with [email] and [password].
  ///
  /// Throws an [AppException] wrapping the underlying [FirebaseAuthException]
  /// on invalid credentials or network failure.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e, st) {
      throw AppException(
        message: e.message ?? 'Email sign-in failed',
        code: e.code,
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Creates a new Firebase Auth user with [email] and [password].
  ///
  /// Throws an [AppException] on failure (e.g. email-already-in-use, weak-password).
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e, st) {
      throw AppException(
        message: e.message ?? 'Account creation failed',
        code: e.code,
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Signs in with Google OAuth and returns a [UserCredential].
  ///
  /// Throws an [AppException] if the user cancels or sign-in fails.
  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AppException(
          message: 'Google Sign-In ကို ပယ်ဖျက်ခဲ့သည်\nGoogle Sign-In was cancelled.',
          code: 'sign-in-cancelled',
        );
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on AppException {
      rethrow;
    } on FirebaseAuthException catch (e, st) {
      throw AppException(
        message: e.message ?? 'Google Sign-In failed',
        code: e.code,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      throw AppException(
        message: 'Google Sign-In failed. Please try again.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
