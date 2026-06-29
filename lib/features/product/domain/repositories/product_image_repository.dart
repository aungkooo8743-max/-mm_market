import 'dart:io';

abstract class ProductImageRepository {
  Future<String> uploadProductImage({required String sellerId, required String productId, required File image, String? fileName});
  Future<List<String>> uploadProductImages({required String sellerId, required String productId, required List<File> images});
  Future<void> deleteProductImageByUrl(String imageUrl);
  Future<void> deleteProductImagesByUrls(List<String> imageUrls);
}
