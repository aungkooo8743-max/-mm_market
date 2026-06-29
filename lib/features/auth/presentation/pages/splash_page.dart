// ─────────────────────────────────────────────────────────────────────────────
// splash_page.dart  —  MM Market  v3.3.7+22
//
// FIXES:
//   1. RouterNotifier pattern: context.go() is no longer blocked by the
//      router redirect guard (which was stuck on AsyncLoading forever).
//   2. 5-second hard timer guarantees exit from splash regardless of Firebase.
//   3. Debug overlay (kDebugMode only) shows startup diagnostics on-screen.
//   4. Logo uses FittedBox + clamp — no stretching on any screen size.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/auth_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  // ── Navigation guard ───────────────────────────────────────────────────────
  bool _navigated = false;
  Timer? _hardTimer;

  // ── Debug diagnostics ──────────────────────────────────────────────────────
  final List<String> _logs = [];

  void _log(String msg) {
    debugPrint('[SplashPage] $msg');
    if (kDebugMode && mounted) {
      setState(() => _logs.add(msg));
    }
  }

  @override
  void initState() {
    super.initState();

    // Entrance animation
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();

    _log('Firebase initialized ✓');

    // ── Hard timeout (5 seconds) ───────────────────────────────────────────
    _hardTimer = Timer(const Duration(seconds: 5), () {
      _log('⏱ Hard timeout → sign-in');
      _navigate(toHome: false, reason: 'timeout');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthState());
  }

  void _checkAuthState() {
    if (!mounted || _navigated) return;
    final authAsync = ref.read(authStateChangesProvider);
    _log('Auth state check: ${authAsync.runtimeType}');
    authAsync.when(
      data: (user) {
        _log('User: ${user != null ? "uid=${user.uid}" : "null → sign-in"}');
        _navigate(toHome: user != null, reason: 'auth_resolved');
      },
      error: (e, _) {
        _log('Auth error: $e');
        _navigate(toHome: false, reason: 'auth_error');
      },
      loading: () => _log('Auth loading — waiting for stream…'),
    );
  }

  void _navigate({required bool toHome, required String reason}) {
    if (_navigated || !mounted) return;
    _navigated = true;
    _hardTimer?.cancel();
    final dest = toHome ? AppRoutes.home : AppRoutes.signIn;
    _log('→ Redirect: $dest (reason: $reason)');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(dest);
    });
  }

  @override
  void dispose() {
    _hardTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes — fires whenever the stream emits.
    ref.listen<AsyncValue<dynamic>>(authStateChangesProvider, (_, next) {
      next.when(
        data: (user) {
          _log('Stream data: ${user != null ? "uid=${user.uid}" : "null"}');
          _navigate(toHome: user != null, reason: 'stream_data');
        },
        error: (e, _) {
          _log('Stream error: $e');
          _navigate(toHome: false, reason: 'stream_error');
        },
        loading: () {},
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main splash content ──────────────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: _buildLogo(context),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _fade,
                    child: Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeTransition(
                    opacity: _fade,
                    child: const Text(
                      "Myanmar's Online Marketplace",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  FadeTransition(
                    opacity: _fade,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white54),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Debug overlay (debug builds only) ───────────────────────────
            if (kDebugMode)
              Positioned(
                left: 12,
                right: 12,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.80),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🔍 DEBUG — Startup Diagnostics',
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_logs.isEmpty)
                        const Text(
                          'Waiting…',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        )
                      else
                        ..._logs.map(
                          (l) => Text(
                            l,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // 20% of screen width, hard-capped between 72 and 100 logical pixels.
    final logoSize = (screenW * 0.20).clamp(72.0, 100.0);
    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Image.asset(
          'assets/images/mm_logo_transparent.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _FallbackLogo(size: logoSize),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fallback logo drawn with CustomPaint — shown when asset is unavailable.
// ─────────────────────────────────────────────────────────────────────────────
class _FallbackLogo extends StatelessWidget {
  final double size;
  const _FallbackLogo({required this.size});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _BagPainter()),
      );
}

class _BagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const orange = Color(0xFFFF5722);

    final handlePaint = Paint()
      ..color = orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.28, h * 0.06, w * 0.44, h * 0.28),
      3.14159,
      3.14159,
      false,
      handlePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, h * 0.30, w * 0.80, h * 0.62),
        Radius.circular(w * 0.10),
      ),
      Paint()..color = orange,
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: 'MM',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, h * 0.48));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
