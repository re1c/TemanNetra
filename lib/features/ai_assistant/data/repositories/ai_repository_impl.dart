import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/models/ai_result.dart';
import '../../domain/repositories/ai_repository.dart';

/// Implementasi repositori asisten visual cerdas terhubung ke Gemini API.
class AiRepositoryImpl implements AiRepository {
  final GenerativeModel _model;

  AiRepositoryImpl({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash', // Latensi super rendah dan multimodal hemat energi
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json', // Memaksa model hanya mengembalikan struktur JSON valid
          ),
        );

  @override
  Future<AiResult> analyzeImage(Uint8List imageBytes) async {
    try {
      final prompt = TextPart(
        'You are an assistive companion for the visually impaired. Analyze this image. '
        'Provide a JSON object containing exactly two keys: '
        '1. "text": Extract any readable text, labels, or handwriting found in the image (Strictly in Indonesian). If none, use an empty string. '
        '2. "sceneDescription": A helpful, clear, and direct description of the object or surroundings (Strictly in Indonesian). '
        'Do not wrap your output in markdown formatting.'
      );

      final content = [
        Content.multi([
          prompt,
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Gemini API returned an empty response.');
      }

      // Berkat konfigurasi 'application/json', kita dijamin menerima 
      // format JSON mentah tanpa perlu pembersihan blok teks markdown.
      final Map<String, dynamic> jsonResponse = jsonDecode(response.text!) as Map<String, dynamic>;
      
      return AiResult(
        text: jsonResponse['text'] as String? ?? '',
        sceneDescription: jsonResponse['sceneDescription'] as String? ?? '',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // Seluruh kegagalan jaringan atau pembatasan kuota dilempar ke atas 
      // agar ditangani oleh state controller UI.
      rethrow;
    }
  }
}
