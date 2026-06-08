import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:temannetra/features/help_request/domain/models/help_request_model.dart';
import 'package:temannetra/features/volunteer/data/services/voice_note_storage_service.dart';
import 'package:temannetra/features/volunteer/domain/models/chat_message_model.dart';
import 'package:temannetra/features/volunteer/domain/repositories/volunteer_repository.dart';

class VolunteerRepositoryImpl implements VolunteerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final VoiceNoteStorageService _voiceNoteStorageService;

  VolunteerRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    VoiceNoteStorageService? voiceNoteStorageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _voiceNoteStorageService =
            voiceNoteStorageService ?? VoiceNoteStorageService();

  CollectionReference<Map<String, dynamic>> get _helpRequestsCollection {
    return _firestore.collection('help_requests');
  }

  CollectionReference<Map<String, dynamic>> _messagesCollection(
    String requestId,
  ) {
    return _helpRequestsCollection.doc(requestId).collection('messages');
  }

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

  @override
  Future<void> claimHelpRequest(String requestId) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Sesi relawan tidak valid. Silakan masuk kembali.');
    }

    final volunteerName = await _getCurrentVolunteerName(currentUser.uid);
    final ticketDocRef = _helpRequestsCollection.doc(requestId);

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
  }

  @override
  Future<void> resolveHelpRequest(String requestId) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Sesi relawan tidak valid. Silakan masuk kembali.');
    }

    final ticketDocRef = _helpRequestsCollection.doc(requestId);

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
  }

  @override
  Future<void> cancelClaim(String requestId) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Sesi relawan tidak valid. Silakan masuk kembali.');
    }

    final ticketDocRef = _helpRequestsCollection.doc(requestId);

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
  }

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
  }

  @override
  Future<void> sendVoiceMessage({
    required String requestId,
    required String voicePath,
  }) async {
    if (voicePath.trim().isEmpty) {
      throw Exception('File voice note tidak valid.');
    }

    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Sesi relawan tidak valid. Silakan masuk kembali.');
    }

    final volunteerName = await _getCurrentVolunteerName(currentUser.uid);
    final ticketDocRef = _helpRequestsCollection.doc(requestId);

    await _validateTicketClaimedByCurrentVolunteer(
      ticketDocRef: ticketDocRef,
      currentUserId: currentUser.uid,
    );

    final voiceUrl = await _voiceNoteStorageService.uploadVoiceNote(
      requestId: requestId,
      localFilePath: voicePath,
    );

    final messageDocRef = _messagesCollection(requestId).doc();

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
          'Voice note hanya dapat dikirim pada tiket yang sedang Anda tangani.',
        );
      }

      transaction.set(messageDocRef, {
        'id': messageDocRef.id,
        'senderId': currentUser.uid,
        'senderName': volunteerName,
        'messageText': null,
        'messageUrl': voiceUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _validateTicketClaimedByCurrentVolunteer({
    required DocumentReference<Map<String, dynamic>> ticketDocRef,
    required String currentUserId,
  }) async {
    final ticketSnapshot = await ticketDocRef.get();

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
        volunteerId != currentUserId) {
      throw Exception(
        'Tiket ini tidak sedang ditangani oleh relawan aktif.',
      );
    }
  }

  Future<String> _getCurrentVolunteerName(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();

    return userDoc.data()?['name'] as String? ?? 'Relawan TemanNetra';
  }
}