import 'dart:io';

class ProductFormState {
  final bool isLoading;
  final bool success;
  final String? errorMessage;
  final String? productId;
  final List<File> selectedImages;
  final List<String> existingImageUrls;
  const ProductFormState({this.isLoading = false, this.success = false, this.errorMessage, this.productId, this.selectedImages = const [], this.existingImageUrls = const []});
  ProductFormState copyWith({bool? isLoading, bool? success, String? errorMessage, String? productId, List<File>? selectedImages, List<String>? existingImageUrls, bool clearError = false}) => ProductFormState(isLoading: isLoading ?? this.isLoading, success: success ?? this.success, errorMessage: clearError ? null : errorMessage, productId: productId ?? this.productId, selectedImages: selectedImages ?? this.selectedImages, existingImageUrls: existingImageUrls ?? this.existingImageUrls);
}
