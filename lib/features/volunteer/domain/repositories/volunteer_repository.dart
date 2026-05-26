import 'package:temannetra/features/help_request/domain/models/help_request_model.dart';

/// Kontrak operasi relawan terhadap tiket bantuan.
///
/// Repository ini sengaja menggunakan [HelpRequestModel] dari fitur help_request
/// agar representasi tiket tetap memiliki satu sumber kebenaran lintas fitur.
abstract class VolunteerRepository {
  /// Membaca daftar tiket yang masih tersedia untuk diklaim relawan.
  Stream<List<HelpRequestModel>> watchPendingHelpRequests();

  /// Membaca daftar tiket yang sedang ditangani oleh relawan aktif.
  Stream<List<HelpRequestModel>> watchMyClaimedHelpRequests();

  /// Mengklaim tiket bantuan secara atomik agar tidak terjadi double-claim.
  Future<void> claimHelpRequest(String requestId);

  /// Menandai tiket bantuan sebagai selesai.
  Future<void> resolveHelpRequest(String requestId);

  /// Membatalkan klaim dan mengembalikan tiket ke status pending.
  Future<void> cancelClaim(String requestId);
}