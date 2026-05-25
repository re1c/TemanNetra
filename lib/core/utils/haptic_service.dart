import 'package:vibration/vibration.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'haptic_service.g.dart';

/// Pustaka utilitas pembungkus getaran taktil reaktif.
///
/// Mengisolasi integrasi paket pihak ketiga [Vibration] guna menjamin kebersihan 
/// arsitektur dan memberikan penanganan error defensif (misal pada emulator tanpa motor getar).
@riverpod
HapticService hapticService(HapticServiceRef ref) {
  return const HapticService();
}

class HapticService {
  const HapticService();

  /// Mengirim getaran tunggal sangat pendek untuk konfirmasi klik tombol.
  Future<void> vibrateClick() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 40);
      }
    } catch (_) {
      // Mengabaikan kegagalan secara defensif jika berjalan pada emulator
      // atau perangkat yang tidak mendukung getaran hardware.
    }
  }

  /// Mengirim getaran berirama sukses (getaran sedang, jeda, getaran sedang).
  Future<void> vibrateSuccess() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Pola: Jeda 0ms, Getar 80ms, Jeda 80ms, Getar 150ms
        await Vibration.vibrate(pattern: [0, 80, 80, 150]);
      }
    } catch (_) {
      // Abaikan kegagalan pada perangkat uji tanpa hardware getar
    }
  }

  /// Mengirim getaran ganda pendek berurutan untuk penanda kesalahan (error).
  Future<void> vibrateError() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Pola: Jeda 0ms, Getar 60ms, Jeda 50ms, Getar 60ms, Jeda 50ms, Getar 60ms
        await Vibration.vibrate(pattern: [0, 60, 50, 60, 50, 60]);
      }
    } catch (_) {
      // Abaikan kegagalan pada emulator
    }
  }
}
