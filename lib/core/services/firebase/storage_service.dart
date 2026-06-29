import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage storage;
  const StorageService(this.storage);

  Future<String> uploadFile({required File file, required String path, required String contentType}) async {
    final task = await storage.ref(path).putFile(file, SettableMetadata(contentType: contentType));
    return task.ref.getDownloadURL();
  }

  Future<void> deleteFileByUrl(String url) => storage.refFromURL(url).delete();
}
