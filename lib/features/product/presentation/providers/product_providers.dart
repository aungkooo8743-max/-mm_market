import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/firebase/firestore_service.dart';
import '../../../../core/services/firebase/storage_service.dart';
import '../../data/repositories/product_image_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_filter.dart';
import '../../domain/repositories/product_image_repository.dart';
import '../../domain/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) => ProductRepositoryImpl(sl<FirestoreService>()));
final productImageRepositoryProvider = Provider<ProductImageRepository>((ref) => ProductImageRepositoryImpl(sl<StorageService>()));
final latestProductsProvider = StreamProvider<List<Product>>((ref) => ref.watch(productRepositoryProvider).watchLatestProducts(limit: 20));
final productDetailProvider = StreamProvider.family<Product?, String>((ref, productId) => ref.watch(productRepositoryProvider).watchProductById(productId));
final sellerProductsProvider = FutureProvider.family<List<Product>, String>((ref, sellerId) => ref.watch(productRepositoryProvider).getSellerProducts(sellerId: sellerId));
final productFilterProvider = StateProvider<ProductFilter>((ref) => const ProductFilter());
final paginatedProductsProvider = FutureProvider<ProductPageResult>((ref) => ref.watch(productRepositoryProvider).getProducts(filter: ref.watch(productFilterProvider)));
