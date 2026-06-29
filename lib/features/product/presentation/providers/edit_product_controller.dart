import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../domain/entities/product.dart';
import 'product_form_state.dart';
import 'product_providers.dart';

final editProductControllerProvider =
    StateNotifierProvider<EditProductController, ProductFormState>(
        (ref) => EditProductController(ref));

class EditProductController extends StateNotifier<ProductFormState> {
  final Ref ref;
  EditProductController(this.ref) : super(const ProductFormState());

  void initialize(Product product) => state = state.copyWith(
        existingImageUrls: product.imageUrls,
        productId: product.id,
        clearError: true,
      );

  void setImages(List<File> images) => state = state.copyWith(
        selectedImages: images
            .take(AppConstants.maxProductImages - state.existingImageUrls.length)
            .toList(),
        clearError: true,
      );

  void removeExistingImage(int index) {
    final list = [...state.existingImageUrls];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = state.copyWith(existingImageUrls: list);
    }
  }

  void removeNewImage(int index) {
    final list = [...state.selectedImages];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = state.copyWith(selectedImages: list);
    }
  }

  Future<void> saveProduct({
    required Product product,
    required String title,
    required String description,
    required String priceText,
    required ProductCategory category,
    required ProductCondition condition,
    required String city,
    required String township,
    String? address,
    bool isNegotiable = false,
  }) async {
    final price = int.tryParse(priceText.trim());
    if (price == null) {
      state = state.copyWith(errorMessage: 'Invalid price');
      return;
    }
    state = state.copyWith(isLoading: true, success: false, clearError: true);
    CrashlyticsService.log('editProduct saveProduct: productId=${product.id}');
    try {
      await ref.read(productRepositoryProvider).updateProduct(
            productId: product.id,
            requesterId: product.sellerId,
            title: title.trim(),
            description: description.trim(),
            category: category,
            condition: condition,
            price: price,
            city: city.trim(),
            township: township.trim(),
            address: address,
            clearAddress: address == null || address.trim().isEmpty,
            isNegotiable: isNegotiable,
          );
      state = state.copyWith(isLoading: false, success: true);
      ref.invalidate(productDetailProvider(product.id));
    } catch (e, st) {
      unawaited(CrashlyticsService.recordFirestoreError(
        e, st,
        operation: 'editProduct_saveProduct',
        collection: 'products',
        docId: product.id,
      ));
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> changeStatus({
    required Product product,
    required ProductStatus status,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    CrashlyticsService.log('editProduct changeStatus: productId=${product.id}, status=$status');
    try {
      await ref.read(productRepositoryProvider).changeStatus(
            productId: product.id,
            requesterId: product.sellerId,
            status: status,
          );
      state = state.copyWith(isLoading: false, success: true);
      ref.invalidate(productDetailProvider(product.id));
    } catch (e, st) {
      unawaited(CrashlyticsService.recordFirestoreError(
        e, st,
        operation: 'editProduct_changeStatus',
        collection: 'products',
        docId: product.id,
      ));
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
