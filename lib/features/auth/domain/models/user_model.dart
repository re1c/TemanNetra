/// Definisi peran pengguna untuk memfasilitasi antarmuka khusus (antarmuka
/// aksesibilitas tinggi untuk tunanetra vs dasbor standar untuk relawan).
enum UserRole {
  tunanetra,
  volunteer;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.tunanetra,
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

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String? ?? ''),
    );
  }
}
