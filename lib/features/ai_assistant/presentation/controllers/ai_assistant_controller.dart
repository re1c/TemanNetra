import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/models/ai_result.dart';
import '../../domain/repositories/ai_repository.dart';

part 'ai_assistant_controller.g.dart';

/// Penyedia repositori asisten AI cerdas terkonfigurasi.
/// 
/// Dependensi API Key dibaca langsung melalui compiler [String.fromEnvironment]
/// guna mencegah paparan variabel mentah di repositori publik (best-practice keamanan).
@riverpod
AiRepository aiRepository(AiRepositoryRef ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  if (apiKey.isEmpty) {
    developer.log(
      'Peringatan: GEMINI_API_KEY tidak dikonfigurasi di environment.',
      name: 'AiRepositoryProvider',
      error: 'GEMINI_API_KEY is empty',
    );
    debugPrint('=== TEMANNETRA AI CONFIG ERROR ===\nGEMINI_API_KEY is empty. Please run with --dart-define=GEMINI_API_KEY=...');
    throw Exception(
      'Kunci API Gemini belum terkonfigurasi. '
      'Pastikan argumen --dart-define=GEMINI_API_KEY=... telah disertakan saat menjalankan aplikasi.'
    );
  }
  return AiRepositoryImpl(apiKey: apiKey);
}

/// Pengendali state asisten AI reaktif berbasis AsyncNotifier.
/// 
/// Mengelola siklus hidup asinkronus dari permintaan pemrosesan gambar ke Groq API.
/// Kelas ini memetakan hasil sukses, status loading, dan penanganan batasan kuota 
/// secara reaktif untuk dibaca oleh lapisan UI aksesibel.
@riverpod
class AiAssistantController extends _$AiAssistantController {
  @override
  FutureOr<AiResult?> build() {
    // Awal status asisten AI adalah null (menunggu input gambar dari kamera).
    return null;
  }

  /// Mengirimkan data byte gambar untuk dianalisis oleh asisten AI.
  Future<void> processImage(Uint8List imageBytes) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      try {
        final repository = ref.read(aiRepositoryProvider);
        return await repository.analyzeImage(imageBytes);
      } catch (e, stackTrace) {
        developer.log(
          'Error ditangkap di controller',
          name: 'AiAssistantController',
          error: e,
          stackTrace: stackTrace,
        );
        debugPrint('======================================================');
        debugPrint('🔴 TEMANNETRA AI ERROR:');
        debugPrint(e.toString());
        debugPrint('======================================================');
        // Meneruskan error ter-map bersih dari repositori ke UI
        rethrow;
      }
    });
  }

  /// Membersihkan riwayat hasil analisis visual.
  void clearResult() {
    state = const AsyncValue.data(null);
  }
}
