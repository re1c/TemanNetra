import 'dart:typed_data';
import '../models/ai_result.dart';

/// Kontrak repositori pemrosesan multimodal kecerdasan buatan pada domain layer.
/// 
/// Abstraksi ini diisolasi secara murni agar logika asisten visual tidak 
/// bergantung langsung pada paket pihak ketiga (google_generative_ai). 
/// Parameter input menggunakan tipe [Uint8List] untuk menjamin kecocokan lintas
/// platform (baik seluler maupun web) tanpa bergantung pada file path lokal.
abstract class AiRepository {
  
  /// Mengirim data biner gambar ke asisten cerdas untuk dianalisis.
  /// 
  /// Mengembalikan [AiResult] yang berisi teks hasil ekstraksi dan deskripsi objek.
  Future<AiResult> analyzeImage(Uint8List imageBytes);
}
