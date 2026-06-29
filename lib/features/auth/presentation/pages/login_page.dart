import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  bool otpMode = false;

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  /// Normalize Myanmar phone number to E.164 format (+959XXXXXXXX)
  /// Accepts: 09XXXXXXXX, 9XXXXXXXX, 959XXXXXXXX, +959XXXXXXXX
  String get phone {
    final raw = phoneController.text.trim();
    if (raw.startsWith('+959')) return raw;
    if (raw.startsWith('+')) return raw;
    // Remove all non-digit characters
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('09')) {
      // 09XXXXXXXX → +959XXXXXXXX (strip leading 0, add +959)
      return '+959${digits.substring(2)}';
    }
    if (digits.startsWith('959')) {
      // 959XXXXXXXX → +959XXXXXXXX
      return '+$digits';
    }
    if (digits.startsWith('9')) {
      // 9XXXXXXXX → +959XXXXXXXX (Myanmar mobile starts with 9)
      return '+959${digits.substring(1)}';
    }
    return '${AppConstants.defaultCountryCode}$digits';
  }

  Future<void> submit() async {
    final ctrl = ref.read(authControllerProvider.notifier);
    if (!otpMode) {
      final normalizedPhone = phone;
      debugPrint('[LoginPage] Sending OTP to: $normalizedPhone');
      await ctrl.sendOtp(normalizedPhone);
      if (!mounted) return;
      final state = ref.read(authControllerProvider);
      if (state.errorMessage != null) return AppSnackbar.error(context, state.errorMessage!);
      setState(() => otpMode = true);
      return;
    }
    await ctrl.verifyOtp(
      verificationId: ref.read(authControllerProvider).verificationId ?? '',
      smsCode: otpController.text.trim(),
    );
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.errorMessage != null) return AppSnackbar.error(context, state.errorMessage!);
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ဖုန်းနံပါတ်ဖြင့် ဝင်ရောက်ရန်\nLogin with Phone'),
        centerTitle: true,
      ),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.phone_android, size: 40, color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          otpMode
              ? 'OTP ကုဒ် ထည့်ပါ\nEnter OTP Code'
              : 'ဖုန်းနံပါတ် ထည့်ပါ\nEnter Phone Number',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (!otpMode) ...[
          const SizedBox(height: 8),
          Text(
            'ဥပမာ: 09xxxxxxxx\nExample: 09xxxxxxxx',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: phoneController,
          enabled: !otpMode,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'ဖုန်းနံပါတ် / Phone Number',
            hintText: '09xxxxxxxx',
            prefixIcon: const Icon(Icons.phone),
            border: const OutlineInputBorder(),
            helperText: '+959 အော်တိုထည့်ပေးမည် / +959 auto-added',
          ),
        ),
        if (otpMode) ...[
          const SizedBox(height: 16),
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'OTP ကုဒ် / OTP Code',
              hintText: '6 လုံး ထည့်ပါ / Enter 6 digits',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: otpMode ? 'OTP အတည်ပြုရန် / Verify OTP' : 'OTP ပို့ရန် / Send OTP',
          isLoading: state.isLoading,
          onPressed: submit,
        ),
        if (otpMode) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: state.isLoading ? null : () => setState(() {
              otpMode = false;
              otpController.clear();
            }),
            child: const Text('ဖုန်းနံပါတ် ပြန်ပြင်ရန် / Change Phone Number'),
          ),
        ],
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.email_outlined),
          label: const Text('အီးမေးလ်ဖြင့် ဝင်ရောက်ရန် / Sign in with Email'),
          onPressed: state.isLoading ? null : () => context.go(AppRoutes.signIn),
        ),
      ]),
    );
  }
}
