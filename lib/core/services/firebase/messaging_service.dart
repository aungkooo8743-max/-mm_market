import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MessagingService
//
// Wraps FirebaseMessaging and flutter_local_notifications to provide:
//  1. Permission request
//  2. FCM token access
//  3. Foreground notification display (onMessage)
//  4. Notification-tap deep-link routing (onMessageOpenedApp + getInitialMessage)
// ─────────────────────────────────────────────────────────────────────────────

/// Callback type: receives a notification payload and navigates to the
/// appropriate screen.  The caller (bootstrap / app) wires this up.
typedef NotificationTapCallback = void Function(RemoteMessage message);

class MessagingService {
  final FirebaseMessaging messaging;

  // flutter_local_notifications is used to show heads-up banners while the
  // app is in the foreground (FCM does not show UI in foreground by default).
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'mm_market_high_importance';
  static const _channelName = 'MM Market Notifications';
  static const _channelDesc = 'Price drops, new products, and chat messages';

  const MessagingService(this.messaging);

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<NotificationSettings> requestPermission() =>
      messaging.requestPermission(alert: true, badge: true, sound: true);

  Future<String?> getToken() => messaging.getToken();

  Stream<String> onTokenRefresh() => messaging.onTokenRefresh;

  /// Initialise local-notification plugin and set up all FCM handlers.
  ///
  /// [onTap] is called whenever the user taps a notification to open the app.
  /// The caller should use the [RemoteMessage.data] map to navigate:
  ///   - data['type'] == 'product'  → navigate to /products/{data['id']}
  ///   - data['type'] == 'chat'     → navigate to /chats/{data['id']}
  ///   - data['type'] == 'promo'    → navigate to /notifications
  Future<void> init({NotificationTapCallback? onTap}) async {
    await _initLocalNotifications(onTap: onTap);
    _listenForeground();
    _listenTap(onTap);
    await _handleInitialMessage(onTap);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _initLocalNotifications({
    NotificationTapCallback? onTap,
  }) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (kDebugMode) {
          debugPrint('[FCM LOCAL TAP] payload=${details.payload}');
        }
      },
    );

    // Create the high-importance Android notification channel.
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show a local notification banner when a push arrives in the foreground.
  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      if (kDebugMode) {
        debugPrint(
            '[FCM FG] title=${notification.title} body=${notification.body}');
      }

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  /// Handle notification tap when the app is in the background (not terminated).
  void _listenTap(NotificationTapCallback? onTap) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('[FCM TAP BG] data=${message.data}');
      }
      onTap?.call(message);
    });
  }

  /// Handle notification tap when the app was terminated (cold start).
  Future<void> _handleInitialMessage(NotificationTapCallback? onTap) async {
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      if (kDebugMode) {
        debugPrint('[FCM TAP COLD] data=${initial.data}');
      }
      // Delay slightly so the widget tree is ready before navigating.
      Future.delayed(const Duration(milliseconds: 500), () {
        onTap?.call(initial);
      });
    }
  }
}
