import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MM Market — Crashlytics Service  v3.3.6
//
// Layer 5: Live Monitoring Readiness
//
// New in v3.3.6:
//  • [recordUiWarning]  — silently captures minor UI anomalies (overflow,
//    null-image, empty-state) as non-fatal events grouped by [tag].
//  • [setScreen]        — tracks the current screen name so every crash
//    report shows WHERE in the app it happened.
//  • [markEvent]        — lightweight performance breadcrumb (e.g. "product
//    list loaded in 340 ms") visible in the Crashlytics timeline.
//  • [recordNetworkError] — captures HTTP/timeout errors with status code.
//  • All methods remain no-ops in debug mode to keep the dashboard clean.
// ─────────────────────────────────────────────────────────────────────────────

/// Central Crashlytics helper used throughout the app.
///
/// Usage:
/// ```dart
/// CrashlyticsService.recordError(e, st, reason: 'Firestore fetch failed');
/// CrashlyticsService.setUserId(uid);
/// CrashlyticsService.log('Product upload started');
/// CrashlyticsService.setScreen('ProductDetailPage');
/// CrashlyticsService.recordUiWarning('ImageOverflow', details: 'card #42');
/// ```
///
/// All methods are **no-ops in debug mode** so the Crashlytics dashboard
/// remains clean during development.
class CrashlyticsService {
  CrashlyticsService._();

  static FirebaseCrashlytics get _c => FirebaseCrashlytics.instance;

  // ── Identity ──────────────────────────────────────────────────────────────

  /// Set the current user ID so crashes are linked to a specific account.
  static Future<void> setUserId(String? uid) async {
    if (kDebugMode) return;
    await _c.setUserIdentifier(uid ?? '');
  }

  // ── Screen tracking ───────────────────────────────────────────────────────

  /// Record the currently visible screen name.
  ///
  /// Call this in each page's [initState] or [didChangeDependencies].
  /// The value appears as a custom key `current_screen` in crash reports,
  /// making it immediately clear which page the user was on when a crash
  /// or non-fatal event occurred.
  static Future<void> setScreen(String screenName) async {
    if (kDebugMode) {
      debugPrint('[Crashlytics] Screen: $screenName');
      return;
    }
    await _c.setCustomKey('current_screen', screenName);
    _c.log('Screen: $screenName');
  }

  // ── Logging ───────────────────────────────────────────────────────────────

  /// Add a breadcrumb log visible in the Crashlytics crash report.
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[Crashlytics] $message');
      return;
    }
    _c.log(message);
  }

  /// Lightweight performance/timing breadcrumb.
  ///
  /// Example: `CrashlyticsService.markEvent('productListLoaded', durationMs: 340);`
  static void markEvent(String name, {int? durationMs}) {
    final msg = durationMs != null ? '$name (${durationMs}ms)' : name;
    log('Event: $msg');
  }

  /// Attach a custom key-value pair to all subsequent crash reports.
  static Future<void> setKey(String key, Object value) async {
    if (kDebugMode) return;
    await _c.setCustomKey(key, value);
  }

  // ── Error recording ───────────────────────────────────────────────────────

  /// Record a **non-fatal** error (e.g. a caught exception that was handled).
  ///
  /// [reason] is a short human-readable label shown in the Crashlytics UI.
  /// [context] is an optional map of extra key-value pairs attached to this
  /// specific error record.
  static Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, Object>? context,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[Crashlytics] ${fatal ? "FATAL" : "non-fatal"} '
        '${reason != null ? "[$reason] " : ""}$error',
      );
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
      return;
    }

    // Attach extra context keys before recording
    if (context != null) {
      for (final entry in context.entries) {
        await _c.setCustomKey(entry.key, entry.value);
      }
    }

    await _c.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
      printDetails: false,
    );
  }

  // ── Specialised recorders ─────────────────────────────────────────────────

  /// Convenience wrapper for Firestore-related errors.
  static Future<void> recordFirestoreError(
    Object error,
    StackTrace? stackTrace, {
    required String operation,
    String? collection,
    String? docId,
  }) =>
      recordError(
        error,
        stackTrace,
        reason: 'Firestore: $operation',
        context: {
          'firestore_operation': operation,
          if (collection != null) 'firestore_collection': collection,
          if (docId != null) 'firestore_doc_id': docId,
        },
      );

  /// Convenience wrapper for Firebase Storage-related errors.
  static Future<void> recordStorageError(
    Object error,
    StackTrace? stackTrace, {
    required String operation,
    String? storagePath,
  }) =>
      recordError(
        error,
        stackTrace,
        reason: 'Storage: $operation',
        context: {
          'storage_operation': operation,
          if (storagePath != null) 'storage_path': storagePath,
        },
      );

  /// Convenience wrapper for Auth-related errors.
  static Future<void> recordAuthError(
    Object error,
    StackTrace? stackTrace, {
    required String operation,
  }) =>
      recordError(
        error,
        stackTrace,
        reason: 'Auth: $operation',
        context: {'auth_operation': operation},
      );

  /// Convenience wrapper for network/HTTP errors.
  ///
  /// Use for REST calls, FCM, or any HTTP-layer failure.
  static Future<void> recordNetworkError(
    Object error,
    StackTrace? stackTrace, {
    required String url,
    int? statusCode,
  }) =>
      recordError(
        error,
        stackTrace,
        reason: 'Network: ${statusCode ?? "timeout"}',
        context: {
          'network_url': url.length > 120 ? url.substring(0, 120) : url,
          if (statusCode != null) 'http_status': statusCode,
        },
      );

  // ── Test crash (QA / staging only) ─────────────────────────────────────────

  /// Force a test crash to verify Crashlytics is wired correctly.
  ///
  /// **IMPORTANT:** Call this only from a hidden debug/staging menu.
  /// Remove or gate behind a `kDebugMode || kProfileMode` check before
  /// promoting to production track.
  ///
  /// After calling, open Firebase Console → Crashlytics and confirm
  /// the stack trace appears within ~60 seconds.
  ///
  /// Usage (staging settings screen):
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: CrashlyticsService.forceCrash,
  ///   child: const Text('Force Test Crash'),
  /// )
  /// ```
  static Future<void> forceCrash() async {
    // Log a breadcrumb so the crash report is easy to identify
    _c.log('MM Market — intentional test crash triggered from staging menu');
    await _c.setCustomKey('crash_type', 'intentional_test');
    await _c.setCustomKey('crash_version', '3.3.6');
    // This call throws a fatal exception that Crashlytics intercepts
    FirebaseCrashlytics.instance.crash();
  }

  // ── UI warning recorder (Layer 5) ─────────────────────────────────────────

  /// Silently record a minor UI anomaly as a **non-fatal** Crashlytics event.
  ///
  /// This is the Layer 5 "live monitoring" hook.  It groups related warnings
  /// under a [tag] so you can track them as a single issue in the Firebase
  /// Console (e.g. "ImageOverflow", "NullCoverImage", "EmptyProductList").
  ///
  /// The event is recorded silently — it never shows anything to the user.
  ///
  /// Example:
  /// ```dart
  /// CrashlyticsService.recordUiWarning(
  ///   'NullCoverImage',
  ///   details: 'productId: $id',
  /// );
  /// ```
  static Future<void> recordUiWarning(
    String tag, {
    String? details,
    String? screen,
  }) =>
      recordError(
        Exception('UI Warning: $tag'),
        null,
        reason: 'UI/$tag',
        context: {
          'ui_warning_tag': tag,
          if (details != null) 'ui_warning_details': details,
          if (screen != null) 'ui_warning_screen': screen,
        },
      );
}
