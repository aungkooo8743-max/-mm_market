// Legacy file — kept for backward compatibility.
// All product creation logic is handled by [productControllerProvider]
// in lib/features/product/presentation/controllers/product_controller.dart
//
// This file is intentionally empty of business logic to avoid
// duplicate state and conflicting API calls.

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/product.dart';
import 'product_form_state.dart';

final createProductControllerProvider =
    StateNotifierProvider<CreateProductController, ProductFormState>(
        (ref) => CreateProductController(ref));

class CreateProductController extends StateNotifier<ProductFormState> {
  final Ref ref;
  CreateProductController(this.ref) : super(const ProductFormState());

  void setImages(List<File> images) => state = state.copyWith(
        selectedImages: images.take(AppConstants.maxProductImages).toList(),
        clearError: true,
      );

  void removeImage(int index) {
    final list = [...state.selectedImages];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = state.copyWith(selectedImages: list);
    }
  }

  /// Deprecated: Use [productControllerProvider] instead.
  /// This method is a no-op stub kept for API compatibility.
  Future<void> createProduct({
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
    // No-op: AddProductPage uses productControllerProvider directly.
    // This stub prevents compile errors from any legacy references.
  }
}
