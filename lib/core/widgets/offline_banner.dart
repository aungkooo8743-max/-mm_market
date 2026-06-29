import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MM Market — Offline Banner Widget  v3.3.6
//
// Usage — wrap any Scaffold body or top-level widget:
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       body: OfflineBanner(
//         child: YourActualContent(),
//       ),
//     );
//   }
//
// The banner slides in from the top when the device goes offline and
// slides out when connectivity is restored.  It never blocks the content
// beneath it — the user can keep browsing cached data.
// ─────────────────────────────────────────────────────────────────────────────

/// A non-blocking animated banner that appears at the top of the screen
/// whenever the device loses internet connectivity.
class OfflineBanner extends ConsumerStatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleConnectivityChange(bool isOnline) {
    if (!isOnline && !_wasOffline) {
      _ctrl.forward();
      _wasOffline = true;
    } else if (isOnline && _wasOffline) {
      // Brief delay so the "Back online" state is visible before hiding.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _ctrl.reverse();
        _wasOffline = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    _handleConnectivityChange(isOnline);

    return Stack(
      children: [
        // ── Main content ───────────────────────────────────────────────────
        widget.child,

        // ── Offline banner ─────────────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _OfflineBannerContent(isOnline: isOnline),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfflineBannerContent extends StatelessWidget {
  final bool isOnline;
  const _OfflineBannerContent({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final isRestored = isOnline;

    return Material(
      elevation: 4,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: isRestored
            ? const Color(0xFF2E7D32) // Green — back online
            : const Color(0xFFC62828), // Red — offline
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 6,
          bottom: 10,
          left: 16,
          right: 16,
        ),
        child: Row(
          children: [
            Icon(
              isRestored ? Icons.wifi : Icons.wifi_off_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isRestored ? 'ချိတ်ဆက်မှု ပြန်ရပြီ' : 'အင်တာနက် မချိတ်ဆက်နိုင်ပါ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (!isRestored)
                    const Text(
                      'Cache ထဲမှ ကြည့်နိုင်ပါသည် · No Connection Available',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convenience wrapper that adds the [OfflineBanner] to any [Scaffold] body.
///
/// Example:
/// ```dart
/// body: withOfflineBanner(child: MyContent()),
/// ```
Widget withOfflineBanner({required Widget child}) =>
    OfflineBanner(child: child);
