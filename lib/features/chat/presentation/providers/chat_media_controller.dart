import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/repositories/chat_media_repository.dart';

import 'chat_providers.dart';

final chatMediaControllerProvider =
    StateNotifierProvider<ChatMediaController, ChatMediaState>(
        (ref) => ChatMediaController(ref));

class ChatMediaController extends StateNotifier<ChatMediaState> {
  final Ref ref;
  ChatMediaController(this.ref) : super(const ChatMediaState());

  Future<void> uploadAndSendImage({
    required String roomId,
    required File image,
    String? caption,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(errorMessage: 'Login required');
      return;
    }
    state = state.copyWith(isUploading: true, errorMessage: null);
    CrashlyticsService.log('chatImage upload started: roomId=$roomId, uid=${user.uid}');
    try {
      // Upload image to Storage via ChatMediaRepository.
      await sl<ChatMediaRepository>().uploadChatImage(
        roomId: roomId,
        senderId: user.uid,
        image: image,
      );
      // Send image message via ChatRepository (creates Firestore document).
      await ref.read(chatRepositoryProvider).sendImageMessage(
            chatRoomId: roomId,
            senderId: user.uid,
            image: image,
            caption: caption,
          );
      ref.invalidate(chatMessagesProvider(roomId));
      ref.invalidate(chatRoomProvider(roomId));
      ref.invalidate(myChatRoomsProvider);
      CrashlyticsService.log('chatImage upload success: roomId=$roomId');
      state = state.copyWith(isUploading: false, success: true);
    } catch (e, st) {
      unawaited(CrashlyticsService.recordStorageError(
        e, st,
        operation: 'uploadAndSendChatImage',
        storagePath: 'chats/$roomId',
      ));
      state = state.copyWith(isUploading: false, errorMessage: e.toString());
    }
  }
}

class ChatMediaState {
  final bool isUploading;
  final bool success;
  final String? errorMessage;

  const ChatMediaState({
    this.isUploading = false,
    this.success = false,
    this.errorMessage,
  });

  ChatMediaState copyWith({
    bool? isUploading,
    bool? success,
    String? errorMessage,
  }) =>
      ChatMediaState(
        isUploading: isUploading ?? this.isUploading,
        success: success ?? this.success,
        errorMessage: errorMessage,
      );
}
