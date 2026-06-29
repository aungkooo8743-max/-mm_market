import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../providers/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(currentUserProfileProvider);
    final locale = ref.watch(languageProvider);
    final isMy = locale.languageCode == 'my';
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isMy ? 'ကျွန်တော်၏ ပရိုဖိုင်\nMy Profile' : 'My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.editProfile),
            icon: const Icon(Icons.edit),
            tooltip: isMy ? 'ပြင်ဆင်ရန်' : 'Edit',
          ),
        ],
      ),
      body: async.when(
        loading: () => const AppLoadingView(),
        error: (e, _) => AppEmptyView(
          title: isMy ? 'အမှားဖြစ်ပွားသည်' : 'Error',
          message: isMy ? 'ထပ်မံကြိုးစားပါ' : 'Please try again',
        ),
        data: (p) => p == null
            ? AppEmptyView(
                title: isMy ? 'ပရိုဖိုင် မရှိပါ' : 'No Profile',
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Avatar ──────────────────────────────────────────
                  Center(
                    child: CircleAvatar(
                      radius: 52,
                      child: p.photoUrl == null
                          ? const Icon(Icons.person, size: 52)
                          : ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: p.photoUrl!,
                                width: 104,
                                height: 104,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.person, size: 52),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      p.nameOrPhone,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  // Online indicator
                  if (p.isOnline)
                    Center(
                      child: Chip(
                        avatar: const Icon(Icons.circle,
                            size: 10, color: Colors.green),
                        label: Text(
                          isMy ? 'အွန်လိုင်း' : 'Online',
                          style: const TextStyle(fontSize: 12),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Metadata card ────────────────────────────────────
                  Card(
                    child: Column(
                      children: [
                        // Phone
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: Text(isMy ? 'ဖုန်းနံပါတ်' : 'Phone'),
                          trailing: Text(p.phone),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        // Joined date
                        ListTile(
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: Text(isMy ? 'ဝင်ရောက်သည့်နေ့' : 'Joined'),
                          trailing: Text(
                            DateFormat('dd MMM yyyy').format(p.createdAt),
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        // Trust score
                        ListTile(
                          leading: const Icon(Icons.verified_user_outlined),
                          title: Text(
                              isMy ? 'ယုံကြည်မှုမှတ်' : 'Trust Score'),
                          trailing: Text('${p.trustScore}'),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        // Rating
                        ListTile(
                          leading: const Icon(Icons.star_outline),
                          title: Text(
                              isMy ? 'အဆင့်သတ်မှတ်ချက်' : 'Rating'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(p.ratingAverage.toStringAsFixed(1)),
                              Text(
                                ' (${p.reviewCount})',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Products count card ──────────────────────────────
                  if (currentUser != null)
                    _ProductsCountCard(
                        userId: currentUser.uid, isMy: isMy),
                  const SizedBox(height: 12),

                  // ── Location card ────────────────────────────────────
                  if (p.city != null || p.township != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(isMy ? 'တည်နေရာ' : 'Location'),
                        subtitle: Text(
                          [p.township, p.city]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(', '),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Language switcher ────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMy
                                ? 'ဘာသာစကား ရွေးချယ်ရန်\nLanguage Settings'
                                : 'Language Settings',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _LangButton(
                                  label: 'မြန်မာ',
                                  sublabel: 'Myanmar',
                                  isSelected: isMy,
                                  onTap: () => ref
                                      .read(languageProvider.notifier)
                                      .setLanguage('my'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _LangButton(
                                  label: 'English',
                                  sublabel: 'အင်္ဂလိပ်',
                                  isSelected: !isMy,
                                  onTap: () => ref
                                      .read(languageProvider.notifier)
                                      .setLanguage('en'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Logout button ────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout),
                    label: Text(
                        isMy ? 'ထွက်ရန် / Logout' : 'Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Products count card ──────────────────────────────────────────────────────
class _ProductsCountCard extends ConsumerWidget {
  final String userId;
  final bool isMy;
  const _ProductsCountCard({required this.userId, required this.isMy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(sellerProductsProvider(userId));
    return Card(
      child: ListTile(
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(isMy ? 'ကျွန်တော်၏ ကုန်ပစ္စည်းများ' : 'My Listings'),
        trailing: productsAsync.when(
          data: (items) => Text(
            '${items.length}',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => const Text('—'),
        ),
        onTap: () => context.push(AppRoutes.favorites),
      ),
    );
  }
}

// ── Language button ──────────────────────────────────────────────────────────
class _LangButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
