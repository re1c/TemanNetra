import 'package:temannetra/features/help_request/domain/models/help_request_model.dart';
import 'package:temannetra/core/models/chat_message_model.dart';

abstract class VolunteerRepository {
  Stream<List<HelpRequestModel>> watchPendingHelpRequests();

  Stream<List<HelpRequestModel>> watchMyClaimedHelpRequests();

  Stream<List<ChatMessageModel>> watchChatMessages(String requestId);

  Future<void> claimHelpRequest(String requestId);

  Future<void> resolveHelpRequest(String requestId);

  Future<void> cancelClaim(String requestId);

  Future<void> sendTextMessage({
    required String requestId,
    required String messageText,
  });

  Future<void> sendVoiceMessage({
    required String requestId,
    required String voicePath,
  });
}