import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/services/firebase/firestore_service.dart';
import '../../../product/domain/entities/product.dart';
import '../../domain/entities/recent_search.dart';
import '../../domain/entities/trending_search.dart';
import '../../domain/models/search_filter.dart';
import '../../domain/repositories/search_repository.dart';

/// Server-side Firestore search implementation.
///
/// Fix 3 (QA Blocker): Replaces the previous client-side `.contains()` filter
/// with a scalable server-side `arrayContains` query on the `searchKeywords`
/// field.
///
/// IMPORTANT: When a keyword search is active, `orderBy('createdAt')` is
/// intentionally omitted because combining `arrayContains` with `orderBy` on a
/// different field requires a composite index that may not yet be deployed.
/// Instead, results are sorted in Dart after retrieval (cheap for ≤100 docs).
/// When no keyword is provided, `orderBy('createdAt')` is applied normally.
class SearchRepositoryImpl implements SearchRepository {
  final FirestoreService fs;
  const SearchRepositoryImpl(this.fs);

  @override
  Future<List<Product>> searchProducts({required SearchFilter filter}) async {
    final keyword = filter.keyword.trim().toLowerCase();

    Query<Map<String, dynamic>> q = fs
        .collection(FirestoreCollections.products)
        .where('status', isEqualTo: ProductStatus.active.name);

    if (keyword.isNotEmpty) {
      // Server-side keyword filter. orderBy is skipped to avoid requiring a
      // composite index. Results are sorted client-side (safe for ≤100 docs).
      q = q.where('searchKeywords', arrayContains: keyword).limit(filter.limit);
    } else {
      // No keyword — safe to use orderBy (single-field index, auto-created).
      if (filter.newestFirst) {
        q = q.orderBy('createdAt', descending: true);
      }
      q = q.limit(filter.limit);
    }

    final snapshot = await q.get();
    final products = snapshot.docs
        .map((d) => Product.fromMap({...d.data(), 'id': d.id}))
        .toList();

    // Sort keyword results by createdAt descending (client-side).
    if (keyword.isNotEmpty && filter.newestFirst) {
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return products;
  }

  @override
  Stream<List<RecentSearch>> watchRecentSearches({required String userId}) =>
      fs
          .collection(FirestoreCollections.recentSearches)
          .where('userId', isEqualTo: userId)
          .orderBy('searchedAt', descending: true)
          .snapshots()
          .map((s) =>
              s.docs.map((d) => RecentSearch.fromMap(d.id, d.data())).toList());

  @override
  Future<void> saveRecentSearch({
    required String userId,
    required String keyword,
  }) =>
      fs
          .collection(FirestoreCollections.recentSearches)
          .doc('${userId}_${keyword.toLowerCase()}')
          .set(
            {
              'userId': userId,
              'keyword': keyword,
              'searchedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

  @override
  Future<void> deleteRecentSearch({required String searchId}) =>
      fs.collection(FirestoreCollections.recentSearches).doc(searchId).delete();

  @override
  Future<void> clearRecentSearches({required String userId}) async {
    final snapshot = await fs
        .collection(FirestoreCollections.recentSearches)
        .where('userId', isEqualTo: userId)
        .get();
    final batch = fs.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<List<TrendingSearch>> getTrendingSearches({int limit = 10}) async {
    final snapshot = await fs
        .collection(FirestoreCollections.trendingSearches)
        .orderBy('count', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((d) => TrendingSearch.fromMap(d.data()))
        .toList();
  }
}
