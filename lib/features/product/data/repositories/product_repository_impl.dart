import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/firebase/firestore_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_filter.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirestoreService _firestoreService;
  const ProductRepositoryImpl(this._firestoreService);
  CollectionReference<Map<String, dynamic>> get _products => _firestoreService.collection(FirestoreCollections.products);

  @override
  Stream<List<Product>> watchLatestProducts({int limit = 20}) => _products.orderBy('createdAt', descending: true).limit(limit).snapshots().map((s) => s.docs.map(_productFromDoc).toList().where((p) => p.status == ProductStatus.active).toList());

  @override
  Stream<Product?> watchProductById(String productId) {
    if (productId.trim().isEmpty) return Stream<Product?>.value(null);
    return _products.doc(productId).snapshots().map((doc) => (!doc.exists || doc.data() == null) ? null : _productFromDoc(doc));
  }

  @override
  Future<Product?> getProductById(String productId) async {
    if (productId.trim().isEmpty) return null;
    final doc = await _products.doc(productId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _productFromDoc(doc);
  }

  @override
  Future<ProductPageResult> getProducts({ProductFilter filter = const ProductFilter()}) async {
    Query<Map<String, dynamic>> query = _products;
    query = _applyFilters(query, filter);
    query = _applySort(query, filter.sort);
    if (filter.cursor is DocumentSnapshot<Map<String, dynamic>>) query = query.startAfterDocument(filter.cursor! as DocumentSnapshot<Map<String, dynamic>>);
    final limit = filter.limit <= 0 ? 20 : filter.limit;
    final snap = await query.limit(limit + 1).get();
    final hasMore = snap.docs.length > limit;
    final docs = hasMore ? snap.docs.take(limit).toList() : snap.docs;
    final targetStatus = filter.status ?? ProductStatus.active;
    final items = docs.map(_productFromDoc).where((p) => p.status == targetStatus).toList();
    return ProductPageResult(items: items, nextCursor: docs.isEmpty ? null : docs.last, hasMore: hasMore);
  }

  @override
  Future<ProductPageResult> searchProducts({required ProductFilter filter}) async {
    final result = await getProducts(filter: filter);
    final keyword = filter.keyword?.trim().toLowerCase();
    if (keyword == null || keyword.isEmpty) return result;
    return ProductPageResult(items: result.items.where((p) => p.title.toLowerCase().contains(keyword) || p.description.toLowerCase().contains(keyword) || p.city.toLowerCase().contains(keyword) || p.township.toLowerCase().contains(keyword) || p.category.name.toLowerCase().contains(keyword)).toList(), nextCursor: result.nextCursor, hasMore: result.hasMore);
  }

  @override
  Future<List<Product>> getSellerProducts({required String sellerId, ProductStatus? status, int limit = 20}) async {
    // NOTE: 'status' filter removed from Firestore query to avoid composite index
    // (sellerId + status + orderBy createdAt). Status filtered client-side.
    Query<Map<String, dynamic>> q = _products
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    final snap = await q.get();
    final products = snap.docs.map(_productFromDoc).toList();
    if (status != null) return products.where((p) => p.status == status).toList();
    return products;
  }

  @override
  Future<String> createProduct({required String sellerId, required String title, required String description, required ProductCategory category, required ProductCondition condition, required int price, required String city, required String township, String currency = 'MMK', bool isNegotiable = false, List<String> imageUrls = const [], String? coverImageUrl, String? address, bool isFeatured = false, bool isUrgent = false}) async {
    if (sellerId.trim().isEmpty) throw const AppException(message: 'Seller ID မရှိပါ', code: 'missing-seller-id');
    final doc = _products.doc();
    final now = DateTime.now();
    final product = Product(id: doc.id, sellerId: sellerId, title: title.trim(), description: description.trim(), category: category, condition: condition, price: price, city: city.trim(), township: township.trim(), currency: currency, isNegotiable: isNegotiable, imageUrls: imageUrls, coverImageUrl: coverImageUrl, address: address, isFeatured: isFeatured, isUrgent: isUrgent, createdAt: now, updatedAt: now);
    await doc.set({...product.toMap(), 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
    return doc.id;
  }

  @override
  Future<void> updateProduct({required String productId, required String requesterId, String? title, String? description, ProductCategory? category, ProductCondition? condition, int? price, String? currency, bool? isNegotiable, List<String>? imageUrls, String? coverImageUrl, bool clearCoverImageUrl = false, String? city, String? township, String? address, bool clearAddress = false, bool? isFeatured, bool? isUrgent}) async {
    await _assertCanModify(productId: productId, requesterId: requesterId);
    await _products.doc(productId).update({
      if (title != null) 'title': title.trim(),
      if (description != null) 'description': description.trim(),
      if (category != null) 'category': category.name,
      if (condition != null) 'condition': condition.name,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (isNegotiable != null) 'isNegotiable': isNegotiable,
      if (imageUrls != null) 'imageUrls': imageUrls,
      if (clearCoverImageUrl) 'coverImageUrl': null,
      if (!clearCoverImageUrl && coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      if (city != null) 'city': city.trim(),
      if (township != null) 'township': township.trim(),
      if (clearAddress) 'address': null,
      if (!clearAddress && address != null) 'address': address.trim(),
      if (isFeatured != null) 'isFeatured': isFeatured,
      if (isUrgent != null) 'isUrgent': isUrgent,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> changeStatus({required String productId, required String requesterId, required ProductStatus status}) async {
    await _assertCanModify(productId: productId, requesterId: requesterId);
    await _products.doc(productId).update({'status': status.name, 'updatedAt': FieldValue.serverTimestamp(), if (status == ProductStatus.sold) 'soldAt': FieldValue.serverTimestamp(), if (status == ProductStatus.deleted) 'deletedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> softDeleteProduct({required String productId, required String requesterId}) => changeStatus(productId: productId, requesterId: requesterId, status: ProductStatus.deleted);
  @override Future<void> incrementViewCount(String productId) => _increment(productId, 'viewCount');
  @override Future<void> incrementFavoriteCount(String productId) => _increment(productId, 'favoriteCount');
  @override Future<void> decrementFavoriteCount(String productId) => _increment(productId, 'favoriteCount', -1);
  @override Future<void> incrementReportCount(String productId) => _increment(productId, 'reportCount');

  @override
  Future<bool> canModifyProduct({required String productId, required String requesterId}) async {
    final product = await getProductById(productId);
    return product != null && !product.isDeleted && product.isOwner(requesterId);
  }

  // NOTE: 'status' filter intentionally removed from Firestore query to avoid
  // composite index requirement (status + orderBy field). Status is filtered
  // client-side after retrieval. All other equality filters are safe.
  Query<Map<String, dynamic>> _applyFilters(Query<Map<String, dynamic>> q, ProductFilter f) {
    if (f.sellerId != null && f.sellerId!.trim().isNotEmpty) q = q.where('sellerId', isEqualTo: f.sellerId!.trim());
    if (f.category != null) q = q.where('category', isEqualTo: f.category!.name);
    if (f.condition != null) q = q.where('condition', isEqualTo: f.condition!.name);
    if (f.city != null && f.city!.trim().isNotEmpty) q = q.where('city', isEqualTo: f.city!.trim());
    if (f.township != null && f.township!.trim().isNotEmpty) q = q.where('township', isEqualTo: f.township!.trim());
    if (f.minPrice != null) q = q.where('price', isGreaterThanOrEqualTo: f.minPrice);
    if (f.maxPrice != null) q = q.where('price', isLessThanOrEqualTo: f.maxPrice);
    return q;
  }
  Query<Map<String, dynamic>> _applySort(Query<Map<String, dynamic>> q, ProductSort s) { switch (s) { case ProductSort.oldest: return q.orderBy('createdAt'); case ProductSort.priceLowToHigh: return q.orderBy('price'); case ProductSort.priceHighToLow: return q.orderBy('price', descending: true); case ProductSort.mostViewed: return q.orderBy('viewCount', descending: true); case ProductSort.mostFavorited: return q.orderBy('favoriteCount', descending: true); case ProductSort.newest: return q.orderBy('createdAt', descending: true); } }
  Future<void> _assertCanModify({required String productId, required String requesterId}) async { if (!await canModifyProduct(productId: productId, requesterId: requesterId)) throw const AppException(message: 'ဒီ Product ကို ပြင်ဆင်ရန် ခွင့်မရှိပါ', code: 'product-permission-denied'); }
  Future<void> _increment(String productId, String field, [int amount = 1]) async { if (productId.trim().isEmpty) return; await _products.doc(productId).update({field: FieldValue.increment(amount), 'updatedAt': FieldValue.serverTimestamp()}); }
  Product _productFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) => Product.fromMap({...doc.data()!, 'id': doc.id});
}
