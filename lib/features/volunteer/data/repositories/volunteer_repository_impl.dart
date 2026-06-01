import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:temannetra/features/help_request/domain/models/help_request_model.dart';
import 'package:temannetra/features/volunteer/domain/models/chat_message_model.dart';
import 'package:temannetra/features/volunteer/domain/repositories/volunteer_repository.dart';

/// Implementasi repository relawan yang terhubung ke Cloud Firestore.
///
/// Firestore digunakan untuk menyimpan data tiket bantuan dan chat koordinasi.
/// Semua perubahan status tiket yang rawan konflik dilakukan dengan transaction
/// agar satu tiket tidak dapat diklaim oleh dua relawan secara bersamaan.
class VolunteerRepositoryImpl implements VolunteerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  VolunteerRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _helpRequestsCollection {
    return _firestore.collection('help_requests');
  }

  CollectionReference<Map<String, dynamic>> _messagesCollection(
    String requestId,
  ) {
    return _helpRequestsCollection.doc(requestId).collection('messages');
  }

  /// Membaca daftar tiket bantuan yang masih tersedia untuk diklaim relawan.
  @override
  Stream<List<HelpRequestModel>> watchPendingHelpRequests() {
    return _helpRequestsCollection
        .where('status', isEqualTo: HelpRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HelpRequestModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Membaca daftar tiket bantuan yang sedang ditangani oleh relawan aktif.
  @override
  Stream<List<HelpRequestModel>> watchMyClaimedHelpRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _helpRequestsCollection
        .where('volunteerId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: HelpRequestStatus.claimed.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HelpRequestModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Membaca pesan koordinasi pada satu tiket bantuan.
  @override
  Stream<List<ChatMessageModel>> watchChatMessages(String requestId) {
    if (requestId.isEmpty) {
      return Stream.value([]);
    }

    return _messagesCollection(requestId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Mengklaim tiket bantuan secara atomik.
  ///
  /// Transaction diperlukan karena dua relawan bisa melihat tiket pending yang sama
  /// dan menekan tombol klaim hampir bersamaan.
  @override
  Future<void> claimHelpRequest(String requestId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Sesi relawan tidak valid. Silakan masuk kembali.');
    }

    final volunteerName = await _getCurrentVolunteerName(currentUser.uid);
    final ticketDocRef = _helpRequestsCollection.doc(requestId);

    try {
      await _firestore.runTransaction((transaction) async {
        final ticketSnapshot = await transaction.get(ticketDocRef);

        if (!ticketSnapshot.exists) {
          throw Exception('Tiket bantuan tidak ditemukan.');
        }

        final data = ticketSnapshot.data();
        if (data == null) {
          throw Exception('Data tiket bantuan tidak valid.');
        }

        final currentStatus = HelpRequestStatus.fromString(
          data['status'] as String? ?? '',
        );

        if (currentStatus != HelpRequestStatus.pending) {
          throw Exception(
            'Tiket bantuan ini baru saja diklaim oleh relawan lain.',
          );
        }

        transaction.update(ticketDocRef, {
          'status': HelpRequestStatus.claimed.name,
          'volunteerId': currentUser.uid,
          'volunteerName': volunteerName,
        });
      });
    } catch (e) {
      throw Exception('Gagal mengklaim tiket bantuan: ${e.toString()}');
    }
  }

  /// Menandai tiket bantuan sebagai selesai.
  @override
  Future<void> resolveHelpRequest(String requestId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Sesi relawan tidak valid. Silakan masuk kembali.');
    }

    final ticketDocRef = _helpRequestsCollection.doc(requestId);

    try {
      await _firestore.runTransaction((transaction) async {
        final ticketSnapshot = await transaction.get(ticketDocRef);

        if (!ticketSnapshot.exists) {
          throw Exception('Tiket bantuan tidak ditemukan.');
        }

        final data = ticketSnapshot.data();
        if (data == null) {
          throw Exception('Data tiket bantuan tidak valid.');
        }

        final currentStatus = HelpRequestStatus.fromString(
          data['status'] as String? ?? '',
        );
        final volunteerId = data['volunteerId'] as String?;

        if (currentStatus != HelpRequestStatus.claimed ||
            volunteerId != currentUser.uid) {
          throw Exception(
            'Tiket ini tidak sedang ditangani oleh relawan aktif.',
          );
        }

        transaction.update(ticketDocRef, {
          'status': HelpRequestStatus.resolved.name,
          'resolvedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Gagal menyelesaikan tiket bantuan: ${e.toString()}');
    }
  }

  /// Membatalkan klaim tiket dan mengembalikannya ke daftar pending.
  ///
  /// Dalam konteks bisnis aplikasi, aksi ini adalah bentuk Delete untuk klaim aktif:
  /// klaim relawan dihapus tanpa menghapus tiket bantuan milik pengguna tunanetra.
  @override
  Future<void> cancelClaim(String requestId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Sesi relawan tidak valid. Silakan masuk kembali.');
    }

    final ticketDocRef = _helpRequestsCollection.doc(requestId);

    try {
      await _firestore.runTransaction((transaction) async {
        final ticketSnapshot = await transaction.get(ticketDocRef);

        if (!ticketSnapshot.exists) {
          throw Exception('Tiket bantuan tidak ditemukan.');
        }

        final data = ticketSnapshot.data();
        if (data == null) {
          throw Exception('Data tiket bantuan tidak valid.');
        }

        final currentStatus = HelpRequestStatus.fromString(
          data['status'] as String? ?? '',
        );
        final volunteerId = data['volunteerId'] as String?;

        if (currentStatus != HelpRequestStatus.claimed ||
            volunteerId != currentUser.uid) {
          throw Exception(
            'Klaim tidak dapat dibatalkan karena tiket ini tidak sedang '
            'ditangani oleh relawan aktif.',
          );
        }

        transaction.update(ticketDocRef, {
          'status': HelpRequestStatus.pending.name,
          'volunteerId': null,
          'volunteerName': null,
          'resolvedAt': null,
        });
      });
    } catch (e) {
      throw Exception('Gagal membatalkan klaim tiket: ${e.toString()}');
    }
  }

  /// Mengirim pesan teks koordinasi pada tiket yang sedang diklaim relawan.
  @override
  Future<void> sendTextMessage({
    required String requestId,
    required String messageText,
  }) async {
    final trimmedMessage = messageText.trim();

    if (trimmedMessage.isEmpty) {
      throw Exception('Pesan tidak boleh kosong.');
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Sesi relawan tidak valid. Silakan masuk kembali.');
    }

    final volunteerName = await _getCurrentVolunteerName(currentUser.uid);
    final ticketDocRef = _helpRequestsCollection.doc(requestId);
    final messageDocRef = _messagesCollection(requestId).doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final ticketSnapshot = await transaction.get(ticketDocRef);

        if (!ticketSnapshot.exists) {
          throw Exception('Tiket bantuan tidak ditemukan.');
        }

        final data = ticketSnapshot.data();
        if (data == null) {
          throw Exception('Data tiket bantuan tidak valid.');
        }

        final currentStatus = HelpRequestStatus.fromString(
          data['status'] as String? ?? '',
        );
        final volunteerId = data['volunteerId'] as String?;

        if (currentStatus != HelpRequestStatus.claimed ||
            volunteerId != currentUser.uid) {
          throw Exception(
            'Pesan hanya dapat dikirim pada tiket yang sedang Anda tangani.',
          );
        }

        transaction.set(messageDocRef, {
          'id': messageDocRef.id,
          'senderId': currentUser.uid,
          'senderName': volunteerName,
          'messageText': trimmedMessage,
          'messageUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Gagal mengirim pesan: ${e.toString()}');
    }
  }

  Future<String> _getCurrentVolunteerName(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['name'] as String? ?? 'Relawan TemanNetra';
  }
}