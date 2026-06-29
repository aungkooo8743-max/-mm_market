import '../../domain/models/user_model.dart';

/// Abstract contract for an authentication data source.
///
/// Concrete implementations (Firebase, mock, etc.) live alongside this file
/// and are injected into [AuthRepositoryImpl] via the DI container.
abstract class AuthDataSource {
  /// Returns the currently signed-in [UserModel], or `null` if no session
  /// exists.
  Future<UserModel?> getCurrentUser();

  /// Authenticates a user with [email] and [password].
  ///
  /// Throws an [Exception] on failure (wrong credentials, network error, etc.).
  Future<UserModel> signInWithEmail(String email, String password);

  /// Signs the current user out and clears the local session.
  Future<void> signOut();

  /// Emits the current [UserModel] whenever the Firebase Auth state changes
  /// (sign-in, sign-out, token refresh).
  ///
  /// Emits `null` when no user is signed in.
  Stream<UserModel?> authStateChanges();
}
