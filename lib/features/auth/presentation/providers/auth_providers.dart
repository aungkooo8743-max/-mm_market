import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => sl<AuthRepository>());
final authStateChangesProvider = StreamProvider<AppUser?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());
final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authStateChangesProvider).valueOrNull);
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));

/// Exposes the currently signed-in user as a lightweight [UserModel].
/// Resolves asynchronously from the repository on first access.
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

class AuthController extends StateNotifier<AuthState> {
  final Ref ref;
  AuthController(this.ref) : super(const AuthState());

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, otpSent: false, clearError: true);
    CrashlyticsService.log('sendOtp: $phoneNumber');
    try {
      final id = await ref.read(authRepositoryProvider).sendOtp(phoneNumber: phoneNumber);
      state = state.copyWith(isLoading: false, otpSent: true, verificationId: id, clearError: true);
    } catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'sendOtp'));
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> verifyOtp({required String verificationId, required String smsCode}) async {
    state = state.copyWith(isLoading: true, verified: false, clearError: true);
    CrashlyticsService.log('verifyOtp started');
    try {
      await ref.read(authRepositoryProvider).verifyOtp(verificationId: verificationId, smsCode: smsCode);
      state = state.copyWith(isLoading: false, verified: true, clearError: true);
    } catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'verifyOtp'));
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    CrashlyticsService.log('signInWithEmail started');
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(email, password);
      state = state.copyWith(isLoading: false, verified: true, clearError: true);
    } catch (e, st) {
      unawaited(CrashlyticsService.recordAuthError(e, st, operation: 'signInWithEmail_controller'));
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

/// An [AsyncNotifier] that resolves and exposes the current user as a
/// [UserModel] — suitable for use in widgets that need lightweight user data
/// without subscribing to the full [AppUser] stream.
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() =>
      ref.watch(authRepositoryProvider).getCurrentUser();

  /// Signs in with [email] and [password] and refreshes the notifier state.
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    CrashlyticsService.log('AuthNotifier.signInWithEmail started');
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithEmail(email, password),
    );
    if (state.hasError) {
      unawaited(CrashlyticsService.recordAuthError(
        state.error!, state.stackTrace, operation: 'AuthNotifier_signInWithEmail'));
    }
  }

  /// Creates a new account with [email] and [password] and refreshes the notifier state.
  Future<void> signUpWithEmail(String email, String password, {String? displayName}) async {
    state = const AsyncLoading();
    CrashlyticsService.log('AuthNotifier.signUpWithEmail started');
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUpWithEmail(
            email,
            password,
            displayName: displayName,
          ),
    );
    if (state.hasError) {
      unawaited(CrashlyticsService.recordAuthError(
        state.error!, state.stackTrace, operation: 'AuthNotifier_signUpWithEmail'));
    }
  }

  /// Signs in with Google OAuth and refreshes the notifier state.
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    CrashlyticsService.log('AuthNotifier.signInWithGoogle started');
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
    if (state.hasError) {
      unawaited(CrashlyticsService.recordAuthError(
        state.error!, state.stackTrace, operation: 'AuthNotifier_signInWithGoogle'));
    }
  }

  /// Signs in with Facebook OAuth and refreshes the notifier state.
  /// Auto-creates a Firestore profile for new users.
  Future<void> signInWithFacebook() async {
    state = const AsyncLoading();
    CrashlyticsService.log('AuthNotifier.signInWithFacebook started');
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithFacebook(),
    );
    if (state.hasError) {
      unawaited(CrashlyticsService.recordAuthError(
        state.error!, state.stackTrace, operation: 'AuthNotifier_signInWithFacebook'));
    }
  }

  /// Signs in with TikTok OAuth and refreshes the notifier state.
  Future<void> signInWithTikTok() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithTikTok(),
    );
  }

  /// Signs the current user out and clears the notifier state.
  Future<void> signOut() async {
    CrashlyticsService.log('AuthNotifier.signOut');
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
    // Clear Crashlytics user identity on sign-out
    unawaited(CrashlyticsService.setUserId(null));
  }
}
