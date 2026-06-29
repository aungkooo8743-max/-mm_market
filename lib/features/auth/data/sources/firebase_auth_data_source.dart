import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../domain/models/user_model.dart';
import 'auth_data_source.dart';

/// A concrete [AuthDataSource] implementation backed by the Firebase Auth SDK.
///
/// All [FirebaseAuthException]s are caught here and re-thrown as [AppException]
/// instances so that the repository layer and Riverpod providers remain
/// decoupled from the Firebase SDK.
///
/// Error-code mapping follows the official Firebase Auth error-code reference:
/// https://firebase.google.com/docs/auth/admin/errors
class FirebaseAuthDataSource implements AuthDataSource {
  FirebaseAuthDataSource({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // ── AuthDataSource interface ───────────────────────────────────────────────

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _userModelFromFirebase(user);
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException(
          message: 'Sign-in succeeded but no user was returned.',
          code: 'null-user',
        );
      }
      return _userModelFromFirebase(user);
    } on FirebaseAuthException catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'signInWithEmail_datasource'));
      throw AppException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
        cause: e,
        stackTrace: st,
      );
    } on AppException {
      rethrow;
    } catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'signInWithEmail_datasource_unexpected'));
      throw AppException(
        message: 'An unexpected error occurred. Please try again.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e, st) {
      throw AppException(
        message: e.message ?? 'Sign-out failed.',
        code: e.code,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _auth.authStateChanges().map(
          (user) => user == null ? null : _userModelFromFirebase(user),
        );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Converts a Firebase [User] into a domain [UserModel].
  ///
  /// Uses [User.metadata.creationTime] as [UserModel.createdAt]; falls back to
  /// [DateTime.now()] when the metadata is unavailable (e.g. anonymous users).
  UserModel _userModelFromFirebase(User user) {
    final createdAt = user.metadata.creationTime ?? DateTime.now();
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      createdAt: createdAt,
      photoUrl: user.photoURL,
      phone: user.phoneNumber,
      updatedAt: user.metadata.lastSignInTime ?? createdAt,
    );
  }

  /// Maps a [FirebaseAuthException.code] to a user-readable English message.
  ///
  /// Codes that are not explicitly handled fall back to a generic message so
  /// that the UI always has something meaningful to display.
  static String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        // Firebase v10+ consolidates user-not-found + wrong-password into this.
        return 'Incorrect email or password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }
}
