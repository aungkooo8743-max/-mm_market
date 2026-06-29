import 'dart:async';

import '../../domain/models/user_model.dart';
import 'auth_data_source.dart';

/// A mock [AuthDataSource] that returns deterministic responses.
///
/// This implementation guarantees compile-readiness and allows UI development
/// to proceed before the Firebase Auth integration is wired in.  It is
/// **never** used in production; the DI container selects the concrete
/// implementation at registration time.
class MockAuthDataSource implements AuthDataSource {
  static final UserModel _mockUser = UserModel(
    id: 'mock-uid-001',
    email: 'demo@mmmarket.app',
    displayName: 'Demo User',
    createdAt: DateTime(2024, 1, 1),
    phone: '+959000000000',
    updatedAt: DateTime(2024, 1, 1),
  );

  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    // Simulate a short network round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (password.isEmpty) {
      throw Exception('Password must not be empty.');
    }

    _currentUser = _mockUser.copyWith(email: email);
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Stream<UserModel?> authStateChanges() => _authStateController.stream;
}
