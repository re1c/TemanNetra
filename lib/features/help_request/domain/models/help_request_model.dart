/// Definisi status operasional tiket bantuan dalam alur kerja sistem.
enum HelpRequestStatus {
  /// Tiket baru diajukan oleh tunanetra dan sedang menunggu respon relawan.
  pending,

  /// Tiket telah diambil alih dan sedang dibantu oleh salah satu relawan.
  claimed,

  /// Bantuan telah selesai diselesaikan dan tiket ditutup.
  resolved,

  /// Permintaan bantuan dibatalkan.
  cancelled;

  static HelpRequestStatus fromString(String value) {
    return HelpRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HelpRequestStatus.pending,
    );
  }
}

/// Entitas data murni Dart yang mewakili pengajuan tiket bantuan tunanetra.
///
/// Dirancang sepenuhnya immutable dengan variabel `final` dan konstruktor `const`
/// untuk menjamin konsistensi state dan keandalan data lintas layer.
class HelpRequestModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String description;
  final HelpRequestStatus status;
  final String? volunteerId;
  final String? volunteerName;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? voiceDescriptionUrl;

  const HelpRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.description,
    required this.status,
    this.volunteerId,
    this.volunteerName,
    required this.createdAt,
    this.resolvedAt,
    this.voiceDescriptionUrl,
  });

  HelpRequestModel copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? description,
    HelpRequestStatus? status,
    String? volunteerId,
    String? volunteerName,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? voiceDescriptionUrl,
  }) {
    return HelpRequestModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      description: description ?? this.description,
      status: status ?? this.status,
      volunteerId: volunteerId ?? this.volunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      voiceDescriptionUrl: voiceDescriptionUrl ?? this.voiceDescriptionUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'description': description,
      'status': status.name,
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'voiceDescriptionUrl': voiceDescriptionUrl,
    };
  }

  factory HelpRequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      
      // Menggunakan penanganan tipe dinamis (dynamic call) untuk Timestamp Firestore
      // guna menjaga kemurnian Domain Layer (tidak mengimpor cloud_firestore di domain).
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    final rawResolvedAt = map['resolvedAt'];

    return HelpRequestModel(
      id: documentId,
      requesterId: map['requesterId'] as String? ?? '',
      requesterName: map['requesterName'] as String? ?? '',
      description: map['description'] as String? ?? '',
      status: HelpRequestStatus.fromString(map['status'] as String? ?? ''),
      volunteerId: map['volunteerId'] as String?,
      volunteerName: map['volunteerName'] as String?,
      createdAt: parseDateTime(map['createdAt']),
      resolvedAt: rawResolvedAt != null ? parseDateTime(rawResolvedAt) : null,
      voiceDescriptionUrl: map['voiceDescriptionUrl'] as String?,
    );
  }
}
