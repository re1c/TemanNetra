import '../../../../core/models/chat_message_model.dart';
import '../models/help_request_model.dart';

abstract class HelpRequestRepository {
  Stream<List<HelpRequestModel>> getMyHelpRequests();

  Future<void> createHelpRequest(String description, {String? voicePath});

  Future<HelpRequestModel> getOrCreateActiveHelpRequest();

  Future<void> updateHelpRequestDescription(String id, String description);

  Future<void> deleteHelpRequest(String id);

  Stream<List<ChatMessageModel>> watchChatMessages(String requestId);

  Future<void> sendTextMessage({
    required String requestId,
    required String messageText,
  });

  Future<void> sendVoiceMessage({
    required String requestId,
    required String voicePath,
  });

  Future<void> cancelHelpRequest(String id);

  Future<void> resolveHelpRequest(String id);
}