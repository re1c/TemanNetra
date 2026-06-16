import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

import '../../domain/models/ai_result.dart';
import '../../domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final String apiKey;
  static const String _modelId = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  AiRepositoryImpl({required this.apiKey});

  Future<Uint8List> _resizeImage(Uint8List imageBytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: 1024,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Future<AiResult> analyzeImage(Uint8List imageBytes) async {
    try {
      // Step 1: Compress image to avoid Payload Too Large (Error 413)
      final resizedBytes = await _resizeImage(imageBytes);

      // Step 2: Encode to Base64 Data URI
      final base64Image = base64Encode(resizedBytes);
      final imageDataUri = 'data:image/png;base64,$base64Image';

      // Step 3: Call Groq API via HTTP Client
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _modelId,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'You are an assistive companion for a visually impaired user. '
                      'Analyze the image carefully and respond only in valid JSON. '
                      'The JSON object must contain exactly two keys: '
                      '"text": extract readable text, labels, or handwriting in Indonesian. If there is no text, use an empty string. '
                      '"sceneDescription": describe the scene clearly and helpfully in Indonesian. '
                      'Do not use markdown. Do not add extra keys.',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': imageDataUri,
                  },
                },
              ],
            }
          ],
          'response_format': {
            'type': 'json_object',
          },
        }),
      );

      // Step 4: Handle HTTP Error Status Codes
      if (response.statusCode == 401) {
        throw Exception(
          'Kunci API Groq tidak valid atau belum dikonfigurasi. '
          'Pastikan memakai GEMINI_API_KEY yang berisi kunci API Groq valid.',
        );
      } else if (response.statusCode == 413) {
        throw Exception('Ukuran gambar terlalu besar untuk diproses oleh server Groq.');
      } else if (response.statusCode == 429) {
        throw Exception('Kuota Groq sedang penuh. Silakan coba lagi beberapa saat.');
      } else if (response.statusCode >= 500) {
        throw Exception('Gagal menghubungi Groq API: Terjadi gangguan server internal.');
      } else if (response.statusCode != 200) {
        throw Exception('Gagal menghubungi Groq API: HTTP ${response.statusCode}');
      }

      // Step 5: Parse and Sanitize JSON Response
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      final rawContent = responseJson['choices'][0]['message']['content'] as String;

      final cleanedContent = rawContent
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final decoded = jsonDecode(cleanedContent) as Map<String, dynamic>;

      return AiResult(
        text: decoded['text'] as String? ?? '',
        sceneDescription: decoded['sceneDescription'] as String? ?? '',
        timestamp: DateTime.now(),
      );
    } on SocketException {
      throw Exception('Koneksi internet bermasalah. Pastikan perangkat Anda terhubung ke internet.');
    } on FormatException {
      throw Exception('Respons Groq tidak berbentuk JSON valid. Silakan coba ambil gambar lagi.');
    } catch (e) {
      throw Exception('Gagal menganalisis gambar: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}