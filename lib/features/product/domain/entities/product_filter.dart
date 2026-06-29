import 'product.dart';

enum ProductSort { newest, oldest, priceLowToHigh, priceHighToLow, mostViewed, mostFavorited }

class ProductFilter {
  final String? keyword;
  final ProductCategory? category;
  final ProductCondition? condition;
  final ProductStatus? status;
  final String? sellerId;
  final String? city;
  final String? township;
  final int? minPrice;
  final int? maxPrice;
  final ProductSort sort;
  final int limit;
  final Object? cursor;
  const ProductFilter({this.keyword, this.category, this.condition, this.status, this.sellerId, this.city, this.township, this.minPrice, this.maxPrice, this.sort = ProductSort.newest, this.limit = 20, this.cursor});
}
