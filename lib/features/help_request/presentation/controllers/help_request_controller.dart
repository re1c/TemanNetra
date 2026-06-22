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
Stream<List<HelpRequestModel>> myHelpRequests(MyHelpRequestsRef ref) {
  return ref.watch(helpRequestRepositoryProvider).getMyHelpRequests();
}

@riverpod
class HelpRequestController extends _$HelpRequestController {
  @override
  FutureOr<void> build() {
    // State is AsyncValue<void> representing status of mutation
  }

  Future<void> createTicket(String description, {String? voicePath}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(helpRequestRepositoryProvider).createHelpRequest(
            description,
            voicePath: voicePath,
          );
    });
  }

  Future<void> cancelHelpRequest(String id) async {
    state = const AsyncLoading();
    ref.invalidate(helpRequestMessagesProvider(id));
    ref.invalidate(myHelpRequestsProvider);
    state = await AsyncValue.guard(() async {
      await ref.read(helpRequestRepositoryProvider).cancelHelpRequest(id);
    });
  }

  Future<void> resolveHelpRequest(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(helpRequestRepositoryProvider).resolveHelpRequest(id);
    });
  }

  Future<HelpRequestModel> getOrCreateActiveHelpRequest() async {
    state = const AsyncLoading();
    HelpRequestModel? ticket;
    state = await AsyncValue.guard(() async {
      ticket = await ref
          .read(helpRequestRepositoryProvider)
          .getOrCreateActiveHelpRequest();
    });
    if (state.hasError) {
      throw state.error!;
    }
    return ticket!;
  }

  Future<void> updateTicket(String id, String description) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(helpRequestRepositoryProvider)
          .updateHelpRequestDescription(
            id,
            description,
          );
    });
  }

  Future<void> deleteTicket(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(helpRequestRepositoryProvider).deleteHelpRequest(id);
    });
  }

  Future<void> sendTextMessage({
    required String requestId,
    required String messageText,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(helpRequestRepositoryProvider).sendTextMessage(
            requestId: requestId,
            messageText: messageText,
          );
    });
  }

  Future<void> sendVoiceMessage({
    required String requestId,
    required String voicePath,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(helpRequestRepositoryProvider).sendVoiceMessage(
            requestId: requestId,
            voicePath: voicePath,
          );
    });
  }
}