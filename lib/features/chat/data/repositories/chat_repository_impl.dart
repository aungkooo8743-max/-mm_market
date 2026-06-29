import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/constants/storage_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/firebase/firestore_service.dart';
import '../../../../core/services/firebase/storage_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  const ChatRepositoryImpl({required FirestoreService firestoreService, required StorageService storageService}) : _firestoreService = firestoreService, _storageService = storageService;
  CollectionReference<Map<String,dynamic>> get _rooms => _firestoreService.collection(FirestoreCollections.chats);
  CollectionReference<Map<String,dynamic>> _messages(String roomId) => _rooms.doc(roomId).collection(FirestoreCollections.messages);

  @override Stream<List<ChatRoom>> watchMyChatRooms({required String userId, int limit = 30}) => _rooms.where('participantIds', arrayContains: userId).orderBy('lastMessageAt', descending: true).limit(limit).snapshots().map((s)=>s.docs.map(_roomFromDoc).toList());
  @override Stream<ChatRoom?> watchChatRoom({required String chatRoomId}) => _rooms.doc(chatRoomId).snapshots().map((d)=>!d.exists||d.data()==null?null:_roomFromDoc(d));
  @override Stream<List<ChatMessage>> watchMessages({required String chatRoomId, int limit = 50}) => _messages(chatRoomId).where('isDeleted', isEqualTo: false).orderBy('createdAt', descending: true).limit(limit).snapshots().map((s)=>s.docs.map((d)=>_messageFromDoc(chatRoomId,d)).toList());

  @override Future<ChatRoom?> getChatRoom({required String chatRoomId}) async { final d=await _rooms.doc(chatRoomId).get(); return !d.exists||d.data()==null?null:_roomFromDoc(d); }
  @override Future<ChatRoom?> getExistingRoomForProduct({required String productId, required String buyerId, required String sellerId}) async { final q=await _rooms.where('productId',isEqualTo:productId).where('buyerId',isEqualTo:buyerId).where('sellerId',isEqualTo:sellerId).limit(1).get(); return q.docs.isEmpty?null:_roomFromDoc(q.docs.first); }
  @override Future<String> createOrGetRoom({required String productId, required String buyerId, required String sellerId}) async { if(buyerId==sellerId) throw const AppException(message:'Self chat not allowed'); final existing=await getExistingRoomForProduct(productId:productId,buyerId:buyerId,sellerId:sellerId); if(existing!=null) return existing.id; final doc=_rooms.doc(); final now=DateTime.now(); final room=ChatRoom(id:doc.id,productId:productId,sellerId:sellerId,buyerId:buyerId,participantIds:[buyerId,sellerId],createdAt:now,updatedAt:now,lastMessageAt:now,unreadCounts:{buyerId:0,sellerId:0}); await doc.set({...room.toMap(),'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp(),'lastMessageAt':FieldValue.serverTimestamp()}); return doc.id; }

  @override Future<String> sendTextMessage({required String chatRoomId, required String senderId, required String text}) => _send(chatRoomId:chatRoomId,senderId:senderId,text:text,type:ChatMessageType.text);
  @override Future<String> sendImageMessage({required String chatRoomId, required String senderId, required File image, String? caption}) async { final fileName='${DateTime.now().millisecondsSinceEpoch}.jpg'; final url=await _storageService.uploadFile(file:image,path:StoragePaths.chatImage(chatId:chatRoomId,senderId:senderId,fileName:fileName),contentType:'image/jpeg'); return _send(chatRoomId:chatRoomId,senderId:senderId,text:caption??'',type:ChatMessageType.image,imageUrl:url); }

  Future<String> _send({required String chatRoomId,required String senderId,required String text,required ChatMessageType type,String? imageUrl}) async { final room=await getChatRoom(chatRoomId:chatRoomId); if(room==null) throw const AppException(message:'Chat room not found'); if(!room.isParticipant(senderId)) throw const AppException(message:'Not a chat participant'); final msg=_messages(chatRoomId).doc(); final now=DateTime.now(); final message=ChatMessage(id:msg.id,chatRoomId:chatRoomId,senderId:senderId,text:text,type:type,imageUrl:imageUrl,createdAt:now,updatedAt:now); final other=room.otherParticipantId(senderId); await _firestoreService.runTransaction((tx) async { tx.set(msg,{...message.toMap(),'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()}); tx.update(_rooms.doc(chatRoomId),{'lastMessageText': type==ChatMessageType.image ? (text.isEmpty?'Image':text) : text,'lastMessageSenderId':senderId,'lastMessageAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp(),'unreadCounts.$other':FieldValue.increment(1)}); }); return msg.id; }

  @override Future<ChatMessagesPageResult> getMessagesPage({required String chatRoomId, int limit = 50, Object? cursor}) async { Query<Map<String,dynamic>> q=_messages(chatRoomId).where('isDeleted',isEqualTo:false).orderBy('createdAt',descending:true); if(cursor is DocumentSnapshot<Map<String,dynamic>>) q=q.startAfterDocument(cursor); final snap=await q.limit(limit+1).get(); final hasMore=snap.docs.length>limit; final docs=hasMore?snap.docs.take(limit).toList():snap.docs; return ChatMessagesPageResult(items:docs.map((d)=>_messageFromDoc(chatRoomId,d)).toList(), nextCursor:docs.isEmpty?null:docs.last, hasMore:hasMore); }
  @override Future<void> markAsRead({required String chatRoomId, required String userId}) async { await _rooms.doc(chatRoomId).update({'unreadCounts.$userId':0,'updatedAt':FieldValue.serverTimestamp()}); }
  @override Future<void> archiveRoom({required String chatRoomId, required String requesterId}) async { if(!await isParticipant(chatRoomId:chatRoomId,userId:requesterId)) return; await _rooms.doc(chatRoomId).update({'status':ChatRoomStatus.archived.name,'updatedAt':FieldValue.serverTimestamp()}); }
  @override Future<void> blockRoom({required String chatRoomId, required String requesterId}) async { if(!await isParticipant(chatRoomId:chatRoomId,userId:requesterId)) return; await _rooms.doc(chatRoomId).update({'status':ChatRoomStatus.blocked.name,'updatedAt':FieldValue.serverTimestamp()}); }
  @override Future<void> deleteMessage({required String chatRoomId, required String messageId, required String requesterId}) async { final doc=await _messages(chatRoomId).doc(messageId).get(); if(!doc.exists || doc.data()?['senderId'] != requesterId) throw const AppException(message:'Message ဖျက်ရန် ခွင့်မရှိပါ'); await doc.reference.update({'isDeleted':true,'status':ChatMessageStatus.deleted.name,'updatedAt':FieldValue.serverTimestamp()}); }
  @override Future<bool> isParticipant({required String chatRoomId, required String userId}) async { final room=await getChatRoom(chatRoomId:chatRoomId); return room?.isParticipant(userId)??false; }
  ChatRoom _roomFromDoc(DocumentSnapshot<Map<String,dynamic>> doc)=>ChatRoom.fromMap({...doc.data()!,'id':doc.id});
  ChatMessage _messageFromDoc(String chatRoomId,DocumentSnapshot<Map<String,dynamic>> doc)=>ChatMessage.fromMap({...doc.data()!,'id':doc.id,'chatRoomId':chatRoomId});
}
