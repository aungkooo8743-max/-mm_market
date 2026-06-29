
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'bootstrap.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FCM Background Message Handler  (Chat Resilience — Section A.3)
//
// Receives push notifications when the app is terminated or backgrounded.
// Must be a top-level function annotated @pragma('vm:entry-point') so the
// Dart VM can locate it from the native side without tree-shaking it away.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the plugin before calling this.
  // No UI work here — Firestore offline persistence queues any writes and
  // syncs them when the app returns to the foreground.
  assert(() {
    // ignore: avoid_print
    print('[FCM BG] id=\${message.messageId} '
        'title=\${message.notification?.title} '
        'data=\${message.data}');
    return true;
  }());
}

Future<void> main() async {
  // Register the FCM background handler BEFORE Firebase.initializeApp().
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await bootstrap(
    () => const ProviderScope(
      child: MMMarketApp(),
    ),
  );
}
