import '../models/user_model.dart';

/// Kontrak repositori autentikasi yang berada pada domain layer.
/// 
/// Abstraksi ini dibuat menggunakan abstract class untuk melepaskan ketergantungan
/// langsung antara presentasi/bisnis logika dengan implementasi Firebase SDK. Hal
/// ini mempermudah pembuatan mock data selama pengujian unit serta mempermudah
/// proses migrasi database backend di masa mendatang tanpa mengganggu alur UI.
abstract class AuthRepository {
  
  /// Mengamati perubahan status autentikasi pengguna secara real-time.
  /// 
  /// Digunakan agar aplikasi dapat merespon transisi login/logout dari sisi
  /// Firebase server secara langsung (reactive routing).
  Stream<UserModel?> get authStateChanges;

  /// Melakukan login pengguna menggunakan email dan sandi.
  Future<UserModel> signInWithEmailAndPassword(String email, String password);

  /// Mendaftarkan pengguna baru serta mencatat profil dan peran mereka di database.
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  });

  /// Mengambil data detail profil pengguna saat ini secara asinkronus.
  Future<UserModel?> getCurrentUserData();

  /// Keluar dari sesi autentikasi pengguna.
  Future<void> signOut();
}
