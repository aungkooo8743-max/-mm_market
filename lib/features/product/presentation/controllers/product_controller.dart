import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_image_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../providers/product_providers.dart';
import 'product_controller_state.dart';

final productControllerProvider =
    NotifierProvider<ProductController, ProductControllerState>(
        ProductController.new);

class ProductController extends Notifier<ProductControllerState> {
  late final ProductRepository _productRepository;
  late final ProductImageRepository _imageRepository;

  @override
  ProductControllerState build() {
    _productRepository = ref.read(productRepositoryProvider);
    _imageRepository = ref.read(productImageRepositoryProvider);
    return const ProductControllerState();
  }

  void setCurrentProduct(Product product) =>
      state = state.setCurrentProduct(product);

  void addSelectedImages(List<File> images) {
    final slots = AppConstants.maxProductImages - state.totalImageCount;
    if (slots <= 0) {
      state = state.failure(
          'Product image အများဆုံး ${AppConstants.maxProductImages} ပုံသာ ထည့်နိုင်ပါသည်');
      return;
    }
    state = state.addSelectedImages(images.take(slots).toList());
  }

  void removeSelectedImageAt(int index) =>
      state = state.removeSelectedImageAt(index);
  void removeExistingImageAt(int index) =>
      state = state.removeExistingImageAt(index);
  void resetStatus() => state = state.resetStatus();

  Future<String?> createProduct({
    required String title,
    required String description,
    required ProductCategory category,
    required ProductCondition condition,
    required int price,
    required String city,
    required String township,
    String currency = 'MMK',
    bool isNegotiable = false,
    String? address,
    bool isFeatured = false,
    bool isUrgent = false,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.failure('Product တင်ရန် Login ဝင်ရန်လိုအပ်ပါသည်');
      return null;
    }
    state = state.loading();
    CrashlyticsService.log('createProduct started: title=$title, uid=${user.uid}');
    try {
      final productId = await _productRepository.createProduct(
        sellerId: user.uid,
        title: title,
        description: description,
        category: category,
        condition: condition,
        price: price,
        city: city,
        township: township,
        currency: currency,
        isNegotiable: isNegotiable,
        address: address,
        isFeatured: isFeatured,
        isUrgent: isUrgent,
      );
      final urls = await _uploadSelectedImages(
          sellerId: user.uid, productId: productId);
      if (urls.isNotEmpty) {
        await _productRepository.updateProduct(
          productId: productId,
          requesterId: user.uid,
          imageUrls: urls,
          coverImageUrl: urls.first,
        );
      }
      _invalidate(productId, user.uid);
      CrashlyticsService.log('createProduct success: productId=$productId');
      state = state.successState(productId: productId);
      return productId;
    } catch (e, st) {
      unawaited(CrashlyticsService.recordFirestoreError(
        e, st,
        operation: 'createProduct',
        collection: 'products',
      ));
      state = state.failure(_errorMessage(e));
      return null;
    }
  }

  Future<void> updateProduct({
    required String productId,
    required String title,
    required String description,
    required ProductCategory category,
    required ProductCondition condition,
    required int price,
    required String city,
    required String township,
    String currency = 'MMK',
    bool isNegotiable = false,
    String? address,
    bool clearAddress = false,
    bool isFeatured = false,
    bool isUrgent = false,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.failure('Product ပြင်ရန် Login ဝင်ရန်လိုအပ်ပါသည်');
      return;
    }
    state = state.loading();
    CrashlyticsService.log('updateProduct started: productId=$productId');
    try {
      final uploaded = await _uploadSelectedImages(
          sellerId: user.uid, productId: productId);
      final allImages = [...state.existingImageUrls, ...uploaded];
      await _productRepository.updateProduct(
        productId: productId,
        requesterId: user.uid,
        title: title,
        description: description,
        category: category,
        condition: condition,
        price: price,
        currency: currency,
        isNegotiable: isNegotiable,
        imageUrls: allImages,
        coverImageUrl: allImages.isNotEmpty ? allImages.first : null,
        clearCoverImageUrl: allImages.isEmpty,
        city: city,
        township: township,
        address: address,
        clearAddress: clearAddress,
        isFeatured: isFeatured,
        isUrgent: isUrgent,
      );
      _invalidate(productId, user.uid);
      CrashlyticsService.log('updateProduct success: productId=$productId');
      state = state.successState(productId: productId);
    } catch (e, st) {
      unawaited(CrashlyticsService.recordFirestoreError(
        e, st,
        operation: 'updateProduct',
        collection: 'products',
        docId: productId,
      ));
      state = state.failure(_errorMessage(e));
    }
  }

  Future<void> deleteProduct(String productId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = state.loading();
    CrashlyticsService.log('deleteProduct started: productId=$productId');
    try {
      await _productRepository.softDeleteProduct(
        productId: productId,
        requesterId: user.uid,
      );
      _invalidate(productId, user.uid);
      CrashlyticsService.log('deleteProduct success: productId=$productId');
      state = state.successState(productId: productId);
    } catch (e, st) {
      unawaited(CrashlyticsService.recordFirestoreError(
        e, st,
        operation: 'deleteProduct',
        collection: 'products',
        docId: productId,
      ));
      state = state.failure(_errorMessage(e));
    }
  }

  Future<List<String>> _uploadSelectedImages({
    required String sellerId,
    required String productId,
  }) async {
    if (state.selectedImages.isEmpty) return const [];
    state = state.uploading(progress: 0);
    final urls = <String>[];
    for (var i = 0; i < state.selectedImages.length; i++) {
      try {
        final url = await _imageRepository.uploadProductImage(
          sellerId: sellerId,
          productId: productId,
          image: state.selectedImages[i],
          fileName: '${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        urls.add(url);
      } catch (e, st) {
        unawaited(CrashlyticsService.recordStorageError(
          e, st,
          operation: 'uploadProductImage',
          storagePath: 'products/$sellerId/$productId',
        ));
        rethrow;
      }
      state = state.uploading(progress: (i + 1) / state.selectedImages.length);
    }
    return urls;
  }

  void _invalidate(String productId, String sellerId) {
    ref.invalidate(latestProductsProvider);
    ref.invalidate(paginatedProductsProvider);
    ref.invalidate(productDetailProvider(productId));
    ref.invalidate(sellerProductsProvider(sellerId));
  }

  String _errorMessage(Object e) =>
      e is AppException ? e.message : e.toString();
}
