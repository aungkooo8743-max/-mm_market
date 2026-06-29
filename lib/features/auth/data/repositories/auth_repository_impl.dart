import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/firebase/fcm_token_sync_service.dart';
import '../../../../core/services/firebase/firebase_auth_service.dart';
import '../../../../core/services/firebase/firestore_service.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository].
///
/// Delegates phone/OTP operations to [FirebaseAuthService] and email/password
/// operations to [FirebaseAuthService.signInWithEmailAndPassword].
///
/// All [FirebaseAuthException]s are caught at this layer and re-thrown as
/// [AppException] instances with user-readable messages so that the Riverpod
/// providers and UI layer remain decoupled from the Firebase SDK.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService authService;
  final FirestoreService firestoreService;
  final FcmTokenSyncService fcmTokenSyncService;
  String? _verificationId;

  AuthRepositoryImpl({
    required this.authService,
    required this.firestoreService,
    required this.fcmTokenSyncService,
  });

  // ── AuthRepository interface ───────────────────────────────────────────────

  @override
  AppUser? get currentUser {
    final user = authService.currentUser;
    if (user == null) return null;
    final now = DateTime.now();
    return AppUser(
      uid: user.uid,
      phone: user.phoneNumber ?? '',
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Stream<AppUser?> authStateChanges() => authService
      .authStateChanges()
      .asyncMap((user) async {
        if (user == null) return null;
        try {
          // Apply a 10-second timeout so the splash screen never hangs
          // indefinitely when Firestore is slow or unreachable.
          return await _loadOrCreateUser(user)
              .timeout(const Duration(seconds: 10));
        } on TimeoutException {
          // Firestore is unreachable — return a minimal user so the app
          // can still navigate away from the splash screen.
          final now = DateTime.now();
          return AppUser(
            uid: user.uid,
            phone: user.phoneNumber ?? '',
            displayName: user.displayName,
            photoUrl: user.photoURL,
            createdAt: now,
            updatedAt: now,
          );
        } catch (e) {
          // Any other error (PERMISSION_DENIED, network, etc.) — treat as
          // signed-out so the router redirects to the login screen.
          return null;
        }
      });

  @override
  Future<String> sendOtp({required String phoneNumber}) async {
    final completer = Completer<String>();
    await authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      codeSent: (verificationId, _) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(
            AppException(
              message: error.message ?? 'OTP ပို့မရပါ',
              code: error.code,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );
    return completer.future;
  }

  @override
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final id = verificationId.isNotEmpty ? verificationId : _verificationId;
    if (id == null || id.isEmpty) {
      throw const AppException(message: 'Verification ID မရှိပါ');
    }
    final credential = await authService.signInWithOtp(
      verificationId: id,
      smsCode: smsCode,
    );
    final user = credential.user;
    if (user == null) throw const AppException(message: 'Login failed');
    return _loadOrCreateUser(user);
  }

  @override
  Future<AppUser?> getCurrentUserProfile() async {
    final user = authService.currentUser;
    if (user == null) return null;
    final doc = await firestoreService
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap({...doc.data()!, 'uid': doc.id});
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = authService.currentUser;
    if (user == null) return null;
    try {
      final doc = await firestoreService
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();
      if (!doc.exists || doc.data() == null) {
        // User exists in Firebase Auth but not yet in Firestore — build a
        // minimal UserModel directly from the Firebase Auth record.
        final createdAt = user.metadata.creationTime ?? DateTime.now();
        return UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          createdAt: createdAt,
          phone: user.phoneNumber,
          updatedAt: user.metadata.lastSignInTime ?? createdAt,
        );
      }
      final appUser = AppUser.fromMap({...doc.data()!, 'uid': doc.id});
      // Preserve the Firebase Auth email on the UserModel even though AppUser
      // is phone-based and does not carry an email field.
      return UserModel.fromAppUser(appUser).copyWith(email: user.email ?? '');
    } on FirebaseAuthException catch (e, st) {
      throw AppException(
        message: e.message ?? 'Failed to load user profile.',
        code: e.code,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await authService.signInWithEmailAndPassword(
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
      // Attempt to load/create a Firestore profile for the email user.
      // If Firestore is unavailable we still return a valid UserModel from
      // the Firebase Auth record so the UI is not blocked.
      try {
        final appUser = await _loadOrCreateUser(user);
        return UserModel.fromAppUser(appUser).copyWith(email: user.email ?? '');
      } catch (_) {
        final createdAt = user.metadata.creationTime ?? DateTime.now();
        return UserModel(
          id: user.uid,
          email: user.email ?? email,
          displayName: user.displayName ?? '',
          createdAt: createdAt,
          phone: user.phoneNumber,
          updatedAt: user.metadata.lastSignInTime ?? createdAt,
        );
      }
    } on AppException {
      rethrow;
    } on FirebaseAuthException catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'signInWithEmail'));
      throw AppException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'signInWithEmail_unexpected'));
      throw AppException(
        message: 'An unexpected error occurred. Please try again.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<UserModel> signUpWithEmail(String email, String password, {String? displayName}) async {
    try {
      final credential = await authService.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException(
          message: 'Account creation succeeded but no user was returned.',
          code: 'null-user',
        );
      }
      // Update display name in Firebase Auth if provided.
      if (displayName != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }
      // Create the Firestore user profile document.
      final now = DateTime.now();
      final appUser = AppUser(
        uid: user.uid,
        phone: user.phoneNumber ?? '',
        displayName: displayName?.trim() ?? user.displayName,
        photoUrl: user.photoURL,
        createdAt: now,
        updatedAt: now,
      );
      final users = firestoreService.collection(FirestoreCollections.users);
      await users.doc(user.uid).set(
        {
          ...appUser.toMap(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      unawaited(fcmTokenSyncService.syncToken(user.uid));
      return UserModel.fromAppUser(appUser).copyWith(email: email.trim());
    } on AppException {
      rethrow;
    } on FirebaseAuthException catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'signUpWithEmail'));
      throw AppException(
        message: _mapSignUpError(e.code),
        code: e.code,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'signUpWithEmail_unexpected'));
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
      await authService.signOut();
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
  Future<UserModel> signInWithGoogle() async {
    try {
      final credential = await authService.signInWithGoogle();
      final user = credential.user;
      if (user == null) {
        throw const AppException(
          message: 'Google Sign-In succeeded but no user was returned.',
          code: 'null-user',
        );
      }
      // Load or create Firestore profile for the Google user.
      try {
        final appUser = await _loadOrCreateUser(user);
        return UserModel.fromAppUser(appUser).copyWith(email: user.email ?? '');
      } catch (_) {
        final createdAt = user.metadata.creationTime ?? DateTime.now();
        return UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          createdAt: createdAt,
          phone: user.phoneNumber,
          updatedAt: user.metadata.lastSignInTime ?? createdAt,
        );
      }
    } on AppException {
      rethrow;
    } on FirebaseAuthException catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'signInWithGoogle'));
      throw AppException(
        message: e.message ?? 'Google Sign-In failed.',
        code: e.code,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'signInWithGoogle_unexpected'));
      throw AppException(
        message: 'Google Sign-In failed. Please try again.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  // ── Facebook Sign-In ───────────────────────────────────────────────────────

  @override
  Future<UserModel> signInWithFacebook() async {
    try {
      // Trigger Facebook OAuth flow
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        throw const AppException(
          message: 'Facebook Sign-In ကို ဖျက်သိမ်းလိုက်ပါသည်',
          code: 'sign-in-cancelled',
        );
      }

      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw AppException(
          message: result.message ?? 'Facebook Sign-In မအောင်မြင်ပါ',
          code: 'facebook-auth-failed',
        );
      }

      // Exchange Facebook token for Firebase credential
      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );
      final userCredential = await authService.firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const AppException(
          message: 'Facebook Sign-In succeeded but no user was returned.',
          code: 'null-user',
        );
      }

      // Auto-create Firestore profile for new users
      try {
        final appUser = await _loadOrCreateUser(user);
        return UserModel.fromAppUser(appUser).copyWith(email: user.email ?? '');
      } catch (_) {
        final createdAt = user.metadata.creationTime ?? DateTime.now();
        return UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          createdAt: createdAt,
          phone: user.phoneNumber,
          updatedAt: user.metadata.lastSignInTime ?? createdAt,
        );
      }
    } on AppException {
      rethrow;
    } on FirebaseAuthException catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'signInWithFacebook'));
      if (e.code == 'account-exists-with-different-credential') {
        throw AppException(
          message: 'အီ email ဖြင့် အကောင့်တစ္ခု ရှိပြီးသည့်ဖြစ်သည့်အ Google သို့မဟုတ် Email ဖြင့် ဝင့်ရောက်ပါ',
          code: e.code,
          cause: e,
          stackTrace: st,
        );
      }
      throw AppException(
        message: e.message ?? 'Facebook Sign-In မအောင့်မြင့်ပါ',
        code: e.code,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'signInWithFacebook_unexpected'));
      throw AppException(
        message: 'Facebook Sign-In မအောင့်မြင့်ပါအ ထပ်မံကြိုးစားပါ',
        cause: e,
        stackTrace: st,
      );
    }
  }

  // ── TikTok Sign-In ─────────────────────────────────────────────────────────
  // TikTok does not have an official Flutter/Firebase SDK.
  // Full implementation requires: TikTok Developer account → OAuth web flow
  // → backend token exchange → Firebase Custom Token.
  // The button is shown in the UI; the backend wiring is left for a future release.

  @override
  Future<UserModel> signInWithTikTok() async {
    throw const AppException(
      message: 'TikTok Sign-In ကို မကြာမီ ထည့်သွင်းပေးပါမည်',
      code: 'tiktok-coming-soon',
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<AppUser> _loadOrCreateUser(User firebaseUser) async {
    final users = firestoreService.collection(FirestoreCollections.users);
    final doc = await users.doc(firebaseUser.uid).get();
    final now = DateTime.now();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap({...doc.data()!, 'uid': doc.id});
    }
    final user = AppUser(
      uid: firebaseUser.uid,
      phone: firebaseUser.phoneNumber ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: now,
      updatedAt: now,
    );
    await users.doc(user.uid).set(
      {
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    unawaited(fcmTokenSyncService.syncToken(user.uid));
    return user;
  }

  /// Maps a [FirebaseAuthException.code] from account creation to a user-readable message.
  static String _mapSignUpError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in instead.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password registration is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Registration failed ($code). Please try again.';
    }
  }

  /// Maps a [FirebaseAuthException.code] to a user-readable English message.
  ///
  /// Kept in sync with [FirebaseAuthDataSource._mapFirebaseAuthError] so that
  /// both the data-source and repository layers produce consistent messages.
  static String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }
}
