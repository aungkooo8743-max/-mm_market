class StoragePaths {
  const StoragePaths._();

  static String userProfilePhoto({required String userId, required String fileName}) =>
      'users/$userId/profile/$fileName';

  static String productImage({required String sellerId, required String productId, required String fileName}) =>
      'products/$sellerId/$productId/$fileName';

  static String chatImage({required String chatId, required String senderId, required String fileName}) =>
      'chats/$chatId/$senderId/$fileName';

  static String reportEvidence({required String reporterId, required String reportId, required String fileName}) =>
      'reports/$reporterId/$reportId/$fileName';
}
