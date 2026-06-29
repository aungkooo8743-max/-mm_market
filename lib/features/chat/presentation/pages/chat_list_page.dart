import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_room_tile.dart';
class ChatListPage extends ConsumerWidget{const ChatListPage({super.key}); @override Widget build(BuildContext context,WidgetRef ref){final user=ref.watch(currentUserProvider); final rooms=ref.watch(myChatRoomsProvider); if(user==null)return const Scaffold(body:Center(child:Text('Login required'))); return Scaffold(appBar:AppBar(title:const Text('Chats')),body:rooms.when(loading:()=>const Center(child:CircularProgressIndicator()),error:(e,_)=>Center(child:Text(e.toString())),data:(items)=>items.isEmpty?const Center(child:Text('Chat မရှိသေးပါ')):ListView.builder(itemCount:items.length,itemBuilder:(_,i)=>ChatRoomTile(room:items[i],currentUserId:user.uid,onTap:()=>context.push(AppRoutes.chatRoomPath(items[i].id))))));}}
