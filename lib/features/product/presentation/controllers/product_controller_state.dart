import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';

class ProductControllerState extends Equatable {
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final bool success;
  final String? successProductId;
  final String? errorMessage;
  final Product? currentProduct;
  final List<File> selectedImages;
  final List<String> existingImageUrls;
  const ProductControllerState({this.isLoading = false, this.isUploading = false, this.uploadProgress = 0, this.success = false, this.successProductId, this.errorMessage, this.currentProduct, this.selectedImages = const [], this.existingImageUrls = const []});
  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;
  int get totalImageCount => selectedImages.length + existingImageUrls.length;
  ProductControllerState copyWith({bool? isLoading, bool? isUploading, double? uploadProgress, bool? success, String? successProductId, bool clearSuccessProductId = false, String? errorMessage, bool clearError = false, Product? currentProduct, bool clearCurrentProduct = false, List<File>? selectedImages, List<String>? existingImageUrls}) => ProductControllerState(isLoading: isLoading ?? this.isLoading, isUploading: isUploading ?? this.isUploading, uploadProgress: uploadProgress ?? this.uploadProgress, success: success ?? this.success, successProductId: clearSuccessProductId ? null : (successProductId ?? this.successProductId), errorMessage: clearError ? null : (errorMessage ?? this.errorMessage), currentProduct: clearCurrentProduct ? null : (currentProduct ?? this.currentProduct), selectedImages: selectedImages ?? this.selectedImages, existingImageUrls: existingImageUrls ?? this.existingImageUrls);
  ProductControllerState loading() => copyWith(isLoading: true, isUploading: false, uploadProgress: 0, success: false, clearError: true, clearSuccessProductId: true);
  ProductControllerState uploading({double progress = 0}) => copyWith(isLoading: true, isUploading: true, uploadProgress: progress.clamp(0, 1), success: false, clearError: true);
  ProductControllerState successState({String? productId}) => copyWith(isLoading: false, isUploading: false, uploadProgress: 1, success: true, successProductId: productId, clearError: true);
  ProductControllerState failure(String message) => copyWith(isLoading: false, isUploading: false, uploadProgress: 0, success: false, errorMessage: message, clearSuccessProductId: true);
  ProductControllerState resetStatus() => copyWith(isLoading: false, isUploading: false, uploadProgress: 0, success: false, clearError: true, clearSuccessProductId: true);
  ProductControllerState setCurrentProduct(Product product) => copyWith(currentProduct: product, existingImageUrls: product.imageUrls, selectedImages: const [], clearError: true);
  ProductControllerState addSelectedImages(List<File> images) => copyWith(selectedImages: [...selectedImages, ...images], clearError: true);
  ProductControllerState removeSelectedImageAt(int index) { if (index < 0 || index >= selectedImages.length) return this; final updated = [...selectedImages]..removeAt(index); return copyWith(selectedImages: updated, clearError: true); }
  ProductControllerState removeExistingImageAt(int index) { if (index < 0 || index >= existingImageUrls.length) return this; final updated = [...existingImageUrls]..removeAt(index); return copyWith(existingImageUrls: updated, clearError: true); }
  @override List<Object?> get props => [isLoading, isUploading, uploadProgress, success, successProductId, errorMessage, currentProduct, selectedImages, existingImageUrls];
}
