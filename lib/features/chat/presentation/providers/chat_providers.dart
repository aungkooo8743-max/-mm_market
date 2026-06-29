import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';
import '../controllers/chat_controller.dart';
import '../controllers/chat_controller_state.dart';

final chatRepositoryProvider=Provider<ChatRepository>((ref)=>sl<ChatRepository>());
final myChatRoomsProvider=StreamProvider<List<ChatRoom>>((ref){final user=ref.watch(currentUserProvider); if(user==null)return const Stream.empty(); return ref.watch(chatRepositoryProvider).watchMyChatRooms(userId:user.uid);});
final chatRoomProvider=StreamProvider.family<ChatRoom?,String>((ref,id)=>ref.watch(chatRepositoryProvider).watchChatRoom(chatRoomId:id));
final chatMessagesProvider=StreamProvider.family<List<ChatMessage>,String>((ref,id)=>ref.watch(chatRepositoryProvider).watchMessages(chatRoomId:id));
final unreadChatCountProvider=Provider<int>((ref){final user=ref.watch(currentUserProvider); final rooms=ref.watch(myChatRoomsProvider); if(user==null)return 0; return rooms.maybeWhen(data:(items)=>items.fold<int>(0,(sum,r)=>sum+r.unreadCountFor(user.uid)),orElse:()=>0);});
final activeChatRoomIdProvider=Provider<String?>((ref)=>ref.watch(chatControllerProvider).activeRoomId);
final chatControllerStateProvider=Provider<ChatControllerState>((ref)=>ref.watch(chatControllerProvider));
