import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tts_service.g.dart';

/// Penyedia layanan pembaca suara (Text-to-Speech) terkonfigurasi.
///
/// Menggunakan `keepAlive: true` agar mesin TTS tidak terus-menerus diinisialisasi ulang,
/// menjaga performa dan menghindari lag audio pada perangkat mobile.
@Riverpod(keepAlive: true)
TtsService ttsService(TtsServiceRef ref) {
  final service = TtsService();
  ref.onDispose(() {
    // Memastikan pembersihan suara yang sedang diputar ketika provider hancur
    // demi mencegah suara terus berbicara di latar belakang.
    service.stop();
  });
  return service;
}

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  TtsService() {
    _initTts();
  }

  /// Melakukan inisialisasi pengaturan dasar mesin suara secara asinkron.
  Future<void> _initTts() async {
    try {
      // Mengatur bahasa ke Bahasa Indonesia secara default
      await _flutterTts.setLanguage('id-ID');
      // Mengatur kecepatan bicara sedang-lambat (0.55) agar instruksi navigasi
      // terdengar sangat jelas dan dapat dipahami secara mendalam oleh tunanetra.
      await _flutterTts.setSpeechRate(0.55);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
      _isInitialized = true;
    } catch (_) {
      // Penanganan defensif jika mesin TTS pada perangkat tidak siap
    }
  }

  /// Memutar suara teks yang dikirimkan.
  ///
  /// Secara otomatis menghentikan suara yang sedang berjalan sebelumnya
  /// untuk memutar suara pesan baru (antrian suara instan / overwrite).
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      if (!_isInitialized) {
        await _initTts();
      }
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (_) {
      // Penanganan error defensif untuk menghindari crash jika TTS bermasalah
    }
  }

  /// Menghentikan pemutaran suara yang sedang berlangsung saat ini.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {
      // Abaikan eksepsi
    }
  }
}
