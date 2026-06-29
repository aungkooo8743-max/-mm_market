import 'package:equatable/equatable.dart';
import '../../../../core/utils/date_parser.dart';
import '../../../../core/utils/enum_parser.dart';
import '../../../../core/utils/map_utils.dart';

enum ChatMessageType { text, image, system }
enum ChatMessageStatus { sending, sent, delivered, read, failed, deleted }
class ChatMessage extends Equatable {
  final String id, chatRoomId, senderId, text;
  final ChatMessageType type;
  final ChatMessageStatus status;
  final String? imageUrl, localImagePath;
  final DateTime createdAt, updatedAt;
  final DateTime? readAt;
  final bool isDeleted;
  const ChatMessage({required this.id, required this.chatRoomId, required this.senderId, this.text='', this.type=ChatMessageType.text, this.status=ChatMessageStatus.sent, this.imageUrl, this.localImagePath, required this.createdAt, required this.updatedAt, this.readAt, this.isDeleted=false});
  bool get isText=>type==ChatMessageType.text; bool get isImage=>type==ChatMessageType.image; bool isMine(String userId)=>senderId==userId;
  ChatMessage copyWith({String? id,String? chatRoomId,String? senderId,String? text,ChatMessageType? type,ChatMessageStatus? status,String? imageUrl,bool clearImageUrl=false,String? localImagePath,bool clearLocalImagePath=false,DateTime? createdAt,DateTime? updatedAt,DateTime? readAt,bool clearReadAt=false,bool? isDeleted})=>ChatMessage(id:id??this.id,chatRoomId:chatRoomId??this.chatRoomId,senderId:senderId??this.senderId,text:text??this.text,type:type??this.type,status:status??this.status,imageUrl:clearImageUrl?null:(imageUrl??this.imageUrl),localImagePath:clearLocalImagePath?null:(localImagePath??this.localImagePath),createdAt:createdAt??this.createdAt,updatedAt:updatedAt??this.updatedAt,readAt:clearReadAt?null:(readAt??this.readAt),isDeleted:isDeleted??this.isDeleted);
  Map<String,dynamic> toMap()=>{'chatRoomId':chatRoomId,'senderId':senderId,'text':text,'type':type.name,'status':status.name,'imageUrl':imageUrl,'createdAt':createdAt.toIso8601String(),'updatedAt':updatedAt.toIso8601String(),'readAt':readAt?.toIso8601String(),'isDeleted':isDeleted};
  factory ChatMessage.fromMap(Map<String,dynamic> map)=>ChatMessage(id:MapUtils.stringValue(map,'id'),chatRoomId:MapUtils.stringValue(map,'chatRoomId'),senderId:MapUtils.stringValue(map,'senderId'),text:MapUtils.stringValue(map,'text', fallback: MapUtils.stringValue(map, 'message')),type:EnumParser.fromName(values:ChatMessageType.values,name:(map['type'] as String?),fallback:ChatMessageType.text),status:EnumParser.fromName(values:ChatMessageStatus.values,name:map['status'] as String?,fallback:ChatMessageStatus.sent),imageUrl:map['imageUrl'] as String?,createdAt:DateParser.fromValue(map['createdAt'])??DateTime.now(),updatedAt:DateParser.fromValue(map['updatedAt'])??DateTime.now(),readAt:DateParser.fromValue(map['readAt']),isDeleted:MapUtils.boolValue(map,'isDeleted'));
  @override List<Object?> get props=>[id,chatRoomId,senderId,text,type,status,imageUrl,localImagePath,createdAt,updatedAt,readAt,isDeleted];
}
