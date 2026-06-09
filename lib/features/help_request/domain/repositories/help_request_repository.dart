import '../models/help_request_model.dart';

abstract class HelpRequestRepository {
  Stream<List<HelpRequestModel>> getMyHelpRequests();

  Future<void> createHelpRequest(String description);

  Future<HelpRequestModel> getOrCreateActiveHelpRequest();

  Future<void> updateHelpRequestDescription(String id, String description);

  Future<void> deleteHelpRequest(String id);
}