/// Entitas data murni Dart yang mewakili hasil analisis multimodal Gemini AI.
/// 
/// Model ini dirancang immutable menggunakan kata kunci `final` untuk menjamin
/// bahwa data hasil pemindaian tidak dapat dimutasi secara tidak sengaja oleh 
/// lapisan presentasi saat di-render atau dibacakan secara audio.
class AiResult {
  
  /// Teks mentah hasil ekstraksi gambar (OCR / Text Recognition).
  final String text;

  /// Deskripsi pemandangan/situasi sekitar objek untuk membantu tunanetra
  /// memahami konteks lingkungan (Scene Description).
  final String sceneDescription;

  /// Penanda waktu kapan analisis visual diselesaikan demi kebutuhan pelacakan riwayat.
  final DateTime timestamp;

  const AiResult({
    required this.text,
    required this.sceneDescription,
    required this.timestamp,
  });

  AiResult copyWith({
    String? text,
    String? sceneDescription,
    DateTime? timestamp,
  }) {
    return AiResult(
      text: text ?? this.text,
      sceneDescription: sceneDescription ?? this.sceneDescription,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sceneDescription': sceneDescription,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AiResult.fromMap(Map<String, dynamic> map) {
    return AiResult(
      text: map['text'] as String? ?? '',
      sceneDescription: map['sceneDescription'] as String? ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp'] as String) 
          : DateTime.now(),
    );
  }
}
