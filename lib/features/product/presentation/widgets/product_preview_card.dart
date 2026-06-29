import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../../../core/services/image_cache_service.dart';
import '../../domain/entities/product.dart';

class ProductPreviewCard extends StatelessWidget {
  final Product product;
  const ProductPreviewCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Layer 5: silently log products with no cover image for data-quality monitoring.
    if (product.mainImageUrl == null) {
      CrashlyticsService.recordUiWarning(
        'NullCoverImage',
        details: 'productId: ${product.id}',
        screen: 'HomeProductGrid',
      );
    }
    return InkWell(
      onTap: () => context.push(AppRoutes.productDetailPath(product.id)),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ImageCacheService.buildProductImage(
                imageUrl: product.mainImageUrl,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${product.price} ${product.currency}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${product.township}, ${product.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
