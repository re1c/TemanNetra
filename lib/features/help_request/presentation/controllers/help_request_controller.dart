import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/models/chat_message_model.dart';
import '../../data/repositories/help_request_repository_impl.dart';
import '../../domain/models/help_request_model.dart';
import '../../domain/repositories/help_request_repository.dart';

part 'help_request_controller.g.dart';

@riverpod
HelpRequestRepository helpRequestRepository(HelpRequestRepositoryRef ref) {
  return HelpRequestRepositoryImpl();
}

@riverpod
Stream<List<ChatMessageModel>> helpRequestMessages(
  HelpRequestMessagesRef ref,
  String requestId,
) {
  return ref.watch(helpRequestRepositoryProvider).watchChatMessages(requestId);
}

@riverpod
class HelpRequestController extends _$HelpRequestController {
  @override
  Stream<List<HelpRequestModel>> build() {
    return ref.watch(helpRequestRepositoryProvider).getMyHelpRequests();
  }

  Future<void> createTicket(String description) async {
    try {
      await ref.read(helpRequestRepositoryProvider).createHelpRequest(
            description,
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<HelpRequestModel> getOrCreateActiveHelpRequest() async {
    try {
      return ref
          .read(helpRequestRepositoryProvider)
          .getOrCreateActiveHelpRequest();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTicket(String id, String description) async {
    try {
      await ref
          .read(helpRequestRepositoryProvider)
          .updateHelpRequestDescription(
            id,
            description,
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTicket(String id) async {
    try {
      await ref.read(helpRequestRepositoryProvider).deleteHelpRequest(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendTextMessage({
    required String requestId,
    required String messageText,
  }) async {
    try {
      await ref.read(helpRequestRepositoryProvider).sendTextMessage(
            requestId: requestId,
            messageText: messageText,
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendVoiceMessage({
    required String requestId,
    required String voicePath,
  }) async {
    try {
      await ref.read(helpRequestRepositoryProvider).sendVoiceMessage(
            requestId: requestId,
            voicePath: voicePath,
          );
    } catch (e) {
      rethrow;
    }
  }
}