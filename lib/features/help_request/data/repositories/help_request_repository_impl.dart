import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/help_request_model.dart';
import '../../domain/repositories/help_request_repository.dart';

class HelpRequestRepositoryImpl implements HelpRequestRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HelpRequestRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static const String _quickHelpDescription =
      'Pengguna membutuhkan bantuan relawan.';

  CollectionReference<Map<String, dynamic>> get _helpRequestsCollection {
    return _firestore.collection('help_requests');
  }

  @override
  Stream<List<HelpRequestModel>> getMyHelpRequests() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream.value([]);
    }

    return _helpRequestsCollection
        .where('requesterId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HelpRequestModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<void> createHelpRequest(String description) async {
    final trimmedDescription = description.trim();

    if (trimmedDescription.isEmpty) {
      throw Exception('Deskripsi bantuan tidak boleh kosong.');
    }

    await _createHelpRequestWithDescription(trimmedDescription);
  }

  @override
  Future<HelpRequestModel> getOrCreateActiveHelpRequest() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Sesi pengguna tidak valid. Silakan masuk kembali.');
    }

    try {
      final snapshot = await _helpRequestsCollection
          .where('requesterId', isEqualTo: currentUser.uid)
          .get();

      final activeTickets = snapshot.docs
          .map((doc) => HelpRequestModel.fromMap(doc.data(), doc.id))
          .where((ticket) {
        return ticket.status == HelpRequestStatus.pending ||
            ticket.status == HelpRequestStatus.claimed;
      }).toList();

      activeTickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (activeTickets.isNotEmpty) {
        return activeTickets.first;
      }

      return _createHelpRequestWithDescription(_quickHelpDescription);
    } catch (e) {
      throw Exception('Gagal membuka bantuan relawan: ${e.toString()}');
    }
  }

  Future<HelpRequestModel> _createHelpRequestWithDescription(
    String description,
  ) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Sesi pengguna tidak valid. Silakan masuk kembali.');
    }

    final userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();

    final requesterName =
        userDoc.data()?['name'] as String? ?? 'Pengguna TemanNetra';

    final createdAt = Timestamp.now();
    final docRef = _helpRequestsCollection.doc();

    final data = {
      'requesterId': currentUser.uid,
      'requesterName': requesterName,
      'description': description,
      'status': HelpRequestStatus.pending.name,
      'volunteerId': null,
      'volunteerName': null,
      'createdAt': createdAt,
      'resolvedAt': null,
    };

    await docRef.set(data);

    return HelpRequestModel.fromMap(data, docRef.id);
  }

  @override
  Future<void> updateHelpRequestDescription(
    String id,
    String description,
  ) async {
    final trimmedDescription = description.trim();

    if (trimmedDescription.isEmpty) {
      throw Exception('Deskripsi bantuan tidak boleh kosong.');
    }

    try {
      final docRef = _helpRequestsCollection.doc(id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('Tiket bantuan tidak ditemukan.');
      }

      final rawStatus = docSnapshot.data()?['status'] as String? ?? '';
      final currentStatus = HelpRequestStatus.fromString(rawStatus);

      if (currentStatus != HelpRequestStatus.pending) {
        throw Exception(
          'Perubahan ditolak karena tiket ini telah diklaim atau '
          'selesai diproses oleh relawan.',
        );
      }

      await docRef.update({
        'description': trimmedDescription,
      });
    } catch (e) {
      throw Exception('Gagal memperbarui tiket: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteHelpRequest(String id) async {
    try {
      final docRef = _helpRequestsCollection.doc(id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('Tiket bantuan tidak ditemukan.');
      }

      final rawStatus = docSnapshot.data()?['status'] as String? ?? '';
      final currentStatus = HelpRequestStatus.fromString(rawStatus);

      if (currentStatus != HelpRequestStatus.pending) {
        throw Exception(
          'Tiket yang sedang berjalan tidak dapat dihapus '
          'demi integritas koordinasi relawan.',
        );
      }

      await docRef.delete();
    } catch (e) {
      throw Exception('Gagal menghapus tiket bantuan: ${e.toString()}');
    }
  }
}