import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Utilitas administratif terisolasi untuk memproses verifikasi KTP Relawan.
class AdminVerificationUtility {
  final FirebaseFirestore _firestore;
  final SupabaseClient _supabase;

  AdminVerificationUtility({
    FirebaseFirestore? firestore,
    SupabaseClient? supabase,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _supabase = supabase ?? Supabase.instance.client;

  /// Meminta Short-Lived Signed URL selama 300 detik dari bucket privat
  /// `volunteer_identity` Supabase untuk file KTP milik relawan tertentu.
  Future<String> generateSecureReviewSession(String volunteerId) async {
    final userDoc = await _firestore.collection('users').doc(volunteerId).get();
    if (!userDoc.exists) {
      throw Exception('Relawan tidak ditemukan.');
    }

    final data = userDoc.data();
    if (data == null) {
      throw Exception('Data relawan kosong.');
    }

    final ktpUrl = data['ktpUrl'] as String?;
    if (ktpUrl == null || ktpUrl.isEmpty) {
      throw Exception('File KTP belum diunggah.');
    }

    // Ekstrak path file relatif terhadap bucket 'volunteer_identity'
    String path = ktpUrl;
    if (path.startsWith('volunteer_identity/')) {
      path = path.replaceFirst('volunteer_identity/', '');
    }

    final signedUrl = await _supabase.storage
        .from('volunteer_identity')
        .createSignedUrl(path, 300);

    return signedUrl;
  }

  /// Menyetujui pendaftaran relawan dan mengubah status verifikasi menjadi `verified`.
  Future<void> approveVolunteer(String volunteerId) async {
    await _firestore.collection('users').doc(volunteerId).update({
      'verificationStatus': 'verified',
    });
  }

  /// Menolak pendaftaran relawan, mengubah status verifikasi menjadi `rejected` disertai alasan penolakan.
  Future<void> rejectVolunteer(String volunteerId, String reason) async {
    await _firestore.collection('users').doc(volunteerId).update({
      'verificationStatus': 'rejected',
      'rejectionReason': reason,
    });
  }
}
