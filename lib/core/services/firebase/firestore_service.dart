import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore firestore;
  const FirestoreService(this.firestore);
  CollectionReference<Map<String, dynamic>> collection(String path) => firestore.collection(path);
  DocumentReference<Map<String, dynamic>> document(String path) => firestore.doc(path);
  WriteBatch batch() => firestore.batch();
  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) action) => firestore.runTransaction(action);
}
