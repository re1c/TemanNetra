import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_controller.g.dart';

/// Penyedia repositori autentikasi untuk memfasilitasi injeksi dependensi.
/// 
/// Menggunakan provider ini memungkinkan pemisahan total instansiasi riil 
/// sehingga mempermudah proses penyuntikan tiruan (mocking) saat pengujian.
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl();
}

/// Pengendali state autentikasi reaktif berbasis StreamNotifier.
/// 
/// Kelas ini bertindak sebagai jembatan antara lapisan data (Firebase stream) 
/// dengan lapisan antarmuka (UI). Karena berbasis StreamNotifier, Riverpod akan
/// secara otomatis memperbarui state UI secara reaktif ketika ada perubahan 
/// sesi dari server Firebase (login/logout/token revoking).
@riverpod
class AuthController extends _$AuthController {
  @override
  Stream<UserModel?> build() {
    // Melakukan observasi reaktif terhadap aliran data perubahan status autentikasi.
    return ref.watch(authRepositoryProvider).authStateChanges;
  }
}

/// Pengendali mutasi autentikasi (Sign In, Sign Up, Sign Out) berbasis AsyncNotifier.
/// 
/// Ini memisahkan status loading dan error selama proses pendaftaran atau masuk
/// dari aliran status autentikasi global agar tidak memicu layar System Error di main.dart.
@riverpod
class AuthMutationController extends _$AuthMutationController {
  @override
  FutureOr<void> build() {}

  /// Mengeksekusi verifikasi masuk pengguna menggunakan kredensial email.
  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(email, password);
    });
  }

  /// Mendaftarkan pengguna baru ke Firebase Auth dan merekam profil ke Firestore.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role,
      );
    });
  }

  /// Mengakhiri sesi pengguna aktif saat ini.
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
    });
  }
}
