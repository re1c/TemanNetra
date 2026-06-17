import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementasi repositori autentikasi yang terintegrasi dengan Firebase.
/// 
/// Kelas ini menggabungkan layanan Firebase Auth untuk kredensial login dan 
/// Cloud Firestore untuk menyimpan data otorisasi peran pengguna.
class AuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserModel?> get authStateChanges {
    // Menggunakan asyncMap untuk menggabungkan data aliran autentikasi Firebase
    // dengan data profil Firestore secara asinkronus pada setiap perubahan state.
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _fetchUserData(firebaseUser.uid);
    });
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw Exception('User authentication failed.');
      }

      final userModel = await _fetchUserData(credential.user!.uid);
      if (userModel == null) {
        throw Exception('User profile not found in database.');
      }

      return userModel;
    } catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User creation failed.');
      }

      final userModel = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        role: role,
      );

      // Profil wajib ditulis ke Firestore segera setelah pembuatan akun di Firebase Auth.
      // Jika penulisan Firestore gagal, status akun di Auth dianggap tidak valid 
      // dari sudut pandang hak akses otorisasi aplikasi (RBAC).
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel;
    } catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return null;
    return _fetchUserData(currentUser.uid);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Mengambil data profil dari Firestore berdasarkan identifier unik.
  Future<UserModel?> _fetchUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Exception _mapAuthException(dynamic e) {
    if (e is fb.FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return Exception('Email ini sudah terdaftar. Silakan gunakan email lain atau masuk.');
        case 'invalid-credential':
          return Exception('Email atau password salah. Silakan periksa kembali.');
        case 'weak-password':
          return Exception('Password terlalu lemah. Gunakan minimal 6 karakter.');
        case 'invalid-email':
          return Exception('Format email tidak valid.');
        case 'user-not-found':
          return Exception('Akun dengan email ini tidak ditemukan.');
        case 'wrong-password':
          return Exception('Kata sandi yang Anda masukkan salah.');
        case 'network-request-failed':
          return Exception('Koneksi internet bermasalah. Silakan periksa koneksi Anda.');
        default:
          return Exception('Terjadi kesalahan otentikasi: ${e.message ?? e.code}');
      }
    }
    if (e is Exception) {
      return e;
    }
    return Exception(e.toString());
  }
}
