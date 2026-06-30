import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'core/di/injection.dart';
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
      // In release builds, all Flutter framework errors and unhandled Dart
      // exceptions are automatically forwarded to the Firebase console.
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
        sl<LoggerService>().info('MM Market v3.3.7+24 initialized');
      }

      // Log app startup breadcrumb to Crashlytics (release only)
      if (!kDebugMode) {
        crashlytics.log('MM Market v3.3.7+24 app started');
      }

      runApp(builder());
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
