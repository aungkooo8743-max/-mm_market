import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A screen that allows users to request a Firebase password-reset email.
///
/// Flow:
///   1. User enters their registered email address.
///   2. [FirebaseAuth.sendPasswordResetEmail] is called.
///   3. On success a confirmation message is shown and the user can go back.
///   4. On failure a user-friendly error snackbar is displayed.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'အီးမေးလ် ထည့်ပါ\nPlease enter your email address';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'မှန်ကန်သော အီးမေးလ် ထည့်ပါ\nPlease enter a valid email address';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(_mapError(e.code));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('မမျောလင့်သော အမှားဖြစ်သည်\nAn unexpected error occurred. Please try again.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'ခု အီးမေးလ်ဖြင့် အကောင့် မရှိပါ\nNo account found for this email address';
      case 'invalid-email':
        return 'အီးမေးလ် မှန်ကန်မှုပါ\nThe email address is not valid';
      case 'too-many-requests':
        return 'ကြိုကြို ကြိုးမားသည့်အကြိုး ခဏန့်စားပါ\nToo many requests. Please wait a moment and try again';
      case 'network-request-failed':
        return 'အင်တာနက်လပ်မရှိပါ\nNo internet connection. Please check your network';
      default:
        return 'အီးမေးလ် ပော့ချရန် မအောင့်ပါ ($code)\nFailed to send reset email. Please try again';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('စကားဝှက် မေ့သွား / Forgot Password'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent
              ? _buildSuccessView(theme, colorScheme)
              : _buildFormView(theme, colorScheme),
        ),
      ),
    );
  }

  Widget _buildSuccessView(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Icon(Icons.mark_email_read_outlined, size: 80, color: colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          'အီးမေးလ် စစ်သေား / Check Your Email',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'စကားဝှက် ပြန်လည်မည့် လင့်းချရန် အီးမေးလ် ပော့ချပါး\nWe\'ve sent a password reset link to:\n${_emailController.text.trim()}',
          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'အီးမေးလ် လက်မှိပါ\nPlease check your inbox and follow the link to reset your password.',
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('ဝင်ရောက်သေား ပြန်သွား / Back to Sign In'),
            onPressed: () => context.pop(),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          child: const Text('အီးမေးလ် ထပ်ပော့ချရန် / Resend email'),
        ),
      ],
    );
  }

  Widget _buildFormView(ThemeData theme, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Icon(Icons.lock_reset_rounded, size: 64, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'စကားဝှက် ပြန်လည်မည့် / Reset Your Password',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'အကောင့်ဖြင့် အီးမေးလ် ထည့်ပါး\nEnter the email address associated with your account and we\'ll send you a link to reset your password.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enabled: !_isLoading,
            validator: _validateEmail,
            onFieldSubmitted: (_) => _isLoading ? null : _submit(),
            decoration: const InputDecoration(
              labelText: 'အီးမေးလ် / Email Address',
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_isLoading ? 'ပော့ချနေသည်... / Sending...' : 'ပော့ချရန် / Send Reset Link'),
            onPressed: _isLoading ? null : _submit,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('ဝင်ရောက်သေား ပြန်သွား / Back to Sign In'),
          ),
        ],
      ),
    );
  }
}
