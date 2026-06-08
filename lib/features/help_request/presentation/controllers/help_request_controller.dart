import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/help_request_repository_impl.dart';
import '../../domain/models/help_request_model.dart';
import '../../domain/repositories/help_request_repository.dart';

part 'help_request_controller.g.dart';

@riverpod
HelpRequestRepository helpRequestRepository(HelpRequestRepositoryRef ref) {
  return HelpRequestRepositoryImpl();
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
}