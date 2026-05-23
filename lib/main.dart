import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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

class TemanNetraApp extends StatelessWidget {
  const TemanNetraApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      
      home: const TempHomeScreen(),
    );
  }
}

class TempHomeScreen extends StatelessWidget {
  const TempHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TemanNetra'),
        centerTitle: true,
      ),
      body: Center(
        child: Semantics(
          label: 'Selamat datang di aplikasi TemanNetra. Tekan dua kali untuk mulai menjelajah.',
          focused: true,
          child: const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'TemanNetra\n(Aksesibilitas & Inklusivitas Terkoneksi)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
