import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../domain/models/ai_result.dart';
import '../../domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final GenerativeModel _model;

  AiRepositoryImpl({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

  @override
  Future<AiResult> analyzeImage(Uint8List imageBytes) async {
    try {
      final prompt = TextPart(
        'You are an assistive companion for a visually impaired user. '
        'Analyze the image carefully and respond only in valid JSON. '
        'The JSON object must contain exactly two keys: '
        '"text": extract readable text, labels, or handwriting in Indonesian. If there is no text, use an empty string. '
        '"sceneDescription": describe the scene clearly and helpfully in Indonesian. '
        'Do not use markdown. Do not add extra keys.',
      );

      final content = [
        Content.multi([
          prompt,
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await _model.generateContent(content);
      final rawText = response.text;

      if (rawText == null || rawText.trim().isEmpty) {
        throw Exception('Gemini API mengembalikan respons kosong.');
      }

      final cleanedText = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final jsonResponse = jsonDecode(cleanedText) as Map<String, dynamic>;

      return AiResult(
        text: jsonResponse['text'] as String? ?? '',
        sceneDescription: jsonResponse['sceneDescription'] as String? ?? '',
        timestamp: DateTime.now(),
      );
    } on GenerativeAIException catch (e) {
      final message = e.message;

      if (message.contains('OAuth') ||
          message.contains('authentication credentials') ||
          message.contains('API key not valid') ||
          message.contains('PERMISSION_DENIED')) {
        throw Exception(
          'Kunci API Gemini tidak valid atau bukan dari Google AI Studio. '
          'Pastikan memakai GEMINI_API_KEY dari Google AI Studio, bukan Supabase key, Firebase key, OAuth Client ID, atau service account.',
        );
      }

      if (message.contains('ResourceExhausted') || message.contains('429')) {
        throw Exception(
          'Kuota Gemini sedang penuh. Silakan coba lagi beberapa saat.',
        );
      }

      throw Exception('Gagal menghubungi Gemini API: $message');
    } on FormatException {
      throw Exception(
        'Respons Gemini tidak berbentuk JSON valid. Silakan coba ambil gambar lagi.',
      );
    } catch (e) {
      throw Exception('Gagal menganalisis gambar: $e');
    }
  }
}