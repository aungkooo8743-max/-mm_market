import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/image_cache_service.dart';
import '../../../../core/widgets/image_fullscreen_viewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../../favorite/presentation/providers/favorite_providers.dart';
import '../providers/product_providers.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});
  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productDetailProvider(widget.productId));
    final user = ref.watch(currentUserProvider);
    final locale = ref.watch(languageProvider);
    final isMy = locale.languageCode == 'my';

    return Scaffold(
      body: async.when(
        loading: () => const AppLoadingView(),
        error: (e, _) => AppEmptyView(
          title: isMy ? 'အမှားဖြစ်ပွားသည်' : 'Something went wrong',
          message: isMy ? 'ထပ်မံကြိုးစားပါ' : 'Please try again',
          icon: Icons.error_outline,
          actionLabel: isMy ? 'ပြန်သွားရန်' : 'Go Back',
          onAction: () => Navigator.of(context).pop(),
        ),
        data: (p) {
          if (p == null) {
            return AppEmptyView(
              title: isMy ? 'ကုန်ပစ္စည်း မတွေ့ပါ' : 'Product not found',
              icon: Icons.inventory_2_outlined,
              actionLabel: isMy ? 'ပြန်သွားရန်' : 'Go Back',
              onAction: () => Navigator.of(context).pop(),
            );
          }

          final isOwner = user?.uid == p.sellerId;
          final images = p.imageUrls.isNotEmpty
              ? p.imageUrls
              : (p.mainImageUrl != null ? [p.mainImageUrl!] : <String>[]);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                actions: [
                  if (isOwner)
                    IconButton(
                      onPressed: () =>
                          context.push(AppRoutes.editProductPath(p.id)),
                      icon: const Icon(Icons.edit),
                      tooltip: isMy ? 'ပြင်ဆင်ရန်' : 'Edit',
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: images.isEmpty
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                size: 80, color: Colors.grey),
                          ),
                        )
                      : Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              onPageChanged: (i) =>
                                  setState(() => _currentImageIndex = i),
                              itemBuilder: (_, i) => GestureDetector(
                                onTap: () => ImageFullscreenViewer.show(
                                  context,
                                  images: images,
                                  initialIndex: i,
                                ),
                                child: Hero(
                                  tag: 'product_image_$i',
                                  child: ImageCacheService.buildProductImage(
                                    imageUrl: images[i],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                            if (images.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    images.length,
                                    (i) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      width:
                                          i == _currentImageIndex ? 20 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: i == _currentImageIndex
                                            ? Colors.white
                                            : Colors.white54,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (images.length > 1)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_currentImageIndex + 1}/${images.length}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${p.price} ${p.currency}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (p.isNegotiable) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(
                                isMy ? 'ညှိနှိုင်းနိုင်' : 'Negotiable',
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(p.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${p.township}, ${p.city}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.category_outlined,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            p.category.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.info_outline,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            p.condition.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        isMy ? 'အသေးစိတ်ဖော်ပြချက်' : 'Description',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(p.description),
                      const SizedBox(height: 24),
                      if (!isOwner) ...[
                        _ActionButtonsRow(
                          isMy: isMy,
                          productId: p.id,
                          productTitle: p.title,
                          onChat: () async {
                            final roomId = await ref
                                .read(chatControllerProvider.notifier)
                                .createOrGetRoom(
                                    sellerId: p.sellerId,
                                    productId: p.id);
                            if (context.mounted && roomId != null) {
                              context.push(AppRoutes.chatRoomPath(roomId));
                            }
                          },
                          onShare: () async {
                            final text =
                                'MM Market တွင် "${p.title}" ကို ကြည့်ပါ';
                            await Clipboard.setData(
                                ClipboardData(text: text));
                            if (context.mounted) {
                              AppSnackbar.info(
                                context,
                                isMy
                                    ? 'Link ကို ကူးယူပြီးပြီ'
                                    : 'Link copied to clipboard',
                              );
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButtonsRow extends ConsumerWidget {
  final bool isMy;
  final String productId;
  final String productTitle;
  final VoidCallback onChat;
  final VoidCallback onShare;

  const _ActionButtonsRow({
    required this.isMy,
    required this.productId,
    required this.productTitle,
    required this.onChat,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavAsync = ref.watch(isFavoriteProvider(productId));
    final isFav = isFavAsync.valueOrNull ?? false;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(
                isMy ? 'ရောင်းသူနှင့် ချတ်လုပ်ရန်' : 'Chat with Seller'),
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
                label: Text(isMy ? 'မျှဝေရန်' : 'Share'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(favoriteControllerProvider.notifier).toggle(productId),
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
                label: Text(
                  isFav
                      ? (isMy ? 'သိမ်းဆည်းပြီး' : 'Saved')
                      : (isMy ? 'သိမ်းဆည်းရန်' : 'Save'),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: isFav ? Colors.red : null,
                  side: isFav ? const BorderSide(color: Colors.red) : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
