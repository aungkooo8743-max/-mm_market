import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/connectivity_provider.dart';
import '../core/providers/language_provider.dart';
import '../core/services/crashlytics_service.dart';
import '../core/widgets/offline_banner.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MMMarketApp extends ConsumerWidget {
  const MMMarketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CRITICAL: watch routerNotifierProvider to keep it alive in the widget
    // tree. Without this watch, Riverpod may GC the notifier (and cancel its
    // fallback timer) between rebuilds.
    // We do NOT use the returned value here — the watching is the goal.
    ref.watch(routerNotifierProvider);

    // Read router ONCE — never watch it. Watching would recreate the router
    // on every auth change and break navigation state.
    final router = ref.read(appRouterProvider);
    final locale = ref.watch(languageProvider);

    // Sync Crashlytics user identity whenever auth state changes.
    // This ensures every crash report is linked to the correct user account.
    ref.listen(currentUserProvider, (_, user) {
      CrashlyticsService.setUserId(user?.uid);
      if (user != null) {
        CrashlyticsService.log('Auth state: signed in uid=${user.uid}');
      } else {
        CrashlyticsService.log('Auth state: signed out');
      }
    });

    // Log connectivity changes to Crashlytics for network-related crash context.
    ref.listen(isOnlineProvider, (prev, isOnline) {
      CrashlyticsService.log(
        isOnline ? 'Network: online' : 'Network: offline',
      );
      CrashlyticsService.setKey('network_online', isOnline.toString());
    });

    return OfflineBanner(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MM Market',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: router,
        // Locale support
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
