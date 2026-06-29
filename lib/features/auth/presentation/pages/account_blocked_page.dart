import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../guards/auth_guard.dart';
import '../providers/auth_providers.dart';

class AccountBlockedPage extends ConsumerWidget {
  const AccountBlockedPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final message = user == null ? 'Account unavailable.' : AuthGuard.blockedMessage(user);
    return Scaffold(
      appBar: AppBar(title: const Text('Account Restricted')),
      body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.block_outlined, size: 72),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: () => ref.read(authControllerProvider.notifier).signOut(), icon: const Icon(Icons.logout_outlined), label: const Text('Logout')),
      ]))),
    );
  }
}
