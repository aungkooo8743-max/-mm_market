// ─────────────────────────────────────────────────────────────────────────────
// app_router.dart  —  MM Market  v3.3.7+17
//
// DEFINITIVE FIX for splash-screen stuck bug:
//
//   PROBLEM (v3.3.7+16 and before):
//     appRouterProvider used ref.watch(routerNotifierProvider).
//     Every auth-state change caused Riverpod to rebuild appRouterProvider,
//     which created a NEW RouterNotifier (resetting the 6-second fallback
//     timer) AND a NEW GoRouter (wiping navigation state).
//     Result: the fallback timer was perpetually reset → splash stuck forever.
//
//   FIX:
//     1. routerNotifierProvider is marked keepAlive so it is never disposed.
//     2. appRouterProvider uses ref.read (not ref.watch) so GoRouter is
//        created exactly once and the RouterNotifier lives for the app lifetime.
//     3. app.dart watches routerNotifierProvider to keep it alive in the widget
//        tree, but the router itself is read once.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/guards/auth_guard.dart';
import '../../features/auth/presentation/pages/account_blocked_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/favorite/presentation/pages/favorites_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/notification/presentation/pages/notification_page.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/report/domain/entities/report.dart';
import '../../features/report/presentation/pages/report_page.dart';
import '../../features/review/presentation/pages/submit_review_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../widgets/main_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RouterNotifier
// ─────────────────────────────────────────────────────────────────────────────

class RouterNotifier extends ChangeNotifier {
  AppUser? _user;
  bool _initialized = false;
  Timer? _fallbackTimer;

  RouterNotifier() {
    // Hard fallback: if Firebase Auth never emits within 5 seconds,
    // force initialized = true (user = null → sign-in) and notify router.
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (!_initialized) {
        debugPrint('[RouterNotifier] ⚠️ fallback timer fired — forcing sign-in');
        _user = null;
        _initialized = true;
        notifyListeners();
      }
    });
    debugPrint('[RouterNotifier] created — fallback timer started (5s)');
  }

  AppUser? get user => _user;
  bool get initialized => _initialized;

  void update(AsyncValue<AppUser?> authAsync) {
    authAsync.when(
      data: (user) {
        debugPrint('[RouterNotifier] auth resolved — user: ${user?.uid ?? "null"}');
        _fallbackTimer?.cancel();
        _user = user;
        _initialized = true;
        notifyListeners();
      },
      error: (err, _) {
        debugPrint('[RouterNotifier] auth error: $err — forcing sign-in');
        _fallbackTimer?.cancel();
        _user = null;
        _initialized = true;
        notifyListeners();
      },
      loading: () {
        debugPrint('[RouterNotifier] auth loading — waiting for stream...');
        // Do nothing — fallback timer handles the case where loading never ends.
      },
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

// keepAlive ensures this notifier (and its fallback timer) is never GC'd.
final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  ref.keepAlive();
  final notifier = RouterNotifier();
  // Listen to auth stream and forward updates to the notifier.
  ref.listen<AsyncValue<AppUser?>>(authStateChangesProvider, (_, next) {
    notifier.update(next);
  });
  // Seed immediately in case the stream already has a value.
  notifier.update(ref.read(authStateChangesProvider));
  return notifier;
});

// CRITICAL: use ref.read so GoRouter is created exactly ONCE.
// The router is kept alive by app.dart watching routerNotifierProvider.
final appRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      // Not yet initialized — stay on splash.
      // RouterNotifier's fallback timer guarantees this resolves within 5 s.
      if (!notifier.initialized) {
        final isSplash = state.matchedLocation == AppRoutes.splash;
        return isSplash ? null : AppRoutes.splash;
      }

      final location = state.matchedLocation;
      final isSplash = location == AppRoutes.splash;
      final isLogin = location == AppRoutes.login;
      final isSignIn = location == AppRoutes.signIn;
      final isSignUp = location == AppRoutes.signUp;
      final isForgotPassword = location == AppRoutes.forgotPassword;
      final isBlocked = location == AppRoutes.accountBlocked;
      final user = notifier.user;

      // CRITICAL FIX (v3.3.7+20): Do NOT allow splash after router is initialized.
      // Previously isSplash was in the allowed list, so an unauthenticated user
      // landing on '/' after initialization would stay on splash forever.
      // Now splash always redirects to /sign-in once initialized and user == null.
      if (user == null) {
        final isPublicAuthRoute =
            isLogin || isSignIn || isSignUp || isForgotPassword;
        return isPublicAuthRoute ? null : AppRoutes.signIn;
      }

      if (AuthGuard.isBlocked(user)) {
        return isBlocked ? null : AppRoutes.accountBlocked;
      }

      if (isSplash || isLogin || isSignIn || isSignUp || isBlocked) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRouteNames.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRouteNames.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: AppRouteNames.signIn,
        builder: (_, __) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: AppRouteNames.signUp,
        builder: (_, __) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRoutes.accountBlocked,
        name: AppRouteNames.accountBlocked,
        builder: (_, __) => const AccountBlockedPage(),
      ),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: AppRouteNames.home,
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.search,
            name: AppRouteNames.search,
            builder: (_, __) => const SearchPage(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: AppRouteNames.notifications,
            builder: (_, __) => const NotificationPage(),
          ),
          GoRoute(
            path: AppRoutes.favorites,
            name: AppRouteNames.favorites,
            builder: (_, __) => const FavoritesPage(),
          ),
          GoRoute(
            path: AppRoutes.chats,
            name: AppRouteNames.chats,
            builder: (_, __) => const ChatListPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: AppRouteNames.profile,
            builder: (_, __) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: AppRouteNames.editProfile,
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.addProduct,
        name: AppRouteNames.addProduct,
        builder: (_, __) => const AddProductPage(),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        name: AppRouteNames.productDetail,
        builder: (_, state) => ProductDetailPage(
          productId: state.pathParameters['productId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.editProduct,
        name: AppRouteNames.editProduct,
        builder: (_, state) => EditProductPage(
          productId: state.pathParameters['productId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.chatRoom,
        name: AppRouteNames.chatRoom,
        builder: (_, state) => ChatRoomPage(
          chatRoomId: state.pathParameters['chatRoomId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.submitReview,
        name: AppRouteNames.submitReview,
        builder: (_, state) => SubmitReviewPage(
          sellerId: state.pathParameters['sellerId'] ?? '',
          productId: state.pathParameters['productId'] ?? '',
          reviewId: state.uri.queryParameters['reviewId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.report,
        name: AppRouteNames.report,
        builder: (_, state) {
          final targetId = state.pathParameters['targetId'] ?? '';
          final typeStr = state.uri.queryParameters['type'] ?? '';
          final targetType = ReportTargetType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => ReportTargetType.product,
          );
          return ReportPage(targetId: targetId, targetType: targetType);
        },
      ),
    ],
    errorBuilder: (_, state) => _RouteErrorPage(error: state.error),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Route constants
// ─────────────────────────────────────────────────────────────────────────────

class AppRoutes {
  const AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const signIn = '/sign-in';
  static const forgotPassword = '/forgot-password';
  static const signUp = '/sign-up';
  static const accountBlocked = '/account-blocked';
  static const home = '/home';
  static const search = '/search';
  static const notifications = '/notifications';
  static const favorites = '/favorites';
  static const chats = '/chats';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const addProduct = '/products/add';
  static const productDetail = '/products/:productId';
  static const editProduct = '/products/:productId/edit';
  static const chatRoom = '/chats/:chatRoomId';
  static const submitReview = '/reviews/:sellerId/:productId';
  static const report = '/report/:targetId';

  static String productDetailPath(String productId) => '/products/$productId';
  static String editProductPath(String productId) =>
      '/products/$productId/edit';
  static String chatRoomPath(String chatRoomId) => '/chats/$chatRoomId';
  static String submitReviewPath({
    required String sellerId,
    required String productId,
    String? reviewId,
  }) {
    final base = '/reviews/$sellerId/$productId';
    return reviewId != null ? '$base?reviewId=$reviewId' : base;
  }

  static String reportPath({
    required String targetId,
    required ReportTargetType targetType,
  }) =>
      '/report/$targetId?type=${targetType.name}';
}

class AppRouteNames {
  const AppRouteNames._();
  static const splash = 'splash';
  static const login = 'login';
  static const signIn = 'signIn';
  static const forgotPassword = 'forgotPassword';
  static const signUp = 'signUp';
  static const accountBlocked = 'accountBlocked';
  static const home = 'home';
  static const search = 'search';
  static const notifications = 'notifications';
  static const favorites = 'favorites';
  static const chats = 'chats';
  static const profile = 'profile';
  static const editProfile = 'editProfile';
  static const addProduct = 'addProduct';
  static const productDetail = 'productDetail';
  static const editProduct = 'editProduct';
  static const chatRoom = 'chatRoom';
  static const submitReview = 'submitReview';
  static const report = 'report';
}

class _RouteErrorPage extends StatelessWidget {
  final Exception? error;
  const _RouteErrorPage({required this.error});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Route Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error?.toString() ?? 'Unknown route error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}
