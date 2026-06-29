import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat_message.dart';
import '../controllers/chat_controller.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';

class ChatRoomPage extends ConsumerStatefulWidget{final String chatRoomId; const ChatRoomPage({super.key,required this.chatRoomId}); @override ConsumerState<ChatRoomPage> createState()=>_ChatRoomPageState();}
class _ChatRoomPageState extends ConsumerState<ChatRoomPage>{final _scrollController=ScrollController(); final _picker=ImagePicker(); @override void initState(){super.initState(); Future.microtask((){ref.read(chatControllerProvider.notifier).setActiveRoom(widget.chatRoomId);ref.read(chatControllerProvider.notifier).markAsRead(widget.chatRoomId);});} @override void dispose(){_scrollController.dispose();super.dispose();}
  Future<void> _pickImage() async{final p=await _picker.pickImage(source:ImageSource.gallery,imageQuality:85,maxWidth:1600); if(p==null)return; ref.read(chatControllerProvider.notifier).setSelectedImage(File(p.path));}
  Future<void> _sendText(String text) async{await ref.read(chatControllerProvider.notifier).sendTextMessage(chatRoomId:widget.chatRoomId,text:text); _scrollToBottom();}
  Future<void> _sendImage(String caption) async{await ref.read(chatControllerProvider.notifier).sendImageMessage(chatRoomId:widget.chatRoomId,caption:caption); _scrollToBottom();}
  void _scrollToBottom(){WidgetsBinding.instance.addPostFrameCallback((_){if(!_scrollController.hasClients)return; _scrollController.animateTo(0,duration:const Duration(milliseconds:250),curve:Curves.easeOut);});}
  List<ChatMessage> _merge(List<ChatMessage> remote,List<ChatMessage> optimistic)=>[...optimistic.where((m)=>m.chatRoomId==widget.chatRoomId),...remote]..sort((a,b)=>b.createdAt.compareTo(a.createdAt));
  @override Widget build(BuildContext context){final user=ref.watch(currentUserProvider); final messages=ref.watch(chatMessagesProvider(widget.chatRoomId)); final st=ref.watch(chatControllerProvider); ref.listen(chatControllerProvider,(p,n){if(!context.mounted)return; if(n.hasError)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(n.errorMessage!)));}); if(user==null)return const Scaffold(body:Center(child:Text('Chat အသုံးပြုရန် Login ဝင်ရန်လိုအပ်ပါသည်'))); return Scaffold(appBar:AppBar(title:const Text('Chat'),actions:[IconButton(onPressed:()=>ref.read(chatControllerProvider.notifier).markAsRead(widget.chatRoomId),icon:const Icon(Icons.done_all_outlined))]),body:Column(children:[Expanded(child:messages.when(loading:()=>const Center(child:CircularProgressIndicator()),error:(e,_)=>Center(child:Text(e.toString())),data:(remote){final items=_merge(remote,st.optimisticMessages); if(items.isEmpty)return const Center(child:Text('Message မရှိသေးပါ')); return ListView.separated(controller:_scrollController,reverse:true,padding:const EdgeInsets.all(12),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(context,i){final m=items[i]; return ChatBubble(message:m,currentUserId:user.uid,onDelete:m.id.startsWith('local_')?null:()=>ref.read(chatControllerProvider.notifier).deleteMessage(chatRoomId:widget.chatRoomId,messageId:m.id));});})), if(st.isUploading)LinearProgressIndicator(value:st.uploadProgress), ChatInputBar(isSending:st.isSending,selectedImage:st.selectedImage,onPickImage:_pickImage,onClearImage:()=>ref.read(chatControllerProvider.notifier).clearSelectedImage(),onSendText:_sendText,onSendImage:_sendImage)]));}
}
