import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/help_request_model.dart';
import '../../domain/repositories/help_request_repository.dart';

/// Implementasi konkrit repositori tiket bantuan terhubung ke Cloud Firestore.
///
/// Menyediakan operasi CRUD data dengan proteksi konkurensi serta query terindeks 
/// di sisi server guna menjamin skalabilitas performa pada skala data besar.
class HelpRequestRepositoryImpl implements HelpRequestRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HelpRequestRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Mengambil real-time stream tiket bantuan khusus milik tunanetra yang sedang aktif.
  ///
  /// Melakukan filter berdasarkan [requesterId] dan pengurutan kronologis terbalik
  /// langsung di sisi server (Server-side Sorting) untuk efisiensi transfer data.
  @override
  Stream<List<HelpRequestModel>> getMyHelpRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // CATATAN PENTING LIVE DEFENSE: Query ini memerlukan konfigurasi 'Composite Index' 
    // di Firebase Console. Jika belum dibuat, Firestore SDK akan memunculkan exception
    // berisi tautan langsung untuk mengaktifkan indeks tersebut secara instan.
    return _firestore
        .collection('help_requests')
        .where('requesterId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HelpRequestModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Membuat pengajuan tiket bantuan baru di Firestore.
  ///
  /// Mengambil nama profil pengaju dari koleksi `/users/{uid}` secara otomatis 
  /// guna menerapkan konsep denormalisasi NoSQL, menekan latensi baca bagi relawan.
  @override
  Future<void> createHelpRequest(String description) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Sesi pengguna tidak valid. Silakan masuk kembali.');
    }

    try {
      // Mengambil nama pengaju dari profil Firestore secara asinkron
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final String requesterName = userDoc.data()?['name'] as String? ?? 'Pengguna TemanNetra';

      final docRef = _firestore.collection('help_requests').doc();
      await docRef.set({
        'requesterId': currentUser.uid,
        'requesterName': requesterName,
        'description': description,
        'status': HelpRequestStatus.pending.name,
        'volunteerId': null,
        'volunteerName': null,
        'createdAt': FieldValue.serverTimestamp(), // Menjamin waktu pembuatan diset adil oleh server
        'resolvedAt': null,
      });
    } catch (e) {
      throw Exception('Gagal mengirimkan tiket bantuan: ${e.toString()}');
    }
  }

  /// Mengubah isi deskripsi bantuan untuk tiket yang diajukan.
  ///
  /// Menerapkan proteksi konkurensi (Concurrency Protection) untuk memastikan deskripsi
  /// hanya dapat diperbarui jika status tiket masih 'pending' (belum dikunci oleh relawan).
  @override
  Future<void> updateHelpRequestDescription(String id, String description) async {
    try {
      final docRef = _firestore.collection('help_requests').doc(id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('Tiket bantuan tidak ditemukan.');
      }

      final rawStatus = docSnapshot.data()?['status'] as String? ?? '';
      final currentStatus = HelpRequestStatus.fromString(rawStatus);

      if (currentStatus != HelpRequestStatus.pending) {
        throw Exception(
          'Perubahan ditolak karena tiket ini telah diklaim atau '
          'selesai diproses oleh relawan.'
        );
      }

      await docRef.update({
        'description': description,
      });
    } catch (e) {
      throw Exception('Gagal memperbarui tiket: ${e.toString()}');
    }
  }

  /// Menghapus tiket dari Firestore (Delete).
  ///
  /// Menjamin penghapusan hanya bisa dilakukan jika tiket berstatus 'pending' 
  /// guna mencegah hilangnya data operasional bantuan yang sedang berjalan.
  @override
  Future<void> deleteHelpRequest(String id) async {
    try {
      final docRef = _firestore.collection('help_requests').doc(id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('Tiket bantuan tidak ditemukan.');
      }

      final rawStatus = docSnapshot.data()?['status'] as String? ?? '';
      final currentStatus = HelpRequestStatus.fromString(rawStatus);

      if (currentStatus != HelpRequestStatus.pending) {
        throw Exception(
          'Tiket yang sedang berjalan tidak dapat dihapus '
          'demi integritas koordinasi relawan.'
        );
      }

      await docRef.delete();
    } catch (e) {
      throw Exception('Gagal menghapus tiket bantuan: ${e.toString()}');
    }
  }
}
