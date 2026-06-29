import '../../domain/entities/app_user.dart';

class AuthGuard {
  const AuthGuard._();
  static bool isBlocked(AppUser? user) {
    if (user == null) return false;
    return user.status == UserStatus.suspended || user.status == UserStatus.banned || user.status == UserStatus.deleted;
  }
  static String blockedMessage(AppUser user) {
    switch (user.status) {
      case UserStatus.suspended: return 'Your account has been suspended.';
      case UserStatus.banned: return 'Your account has been banned.';
      case UserStatus.deleted: return 'This account has been deleted.';
      case UserStatus.active: return '';
    }
  }
}
