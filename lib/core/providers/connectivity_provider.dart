import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/injection.dart';
import '../services/connectivity_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MM Market — Connectivity Providers  v3.3.6
//
// Exposes real-time network status as Riverpod streams so any widget can
// reactively respond to online/offline transitions.
// ─────────────────────────────────────────────────────────────────────────────

/// Emits [true] when the device has a network connection, [false] otherwise.
/// Backed by [ConnectivityService.watchOnlineStatus].
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return sl<ConnectivityService>().watchOnlineStatus();
});

/// Synchronous snapshot of the current online status.
/// Defaults to [true] while the stream is loading (avoids false offline banners
/// on app start before the first connectivity event arrives).
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStreamProvider).when(
        data: (online) => online,
        loading: () => true,   // Optimistic: assume online until proven offline
        error: (_, __) => true, // On error, don't block the UI
      );
});
