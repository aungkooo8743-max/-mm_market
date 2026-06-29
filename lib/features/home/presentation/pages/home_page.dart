import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/image_cache_service.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../product/presentation/widgets/product_preview_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(latestProductsProvider);
    final locale = ref.watch(languageProvider);
    final isMy = locale.languageCode == 'my';

    return Scaffold(
      appBar: AppBar(
        title: const Text('MM Market'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: isMy ? 'ရှာဖွေရန်' : 'Search',
            onPressed: () => context.push(AppRoutes.search),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: isMy ? 'အကြောင်းကြားချက်' : 'Notifications',
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: isMy ? 'ပရိုဖိုင်' : 'Profile',
            onPressed: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
      body: async.when(
        loading: () => const _ProductGridSkeleton(),
        error: (e, _) => AppEmptyView(
          title: isMy ? 'အမှားဖြစ်ပွားသည်' : 'Something went wrong',
          message: isMy ? 'ထပ်မံကြိုးစားပါ' : 'Please try again',
          icon: Icons.error_outline,
          actionLabel: isMy ? 'ပြန်ကြိုးစားရန်' : 'Retry',
          onAction: () => ref.invalidate(latestProductsProvider),
        ),
        data: (items) => items.isEmpty
            ? AppEmptyView(
                title: isMy ? 'ကုန်ပစ္စည်း မရှိသေးပါ' : 'No Products Yet',
                message: isMy
                    ? 'ပထမဆုံး product တင်ရန် "Product တင်ရန်" ကို နှိပ်ပါ'
                    : 'Be the first to list a product',
                icon: Icons.store_outlined,
                actionLabel: isMy ? 'Product တင်ရန်' : 'Add Product',
                onAction: () => context.go(AppRoutes.addProduct),
              )
            : _ProductGrid(items: items),
      ),
    );
  }
}

// ── Product grid with proactive image precaching ─────────────────────────────
class _ProductGrid extends StatefulWidget {
  final List<Product> items;
  const _ProductGrid({required this.items});

  @override
  State<_ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<_ProductGrid> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Proactively cache all cover images as soon as the list is rendered.
    // This ensures images are available offline and render instantly on scroll.
    final urls = widget.items.map((p) => p.coverImageUrl).toList();
    ImageCacheService.precacheProductImages(context, urls);
  }

  @override
  void didUpdateWidget(_ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-cache if the product list changes (e.g., pagination or refresh).
    if (oldWidget.items != widget.items) {
      final urls = widget.items.map((p) => p.coverImageUrl).toList();
      ImageCacheService.precacheProductImages(context, urls);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: .72,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.items.length,
      itemBuilder: (_, i) => ProductPreviewCard(product: widget.items[i]),
    );
  }
}

// ── Skeleton shimmer grid ────────────────────────────────────────────────────
class _ProductGridSkeleton extends StatefulWidget {
  const _ProductGridSkeleton();

  @override
  State<_ProductGridSkeleton> createState() => _ProductGridSkeletonState();
}

class _ProductGridSkeletonState extends State<_ProductGridSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: .72,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => _SkeletonCard(opacity: _anim.value),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double opacity;
  const _SkeletonCard({required this.opacity});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
    final shimmerColor = baseColor.withValues(alpha: opacity);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Expanded(
            child: Container(color: shimmerColor),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price placeholder
                Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                // Title placeholder
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                // Location placeholder
                Container(
                  height: 10,
                  width: 100,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
