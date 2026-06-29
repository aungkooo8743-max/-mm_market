import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/auth_providers.dart';

/// Main Sign-In gateway — first screen users see.
/// Supports Email/Password, Google, Facebook, and TikTok (coming soon).
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'အီးမေးလ် လိပ်စာ ထည့်ပါ\nEmail is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'မှန်ကန်သော အီးမေးလ် ထည့်ပါ\nPlease enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'စကားဝှက် ထည့်ပါ\nPassword is required';
    }
    if (value.length < 6) {
      return 'စကားဝှက် အနည်းဆုံး ၆ လုံး ရှိရမည်\nPassword must be at least 6 characters';
    }
    return null;
  }

  // ── Social Auth Handlers ───────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    _handleAuthResult();
  }

  Future<void> _signInWithFacebook() async {
    await ref.read(authNotifierProvider.notifier).signInWithFacebook();
    if (!mounted) return;
    _handleAuthResult();
  }

  Future<void> _signInWithTikTok() async {
    await ref.read(authNotifierProvider.notifier).signInWithTikTok();
    if (!mounted) return;
    _handleAuthResult();
  }

  void _handleAuthResult() {
    final authState = ref.read(authNotifierProvider);
    authState.whenOrNull(
      error: (error, stackTrace) {
        String message;
        if (error is AppException) {
          if (error.code == 'sign-in-cancelled') return;
          if (error.code == 'tiktok-coming-soon' ||
              error.code == 'tiktok-pending-backend') {
            AppSnackbar.info(context, error.message);
            return;
          }
          if (error.code == 'facebook-not-configured') {
            AppSnackbar.error(context, error.message);
            return;
          }
          message = error.message;
        } else {
          message = 'Sign-In မအောင်မြင်ပါ\nSign-In failed. Please try again.';
        }
        AppSnackbar.error(context, message);
      },
      data: (user) {
        if (user != null) context.go(AppRoutes.home);
      },
    );
  }

  // ── Email Submit ───────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await ref
        .read(authNotifierProvider.notifier)
        .signInWithEmail(email, password);

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    authState.whenOrNull(
      error: (error, stackTrace) {
        String message;
        if (error is AppException) {
          debugPrint('[SignIn] error code="${error.code}" message="${error.message}"');
          message = error.message;
        } else {
          debugPrint('[SignIn] Unexpected error: $error\n$stackTrace');
          message = 'မမျှော်လင့်သော အမှားဖြစ်သည်\nAn unexpected error occurred. Please try again.';
        }
        AppSnackbar.error(context, message);
      },
      data: (user) {
        if (user != null) context.go(AppRoutes.home);
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ဝင်ရောက်ရန် / Sign In'),
        centerTitle: true,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    // Myanmar mascot greeting illustration
                    SizedBox(
                      height: 140,
                      child: Image.asset(
                        'assets/images/mascot_greeting.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.storefront_rounded,
                          size: 72,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ကြိုဆိုပါသည်',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome Back',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MM Market အကောင့်သို့ ဝင်ရောက်ပါ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // ── Social Sign-In Buttons ──────────────────────────────
                    _GoogleSignInButton(
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _signInWithGoogle,
                    ),
                    const SizedBox(height: 12),
                    // Facebook Login — configured but hidden from UI per v3.3.4 spec
                    // App ID 971595999048926 is set in strings.xml
                    // Uncomment to re-enable:
                    // _FacebookSignInButton(
                    //   isLoading: isLoading,
                    //   onPressed: isLoading ? null : _signInWithFacebook,
                    // ),
                    // const SizedBox(height: 12),
                    // TikTok Login — Coming Soon (no official Flutter SDK)
                    // _TikTokSignInButton(
                    //   isLoading: isLoading,
                    //   onPressed: isLoading ? null : _signInWithTikTok,
                    // ),
                    const SizedBox(height: 24),

                    // ── Divider ─────────────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'သို့မဟုတ် အီးမေးလ်ဖြင့် / or with Email',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Email Field ─────────────────────────────────────────
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enabled: !isLoading,
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'အီးမေးလ် / Email',
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Password Field ──────────────────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => isLoading ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: 'စကားဝှက် / Password',
                        hintText: 'အနည်းဆုံး ၆ လုံး / At least 6 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'စကားဝှက် ပြရန် / Show password'
                              : 'စကားဝှက် ဝှက်ရန် / Hide password',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Forgot Password Link ────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.push(AppRoutes.forgotPassword),
                        child: const Text('စကားဝှက် မေ့သွားသလား? / Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Sign In Button ──────────────────────────────────────
                    AppPrimaryButton(
                      label: 'ဝင်ရောက်ရန် / Sign In',
                      icon: Icons.login_rounded,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _submit,
                    ),
                    const SizedBox(height: 20),

                    // ── Divider ─────────────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'သို့မဟုတ် / or',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Phone Login Link ────────────────────────────────────
                    OutlinedButton.icon(
                      icon: const Icon(Icons.phone_outlined),
                      label: const Text('ဖုန်းနံပါတ်ဖြင့် ဝင်ရောက်ရန် / Sign in with Phone'),
                      onPressed: isLoading ? null : () => context.go(AppRoutes.login),
                    ),
                    const SizedBox(height: 24),

                    // ── Create Account Button ────────────────────────────
                    Column(
                      children: [
                        Text(
                          'အကောင့် မရှိသေးဘူးလား? / Don\'t have an account?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                isLoading ? null : () => context.push(AppRoutes.signUp),
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text(
                              'အကောင့် ဖွင့်ရန် / Create Account',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared Social Button Builder ─────────────────────────────────────────────

/// Builds a social auth button that auto-fits bilingual text without clipping.
Widget _buildSocialButton({
  required BuildContext context,
  required bool isLoading,
  required VoidCallback? onPressed,
  required Widget logo,
  required String myanmarText,
  required String englishText,
  required Color backgroundColor,
  required Color textColor,
  Color? borderColor,
  double elevation = 2,
}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: elevation,
      shadowColor: Colors.black26,
      side: borderColor != null ? BorderSide(color: borderColor) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    child: isLoading
        ? SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: textColor,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              logo,
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myanmarText,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      englishText,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
  );
}

// ── Google Sign-In Button ────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _buildSocialButton(
      context: context,
      isLoading: isLoading,
      onPressed: onPressed,
      logo: SizedBox(
        width: 24, height: 24,
        child: CustomPaint(painter: _GoogleLogoPainter()),
      ),
      myanmarText: 'Google ဖြင့် ဆက်လုပ်ရန်',
      englishText: 'Continue with Google',
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      borderColor: const Color(0xFFDDDDDD),
    );
  }
}

// ── Facebook Sign-In Button ──────────────────────────────────────────────────

class _FacebookSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _FacebookSignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _buildSocialButton(
      context: context,
      isLoading: isLoading,
      onPressed: onPressed,
      logo: Container(
        width: 24, height: 24,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'f',
            style: TextStyle(
              color: Color(0xFF1877F2),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.2,
            ),
          ),
        ),
      ),
      myanmarText: 'Facebook ဖြင့် ဆက်လုပ်ရန်',
      englishText: 'Continue with Facebook',
      backgroundColor: const Color(0xFF1877F2),
      textColor: Colors.white,
    );
  }
}

// ── TikTok Sign-In Button ────────────────────────────────────────────────────

class _TikTokSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _TikTokSignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _buildSocialButton(
      context: context,
      isLoading: isLoading,
      onPressed: onPressed,
      logo: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.black,
        ),
        child: const Center(
          child: Text(
            '♪',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.0,
            ),
          ),
        ),
      ),
      myanmarText: 'TikTok ဖြင့် ဆက်လုပ်ရန်',
      englishText: 'Continue with TikTok',
      backgroundColor: const Color(0xFF010101),
      textColor: Colors.white,
    );
  }
}

// ── Google Logo Painter ──────────────────────────────────────────────────────

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const colors = [
      Color(0xFF4285F4),
      Color(0xFF34A853),
      Color(0xFFFBBC05),
      Color(0xFFEA4335),
    ];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.28;

    paint.color = colors[0];
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.72), -0.3, 1.6, false, paint);
    paint.color = colors[1];
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.72), 1.3, 1.6, false, paint);
    paint.color = colors[2];
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.72), 2.9, 0.8, false, paint);
    paint.color = colors[3];
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.72), 3.7, 1.0, false, paint);

    final barPaint = Paint()
      ..color = colors[0]
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - size.height * 0.14, radius * 0.72, size.height * 0.28),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
