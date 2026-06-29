import 'dart:io';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/storage_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/firebase/storage_service.dart';
import '../../domain/repositories/product_image_repository.dart';

class ProductImageRepositoryImpl implements ProductImageRepository {
  final StorageService _storageService;
  const ProductImageRepositoryImpl(this._storageService);

  @override
  Future<String> uploadProductImage({required String sellerId, required String productId, required File image, String? fileName}) async {
    if (!image.existsSync()) throw const AppException(message: 'Image file မတွေ့ပါ', code: 'image-file-not-found');
    final safeName = fileName?.trim().isNotEmpty == true ? fileName!.trim() : '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = StoragePaths.productImage(sellerId: sellerId, productId: productId, fileName: safeName);
    return _storageService.uploadFile(file: image, path: path, contentType: _contentTypeFor(image.path));
  }

  @override
  Future<List<String>> uploadProductImages({required String sellerId, required String productId, required List<File> images}) async {
    if (images.length > AppConstants.maxProductImages) throw AppException(message: 'Product image အများဆုံး ${AppConstants.maxProductImages} ပုံသာ ထည့်နိုင်ပါသည်', code: 'too-many-product-images');
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      urls.add(await uploadProductImage(sellerId: sellerId, productId: productId, image: images[i], fileName: '${DateTime.now().millisecondsSinceEpoch}_$i.jpg'));
    }
    return urls;
  }

  @override Future<void> deleteProductImageByUrl(String imageUrl) async { if (imageUrl.trim().isNotEmpty) await _storageService.deleteFileByUrl(imageUrl); }
  @override Future<void> deleteProductImagesByUrls(List<String> imageUrls) async { for (final url in imageUrls) { await deleteProductImageByUrl(url); } }
  String _contentTypeFor(String path) { final p = path.toLowerCase(); if (p.endsWith('.png')) return 'image/png'; if (p.endsWith('.webp')) return 'image/webp'; if (p.endsWith('.heic')) return 'image/heic'; return 'image/jpeg'; }
}
