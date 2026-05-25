import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/help_request_repository_impl.dart';
import '../../domain/models/help_request_model.dart';
import '../../domain/repositories/help_request_repository.dart';

part 'help_request_controller.g.dart';

/// Penyedia repositori tiket bantuan terkonfigurasi.
@riverpod
HelpRequestRepository helpRequestRepository(HelpRequestRepositoryRef ref) {
  return HelpRequestRepositoryImpl();
}

/// Pengendali state reaktif berbasis StreamNotifier untuk mengelola daftar tiket.
///
/// Kelas ini memantau aliran data perubahan dokumen Firestore secara real-time.
/// Method mutasi dirancang melempar error (rethrow) agar lapisan presentasi (UI)
/// dapat menangkap kegagalan secara asinkron dan memberikan respon suara instan.
@riverpod
class HelpRequestController extends _$HelpRequestController {
  @override
  Stream<List<HelpRequestModel>> build() {
    return ref.watch(helpRequestRepositoryProvider).getMyHelpRequests();
  }

  /// Membuat pengajuan tiket bantuan baru ke Firestore.
  Future<void> createTicket(String description) async {
    try {
      await ref.read(helpRequestRepositoryProvider).createHelpRequest(description);
    } catch (e) {
      // Melempar error ke lapisan UI agar ditangani oleh listener suara & taktil
      rethrow;
    }
  }

  /// Memperbarui deskripsi kebutuhan bantuan pada tiket tertentu.
  Future<void> updateTicket(String id, String description) async {
    try {
      await ref.read(helpRequestRepositoryProvider).updateHelpRequestDescription(id, description);
    } catch (e) {
      rethrow;
    }
  }

  /// Menghapus tiket bantuan secara permanen (Delete).
  Future<void> deleteTicket(String id) async {
    try {
      await ref.read(helpRequestRepositoryProvider).deleteHelpRequest(id);
    } catch (e) {
      rethrow;
    }
  }
}
