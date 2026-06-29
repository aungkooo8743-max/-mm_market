import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

class ChatControllerState extends Equatable {
  final bool isSending;
  final bool isUploading;
  final double uploadProgress;
  final String? activeRoomId;
  final String? errorMessage;
  final List<ChatMessage> optimisticMessages;
  final File? selectedImage;
  const ChatControllerState({this.isSending=false,this.isUploading=false,this.uploadProgress=0,this.activeRoomId,this.errorMessage,this.optimisticMessages=const[],this.selectedImage});
  bool get hasError=>errorMessage!=null&&errorMessage!.trim().isNotEmpty;
  ChatControllerState copyWith({bool? isSending,bool? isUploading,double? uploadProgress,String? activeRoomId,bool clearActiveRoomId=false,String? errorMessage,bool clearError=false,List<ChatMessage>? optimisticMessages,File? selectedImage,bool clearSelectedImage=false})=>ChatControllerState(isSending:isSending??this.isSending,isUploading:isUploading??this.isUploading,uploadProgress:uploadProgress??this.uploadProgress,activeRoomId:clearActiveRoomId?null:(activeRoomId??this.activeRoomId),errorMessage:clearError?null:(errorMessage??this.errorMessage),optimisticMessages:optimisticMessages??this.optimisticMessages,selectedImage:clearSelectedImage?null:(selectedImage??this.selectedImage));
  ChatControllerState sending()=>copyWith(isSending:true,isUploading:false,uploadProgress:0,clearError:true);
  ChatControllerState uploading({double progress=0})=>copyWith(isSending:true,isUploading:true,uploadProgress:progress.clamp(0,1),clearError:true);
  ChatControllerState idle()=>copyWith(isSending:false,isUploading:false,uploadProgress:0,clearError:true,clearSelectedImage:true);
  ChatControllerState failure(String message)=>copyWith(isSending:false,isUploading:false,uploadProgress:0,errorMessage:message);
  ChatControllerState setActiveRoom(String roomId)=>copyWith(activeRoomId:roomId,clearError:true);
  ChatControllerState setSelectedImage(File image)=>copyWith(selectedImage:image,clearError:true);
  ChatControllerState clearSelectedImage()=>copyWith(clearSelectedImage:true,clearError:true);
  ChatControllerState addOptimisticMessage(ChatMessage m)=>copyWith(optimisticMessages:[...optimisticMessages,m],clearError:true);
  ChatControllerState removeOptimisticMessage(String id)=>copyWith(optimisticMessages:optimisticMessages.where((m)=>m.id!=id).toList());
  ChatControllerState markOptimisticMessageFailed(String id)=>copyWith(optimisticMessages:optimisticMessages.map((m)=>m.id==id?m.copyWith(status:ChatMessageStatus.failed,updatedAt:DateTime.now()):m).toList());
  @override List<Object?> get props=>[isSending,isUploading,uploadProgress,activeRoomId,errorMessage,optimisticMessages,selectedImage];
}
