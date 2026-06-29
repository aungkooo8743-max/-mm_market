import 'dart:io';
import '../entities/chat_message.dart';
import '../entities/chat_room.dart';

class ChatMessagesPageResult { final List<ChatMessage> items; final Object? nextCursor; final bool hasMore; const ChatMessagesPageResult({required this.items, this.nextCursor, required this.hasMore}); }
abstract class ChatRepository {
  Stream<List<ChatRoom>> watchMyChatRooms({required String userId, int limit = 30});
  Stream<ChatRoom?> watchChatRoom({required String chatRoomId});
  Stream<List<ChatMessage>> watchMessages({required String chatRoomId, int limit = 50});
  Future<ChatRoom?> getChatRoom({required String chatRoomId});
  Future<ChatRoom?> getExistingRoomForProduct({required String productId, required String buyerId, required String sellerId});
  Future<String> createOrGetRoom({required String productId, required String buyerId, required String sellerId});
  Future<String> sendTextMessage({required String chatRoomId, required String senderId, required String text});
  Future<String> sendImageMessage({required String chatRoomId, required String senderId, required File image, String? caption});
  Future<ChatMessagesPageResult> getMessagesPage({required String chatRoomId, int limit = 50, Object? cursor});
  Future<void> markAsRead({required String chatRoomId, required String userId});
  Future<void> archiveRoom({required String chatRoomId, required String requesterId});
  Future<void> blockRoom({required String chatRoomId, required String requesterId});
  Future<void> deleteMessage({required String chatRoomId, required String messageId, required String requesterId});
  Future<bool> isParticipant({required String chatRoomId, required String userId});
}
