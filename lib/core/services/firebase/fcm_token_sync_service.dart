import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_collections.dart';
import 'firestore_service.dart';
import 'messaging_service.dart';

class FcmTokenSyncService {
  final MessagingService messagingService;
  final FirestoreService firestoreService;
  const FcmTokenSyncService({required this.messagingService, required this.firestoreService});

  Future<void> syncToken(String userId) async {
    final token = await messagingService.getToken();
    if (token == null) return;
    await firestoreService.collection(FirestoreCollections.users).doc(userId).set({'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
}
