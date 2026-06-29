import '../entities/app_user.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<String> sendOtp({required String phoneNumber});
  Future<AppUser> verifyOtp({required String verificationId, required String smsCode});
  Future<AppUser?> getCurrentUserProfile();

  /// Returns the currently signed-in user as a lightweight [UserModel], or
  /// `null` if no session exists.
  Future<UserModel?> getCurrentUser();

  /// Signs in with [email] and [password] and returns the authenticated user
  /// as a lightweight [UserModel].
  ///
  /// Throws an [AppException] on invalid credentials or network failure.
  Future<UserModel> signInWithEmail(String email, String password);

  /// Creates a new account with [email] and [password], creates a Firestore
  /// user profile, and returns the new user as a lightweight [UserModel].
  ///
  /// Throws an [AppException] on failure (e.g. email already in use).
  Future<UserModel> signUpWithEmail(String email, String password, {String? displayName});

  Future<void> signOut();

  /// Signs in with Google OAuth and returns the authenticated user.
  Future<UserModel> signInWithGoogle();

  /// Signs in with Facebook OAuth and returns the authenticated user.
  /// Auto-creates a Firestore profile if the user is new.
  Future<UserModel> signInWithFacebook();

  /// Signs in with TikTok OAuth and returns the authenticated user.
  /// Auto-creates a Firestore profile if the user is new.
  Future<UserModel> signInWithTikTok();
}
