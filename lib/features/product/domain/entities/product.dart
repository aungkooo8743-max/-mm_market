import 'package:equatable/equatable.dart';
import '../../../../core/utils/date_parser.dart';
import '../../../../core/utils/enum_parser.dart';
import '../../../../core/utils/map_utils.dart';

enum ProductStatus { draft, active, sold, hidden, deleted, rejected, pendingReview }
enum ProductCondition { newItem, likeNew, used, refurbished }
enum ProductCategory { electronics, phones, computers, fashion, vehicles, property, furniture, homeAppliances, beauty, sports, books, toys, jobs, services, other }

class Product extends Equatable {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final ProductCategory category;
  final ProductCondition condition;
  final ProductStatus status;
  final int price;
  final String currency;
  final bool isNegotiable;
  final List<String> imageUrls;
  final String? coverImageUrl;
  final String city;
  final String township;
  final String? address;
  final int viewCount;
  final int favoriteCount;
  final int reportCount;
  final bool isFeatured;
  final bool isUrgent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? soldAt;
  final DateTime? deletedAt;

  const Product({required this.id, required this.sellerId, required this.title, required this.description, required this.category, required this.condition, this.status = ProductStatus.active, required this.price, this.currency = 'MMK', this.isNegotiable = false, this.imageUrls = const [], this.coverImageUrl, required this.city, required this.township, this.address, this.viewCount = 0, this.favoriteCount = 0, this.reportCount = 0, this.isFeatured = false, this.isUrgent = false, required this.createdAt, required this.updatedAt, this.soldAt, this.deletedAt});

  bool get isVisible => status == ProductStatus.active;
  bool get isSold => status == ProductStatus.sold;
  bool get isDeleted => status == ProductStatus.deleted;
  bool isOwner(String userId) => sellerId == userId;
  String get displayPrice => '$price $currency';
  String? get primaryImageUrl => (coverImageUrl != null && coverImageUrl!.trim().isNotEmpty) ? coverImageUrl : (imageUrls.isNotEmpty ? imageUrls.first : null);
  String? get mainImageUrl => primaryImageUrl;

  Product copyWith({String? id, String? sellerId, String? title, String? description, ProductCategory? category, ProductCondition? condition, ProductStatus? status, int? price, String? currency, bool? isNegotiable, List<String>? imageUrls, String? coverImageUrl, bool clearCoverImageUrl = false, String? city, String? township, String? address, bool clearAddress = false, int? viewCount, int? favoriteCount, int? reportCount, bool? isFeatured, bool? isUrgent, DateTime? createdAt, DateTime? updatedAt, DateTime? soldAt, bool clearSoldAt = false, DateTime? deletedAt, bool clearDeletedAt = false}) => Product(id: id ?? this.id, sellerId: sellerId ?? this.sellerId, title: title ?? this.title, description: description ?? this.description, category: category ?? this.category, condition: condition ?? this.condition, status: status ?? this.status, price: price ?? this.price, currency: currency ?? this.currency, isNegotiable: isNegotiable ?? this.isNegotiable, imageUrls: imageUrls ?? this.imageUrls, coverImageUrl: clearCoverImageUrl ? null : (coverImageUrl ?? this.coverImageUrl), city: city ?? this.city, township: township ?? this.township, address: clearAddress ? null : (address ?? this.address), viewCount: viewCount ?? this.viewCount, favoriteCount: favoriteCount ?? this.favoriteCount, reportCount: reportCount ?? this.reportCount, isFeatured: isFeatured ?? this.isFeatured, isUrgent: isUrgent ?? this.isUrgent, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt, soldAt: clearSoldAt ? null : (soldAt ?? this.soldAt), deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt));

  Map<String, dynamic> toMap() => {'sellerId': sellerId, 'title': title.trim(), 'description': description.trim(), 'category': category.name, 'condition': condition.name, 'status': status.name, 'price': price, 'currency': currency, 'isNegotiable': isNegotiable, 'imageUrls': imageUrls, 'coverImageUrl': coverImageUrl, 'city': city.trim(), 'township': township.trim(), 'address': address, 'viewCount': viewCount, 'favoriteCount': favoriteCount, 'reportCount': reportCount, 'isFeatured': isFeatured, 'isUrgent': isUrgent, 'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(), 'soldAt': soldAt?.toIso8601String(), 'deletedAt': deletedAt?.toIso8601String(),
        'searchKeywords': _buildSearchKeywords()};
  factory Product.fromMap(Map<String, dynamic> map) => Product(id: MapUtils.stringValue(map, 'id'), sellerId: MapUtils.stringValue(map, 'sellerId'), title: MapUtils.stringValue(map, 'title'), description: MapUtils.stringValue(map, 'description'), category: EnumParser.fromName(values: ProductCategory.values, name: (map['category'] ?? map['categoryId']) as String?, fallback: ProductCategory.other), condition: EnumParser.fromName(values: ProductCondition.values, name: map['condition'] as String?, fallback: ProductCondition.used), status: EnumParser.fromName(values: ProductStatus.values, name: map['status'] as String?, fallback: ProductStatus.active), price: MapUtils.intValue(map, 'price'), currency: MapUtils.stringValue(map, 'currency', fallback: 'MMK'), isNegotiable: MapUtils.boolValue(map, 'isNegotiable'), imageUrls: MapUtils.stringListValue(map, 'imageUrls'), coverImageUrl: map['coverImageUrl'] as String?, city: MapUtils.stringValue(map, 'city'), township: MapUtils.stringValue(map, 'township'), address: map['address'] as String?, viewCount: MapUtils.intValue(map, 'viewCount'), favoriteCount: MapUtils.intValue(map, 'favoriteCount'), reportCount: MapUtils.intValue(map, 'reportCount'), isFeatured: MapUtils.boolValue(map, 'isFeatured'), isUrgent: MapUtils.boolValue(map, 'isUrgent'), createdAt: DateParser.fromValue(map['createdAt']) ?? DateTime.now(), updatedAt: DateParser.fromValue(map['updatedAt']) ?? DateTime.now(), soldAt: DateParser.fromValue(map['soldAt']), deletedAt: DateParser.fromValue(map['deletedAt']));
  Map<String, dynamic> toJson() => toMap();
  factory Product.fromJson(Map<String, dynamic> json) => Product.fromMap(json);
  @override List<Object?> get props => [id, sellerId, title, description, category, condition, status, price, currency, isNegotiable, imageUrls, coverImageUrl, city, township, address, viewCount, favoriteCount, reportCount, isFeatured, isUrgent, createdAt, updatedAt, soldAt, deletedAt];
  /// Builds a list of lowercase keyword tokens for server-side Firestore search.
  ///
  /// Tokenises [title] and [description] into individual lowercase words and
  /// also includes the full lowercased title and description as single tokens
  /// so that exact-phrase searches work alongside single-word searches.
  List<String> _buildSearchKeywords() {
    final Set<String> keywords = {};
    // Full strings (for exact-phrase match)
    keywords.add(title.trim().toLowerCase());
    keywords.add(description.trim().toLowerCase());
    // Individual word tokens
    keywords.addAll(
      title.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 1),
    );
    keywords.addAll(
      description.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 1),
    );
    // Category and city tokens for category/location search
    keywords.add(category.name.toLowerCase());
    keywords.add(city.trim().toLowerCase());
    keywords.add(township.trim().toLowerCase());
    return keywords.toList();
  }

}
