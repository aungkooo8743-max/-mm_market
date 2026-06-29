import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'core/di/injection.dart';
import 'core/services/firebase/messaging_service.dart';
import 'core/services/logger_service.dart';
import 'firebase_options.dart';

typedef AppBuilder = Widget Function();

Future<void> bootstrap(AppBuilder builder) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // ── Firebase Core ────────────────────────────────────────────────────
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // ── Firebase Crashlytics ─────────────────────────────────────────────
      // Disable Crashlytics in debug mode to avoid polluting the dashboard.
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Forward Flutter framework errors (widget build failures, etc.)
      FlutterError.onError = (errorDetails) {
        if (kDebugMode) {
          FlutterError.presentError(errorDetails);
        } else {
          crashlytics.recordFlutterFatalError(errorDetails);
        }
      };

      // Forward async errors that escape the zone (platform channel errors, etc.)
      PlatformDispatcher.instance.onError = (error, stack) {
        if (!kDebugMode) {
          crashlytics.recordError(error, stack, fatal: true);
        }
        return true;
      };

      // ── App DI ───────────────────────────────────────────────────────────
      await configureDependencies();

      if (sl.isRegistered<LoggerService>()) {
        sl<LoggerService>().info('MM Market v3.3.7+19 initialized');
      }

      // Log app startup breadcrumb to Crashlytics (release only)
      if (!kDebugMode) {
        crashlytics.log('MM Market v3.3.7+19 app started');
      }

      // ── CRITICAL FIX (v3.3.7+19): runApp BEFORE FCM init ────────────────
      // FCM init (getInitialMessage, local notifications setup) can hang
      // on some devices, blocking the Flutter first frame and causing the
      // Android native launch splash to stay forever.
      //
      // Solution: call runApp() first so Flutter renders its first frame
      // immediately, then initialise FCM in the background with a 3-second
      // timeout so a slow/failing FCM setup never blocks the UI.
      runApp(builder());

      // ── FCM Foreground + Tap Handlers (non-blocking) ─────────────────────
      // MessagingService.init() sets up:
      //   • flutter_local_notifications foreground banner display
      //   • onMessageOpenedApp (background-tap deep-link)
      //   • getInitialMessage (cold-start tap deep-link)
      unawaited(
        sl<MessagingService>()
            .init(
              onTap: (message) {
                if (kDebugMode) {
                  debugPrint(
                      '[FCM TAP] type=${message.data["type"]} id=${message.data["id"]}');
                }
              },
            )
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                debugPrint('[FCM init] timeout after 3s — skipping');
              },
            )
            .catchError((Object e, StackTrace st) {
              debugPrint('[FCM init] skipped due to error: $e');
            }),
      );
    },
    // Zone-level error handler — catches all unhandled async errors
    (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Zone error: $error');
        debugPrintStack(stackTrace: stackTrace);
      } else {
        FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
      }
    },
  );
}
