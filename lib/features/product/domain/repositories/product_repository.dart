import '../entities/product.dart';
import '../entities/product_filter.dart';

class ProductPageResult {
  final List<Product> items;
  final Object? nextCursor;
  final bool hasMore;
  const ProductPageResult({required this.items, this.nextCursor, required this.hasMore});
}

abstract class ProductRepository {
  Stream<List<Product>> watchLatestProducts({int limit = 20});
  Stream<Product?> watchProductById(String productId);
  Future<Product?> getProductById(String productId);
  Future<ProductPageResult> getProducts({ProductFilter filter = const ProductFilter()});
  Future<ProductPageResult> searchProducts({required ProductFilter filter});
  Future<List<Product>> getSellerProducts({required String sellerId, ProductStatus? status, int limit = 20});
  Future<String> createProduct({required String sellerId, required String title, required String description, required ProductCategory category, required ProductCondition condition, required int price, required String city, required String township, String currency = 'MMK', bool isNegotiable = false, List<String> imageUrls = const [], String? coverImageUrl, String? address, bool isFeatured = false, bool isUrgent = false});
  Future<void> updateProduct({required String productId, required String requesterId, String? title, String? description, ProductCategory? category, ProductCondition? condition, int? price, String? currency, bool? isNegotiable, List<String>? imageUrls, String? coverImageUrl, bool clearCoverImageUrl = false, String? city, String? township, String? address, bool clearAddress = false, bool? isFeatured, bool? isUrgent});
  Future<void> changeStatus({required String productId, required String requesterId, required ProductStatus status});
  Future<void> softDeleteProduct({required String productId, required String requesterId});
  Future<void> incrementViewCount(String productId);
  Future<void> incrementFavoriteCount(String productId);
  Future<void> decrementFavoriteCount(String productId);
  Future<void> incrementReportCount(String productId);
  Future<bool> canModifyProduct({required String productId, required String requesterId});
}
