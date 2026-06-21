import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class VoiceNoteStorageService {
  static const String _bucketName = 'voice_notes';

  final SupabaseClient? _clientOverride;
  final Uuid _uuid;

  VoiceNoteStorageService({
    SupabaseClient? client,
    Uuid? uuid,
  })  : _clientOverride = client,
        _uuid = uuid ?? const Uuid();

  SupabaseClient get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw Exception(
        'Penyimpanan suara (Supabase) belum terinisialisasi. '
        'Pastikan argumen --dart-define=SUPABASE_URL=... dan --dart-define=SUPABASE_PUBLISHABLE_KEY=... telah disertakan saat menjalankan aplikasi.'
      );
    }
  }

  Future<String> uploadVoiceNote({
    required String requestId,
    required String localFilePath,
  }) async {
    final cleanedLocalPath = localFilePath.replaceFirst('file://', '');
    final file = File(cleanedLocalPath);

    if (!await file.exists()) {
      throw Exception('File voice note tidak ditemukan di: $cleanedLocalPath');
    }

    final safeRequestId = _sanitizePathSegment(requestId);
    final fileName = '${safeRequestId}_${_uuid.v4()}.m4a';

    try {
      await _client.storage.from(_bucketName).upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              contentType: 'audio/mp4',
              cacheControl: '3600',
              upsert: false,
            ),
          );

      return _client.storage.from(_bucketName).getPublicUrl(fileName);
    } finally {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Silent catch to prevent masking upload failures
      }
    }
  }

  String _sanitizePathSegment(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    if (cleaned.isEmpty) {
      return 'voice_note';
    }

    return cleaned;
  }
}
