import 'package:equatable/equatable.dart';
import '../../../../core/utils/date_parser.dart';
import '../../../../core/utils/enum_parser.dart';
import '../../../../core/utils/map_utils.dart';

enum ChatRoomStatus { active, archived, blocked, deleted }
class ChatRoom extends Equatable {
  final String id, productId, sellerId, buyerId;
  final List<String> participantIds;
  final String? lastMessageText, lastMessageSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;
  final ChatRoomStatus status;
  final DateTime createdAt, updatedAt;
  const ChatRoom({required this.id, required this.productId, required this.sellerId, required this.buyerId, required this.participantIds, this.lastMessageText, this.lastMessageSenderId, this.lastMessageAt, this.unreadCounts = const {}, this.status = ChatRoomStatus.active, required this.createdAt, required this.updatedAt});
  bool isParticipant(String userId) => participantIds.contains(userId);
  String otherParticipantId(String currentUserId) => currentUserId == sellerId ? buyerId : sellerId;
  int unreadCountFor(String userId) => unreadCounts[userId] ?? 0;
  Map<String,dynamic> toMap()=>{'productId':productId,'sellerId':sellerId,'buyerId':buyerId,'participantIds':participantIds,'lastMessageText':lastMessageText,'lastMessageSenderId':lastMessageSenderId,'lastMessageAt':lastMessageAt?.toIso8601String(),'unreadCounts':unreadCounts,'status':status.name,'createdAt':createdAt.toIso8601String(),'updatedAt':updatedAt.toIso8601String()};
  factory ChatRoom.fromMap(Map<String,dynamic> map){ final raw=map['unreadCounts']; final unread=<String,int>{}; if(raw is Map){ raw.forEach((k,v)=>unread[k.toString()]=int.tryParse(v.toString())??0); } return ChatRoom(id:MapUtils.stringValue(map,'id'), productId:MapUtils.stringValue(map,'productId'), sellerId:MapUtils.stringValue(map,'sellerId'), buyerId:MapUtils.stringValue(map,'buyerId'), participantIds:MapUtils.stringListValue(map,'participantIds'), lastMessageText:map['lastMessageText'] as String?, lastMessageSenderId:map['lastMessageSenderId'] as String?, lastMessageAt:DateParser.fromValue(map['lastMessageAt']), unreadCounts:unread, status:EnumParser.fromName(values:ChatRoomStatus.values,name:map['status'] as String?,fallback:ChatRoomStatus.active), createdAt:DateParser.fromValue(map['createdAt'])??DateTime.now(), updatedAt:DateParser.fromValue(map['updatedAt'])??DateTime.now()); }
  @override List<Object?> get props=>[id,productId,sellerId,buyerId,participantIds,lastMessageText,lastMessageSenderId,lastMessageAt,unreadCounts,status,createdAt,updatedAt];
}
