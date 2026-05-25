import '../models/help_request_model.dart';

/// Kontrak repositori tiket bantuan pada domain layer.
///
/// Mengabstraksikan operasi CRUD data tiket agar terlepas dari framework database Firestore.
abstract class HelpRequestRepository {
  
  /// Mengambil aliran data reaktif (real-time stream) tiket bantuan milik tunanetra yang aktif.
  Stream<List<HelpRequestModel>> getMyHelpRequests();

  /// Membuat pengajuan tiket bantuan baru.
  Future<void> createHelpRequest(String description);

  /// Mengubah deskripsi kebutuhan bantuan pada tiket tertentu.
  Future<void> updateHelpRequestDescription(String id, String description);

  /// Menghapus tiket bantuan secara permanen untuk privasi (Delete).
  Future<void> deleteHelpRequest(String id);
}
