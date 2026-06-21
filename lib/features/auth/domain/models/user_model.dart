/// Definisi peran pengguna untuk memfasilitasi antarmuka khusus (antarmuka
/// aksesibilitas tinggi untuk tunanetra vs dasbor standar untuk relawan).
enum UserRole {
  tunanetra,
  volunteer,
  admin;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.tunanetra,
    );
  }
}

/// Status verifikasi identitas (KTP) bagi relawan.
enum VerificationStatus {
  unverified,
  pending,
  verified,
  rejected;

  static VerificationStatus fromString(String value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VerificationStatus.unverified,
    );
  }
}

/// Entitas data murni Dart yang mewakili profil pengguna di dalam sistem.
/// Model ini dirancang immutable menggunakan variabel final untuk mencegah
/// perubahan state yang tidak sengaja selama siklus hidup aplikasi.
class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final VerificationStatus verificationStatus;
  final String? ktpUrl;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.verificationStatus = VerificationStatus.unverified,
    this.ktpUrl,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    VerificationStatus? verificationStatus,
    String? ktpUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      ktpUrl: ktpUrl ?? this.ktpUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name,
      'verificationStatus': verificationStatus.name,
      'ktpUrl': ktpUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String? ?? ''),
      verificationStatus: VerificationStatus.fromString(
        map['verificationStatus'] as String? ?? '',
      ),
      ktpUrl: map['ktpUrl'] as String?,
    );
  }
}
