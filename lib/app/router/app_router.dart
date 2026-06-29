// ─────────────────────────────────────────────────────────────────────────────
// app_router.dart  —  MM Market  v3.3.7+23
//
// FIX v3.3.7+23 (DEFINITIVE): Changed ref.watch → ref.read in appRouterProvider.
//
// ROOT CAUSE of splash-screen hang:
//   appRouterProvider used ref.watch(routerNotifierProvider). In Riverpod,
//   ref.watch() inside a Provider causes the provider to be INVALIDATED and
//   RECREATED whenever the watched value changes. Since RouterNotifier calls
//   notifyListeners() on every auth state change, GoRouter was being recreated
//   from scratch on every auth event — resetting to initialLocation='/' (splash)
//   each time, creating an infinite splash loop.
//
// THE FIX:
//   • Use ref.read() in appRouterProvider so GoRouter is created ONCE.
//   • RouterNotifier (ChangeNotifier) is passed as refreshListenable so the
//     redirect guard re-runs on auth changes WITHOUT recreating the router.
//   • app.dart correctly uses ref.watch(routerNotifierProvider) to keep the
//     notifier alive, and ref.read(appRouterProvider) to get the stable router.
//   • SplashPage 5-second hard timer is kept as a belt-and-suspenders fallback.
// ─────────────────────────────────────────────────────────────────────────────

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
// RouterNotifier — bridges Riverpod auth stream → GoRouter refreshListenable
// ─────────────────────────────────────────────────────────────────────────────

class RouterNotifier extends ChangeNotifier {
  AppUser? _user;
  bool _initialized = false;

  AppUser? get user => _user;
  bool get initialized => _initialized;

  void update(AsyncValue<AppUser?> authAsync) {
    authAsync.when(
      data: (user) {
        _user = user;
        _initialized = true;
        notifyListeners();
      },
      error: (_, __) {
        // On error treat as signed-out so the user reaches sign-in.
        _user = null;
        _initialized = true;
        notifyListeners();
      },
      loading: () {
        // Still loading — do not notify yet; SplashPage hard-timer handles timeout.
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Holds the RouterNotifier instance.
final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  final notifier = RouterNotifier();
  // Listen (not watch) so we don't rebuild this provider on every auth change.
  ref.listen<AsyncValue<AppUser?>>(authStateChangesProvider, (_, next) {
    notifier.update(next);
  });
  // Seed with the current value in case the stream already has data.
  notifier.update(ref.read(authStateChangesProvider));
  return notifier;
});

/// Creates GoRouter ONCE. Uses refreshListenable so the redirect guard
/// re-runs whenever RouterNotifier fires — without recreating the router.
final appRouterProvider = Provider<GoRouter>((ref) {
  // CRITICAL: Use ref.read (NOT ref.watch) so GoRouter is created ONCE.
  // ref.watch would cause GoRouter to be recreated on every auth change,
  // resetting navigation to initialLocation='/' and causing an infinite
  // splash-screen loop.
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      // If auth is not yet initialized, stay on splash.
      // The hard timer in SplashPage guarantees we leave within 5 seconds.
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

      if (user == null) {
        // Not signed in — allow auth pages, redirect everything else to sign-in.
        return (isLogin || isSignIn || isSignUp || isForgotPassword || isSplash)
            ? null
            : AppRoutes.signIn;
      }

      if (AuthGuard.isBlocked(user)) {
        return isBlocked ? null : AppRoutes.accountBlocked;
      }

      // Signed-in user should not see auth/splash pages.
      if (isSplash || isLogin || isSignIn || isSignUp || isBlocked) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // ── Public / Auth routes ──────────────────────────────────────────────
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

      // ── Shell: persistent bottom navigation bar ───────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: AppRouteNames.home,
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.addProduct,
            name: AppRouteNames.addProduct,
            builder: (_, __) => const AddProductPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: AppRouteNames.profile,
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.editProfile,
            name: AppRouteNames.editProfile,
            builder: (_, __) => const EditProfilePage(),
          ),
        ],
      ),

      // ── Detail / overlay routes (no bottom nav) ───────────────────────────
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

  // Path helpers
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
