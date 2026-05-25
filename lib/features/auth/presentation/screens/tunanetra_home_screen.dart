import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/tts_service.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../help_request/presentation/screens/help_request_history_screen.dart';
import '../controllers/auth_controller.dart';

/// Halaman beranda utama khusus untuk pengguna penyandang disabilitas netra.
///
/// Menyediakan navigasi suara cepat, getaran taktil, dan area sentuh kontras tinggi
/// untuk mengoperasikan asisten visual berbasis Gemini AI.
class TunanetraHomeScreen extends ConsumerWidget {
  const TunanetraHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'TemanNetra Beranda',
          style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
        ),
        actions: [
          Semantics(
            label: 'Tombol Keluar Akun',
            hint: 'Ketuk dua kali untuk melakukan sign out dari akun Anda',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFFFD700), size: 28),
              onPressed: () {
                ref.read(hapticServiceProvider).vibrateClick();
                ref.read(ttsServiceProvider).speak('Keluar dari akun Anda.');
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Deskripsi ucapan beranda reaktif yang dibaca saat layar dimuat
              Semantics(
                label: 'Selamat datang di beranda TemanNetra. Mode tunanetra aktif.',
                focused: true,
                child: const Text(
                  'Halo, TemanNetra',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Asisten AI siap membantu Anda memahami objek dan teks di sekitar Anda secara mandiri.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Tombol utama Buka Asisten AI berukuran super besar (Aksesibilitas Tinggi)
              Semantics(
                label: 'Tombol Buka Kamera Asisten AI',
                hint: 'Ketuk dua kali untuk mengaktifkan asisten kamera pembaca objek dan teks',
                button: true,
                child: SizedBox(
                  height: 120, // Tinggi super longgar agar sangat mudah ditekan oleh pengguna tunanetra
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      ref.read(hapticServiceProvider).vibrateClick();
                      // Membuka layar asisten AI kamera
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AiAssistantScreen(),
                        ),
                      );
                    },
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility, size: 48, color: Colors.black),
                        SizedBox(height: 8),
                        Text(
                          'BUKA ASISTEN AI',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol kedua Daftar Bantuan Saya (Aksesibilitas Tinggi)
              Semantics(
                label: 'Tombol Buka Daftar Bantuan Saya',
                hint: 'Ketuk dua kali untuk melihat riwayat dan memantau status tiket bantuan Anda.',
                button: true,
                child: SizedBox(
                  height: 120,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFD700), width: 3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      ref.read(hapticServiceProvider).vibrateClick();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HelpRequestHistoryScreen(),
                        ),
                      );
                    },
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt, size: 48, color: Color(0xFFFFD700)),
                        SizedBox(height: 8),
                        Text(
                          'DAFTAR BANTUAN SAYA',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

