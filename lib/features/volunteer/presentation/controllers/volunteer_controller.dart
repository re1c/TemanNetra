import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temannetra/features/help_request/domain/models/help_request_model.dart';
import 'package:temannetra/features/volunteer/data/repositories/volunteer_repository_impl.dart';
import 'package:temannetra/core/models/chat_message_model.dart';
import 'package:temannetra/features/volunteer/domain/repositories/volunteer_repository.dart';

part 'volunteer_controller.g.dart';

@riverpod
VolunteerRepository volunteerRepository(VolunteerRepositoryRef ref) {
  return VolunteerRepositoryImpl();
}

@riverpod
Stream<List<HelpRequestModel>> pendingHelpRequests(
  PendingHelpRequestsRef ref,
) {
  return ref.watch(volunteerRepositoryProvider).watchPendingHelpRequests();
}

@riverpod
Stream<List<HelpRequestModel>> myClaimedHelpRequests(
  MyClaimedHelpRequestsRef ref,
) {
  return ref.watch(volunteerRepositoryProvider).watchMyClaimedHelpRequests();
}

@riverpod
Stream<List<ChatMessageModel>> chatMessages(
  ChatMessagesRef ref,
  String requestId,
) {
  return ref.watch(volunteerRepositoryProvider).watchChatMessages(requestId);
}

@riverpod
class VolunteerController extends _$VolunteerController {
  @override
  FutureOr<void> build() {}

  Future<void> claimHelpRequest(String requestId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(volunteerRepositoryProvider).claimHelpRequest(requestId);
    });
  }

  Future<void> resolveHelpRequest(String requestId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(volunteerRepositoryProvider).resolveHelpRequest(requestId);
    });
  }

  Future<void> cancelClaim(String requestId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(volunteerRepositoryProvider).cancelClaim(requestId);
    });
  }

  Future<void> sendTextMessage({
    required String requestId,
    required String messageText,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(volunteerRepositoryProvider).sendTextMessage(
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
      await ref.read(volunteerRepositoryProvider).sendVoiceMessage(
            requestId: requestId,
            voicePath: voicePath,
          );
    });
  }
}