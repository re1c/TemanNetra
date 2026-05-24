import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/domain/models/user_model.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/tunanetra_home_screen.dart';
import 'features/auth/presentation/screens/volunteer_home_screen.dart';

void main() async {
  // Menjamin inisialisasi binding widget Flutter sebelum menjalankan kode asinkronus
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase menggunakan opsi multiplatform terkonfigurasi otomatis
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Diposisikan di root aplikasi untuk mendukung manajemen state terdistribusi Riverpod
  runApp(
    const ProviderScope(
      child: TemanNetraApp(),
    ),
  );
}

class TemanNetraApp extends ConsumerWidget {
  const TemanNetraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau status sesi pengguna secara reaktif untuk memicu routing otomatis.
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'TemanNetra',
      debugShowCheckedModeBanner: false,
      
      // Tema standard dengan kontras tinggi khusus low vision (WCAG 2.2 compliant)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD700), // Warna aksen kuning terang untuk visibilitas tinggi
          brightness: Brightness.dark,       // Latar belakang gelap bawaan untuk mengurangi ketegangan mata
          primary: const Color(0xFFFFD700),
          surface: const Color(0xFF121212),
        ),
        
        // Memastikan ukuran area ketuk (tap targets) tombol minimum memenuhi standar aksesibilitas
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }
          // Mengarahkan pengguna secara reaktif ke layar beranda spesifik berdasarkan perannya.
          if (user.role == UserRole.tunanetra) {
            return const TunanetraHomeScreen();
          } else {
            return const VolunteerHomeScreen();
          }
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => Scaffold(
          body: Center(
            child: Semantics(
              label: 'Terjadi kesalahan sistem: $error',
              focused: true,
              child: Text(
                'System Error\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

