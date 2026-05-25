// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tts_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ttsServiceHash() => r'5c3ecefd4e931d669f95740c1c070542ddb089a5';

/// Penyedia layanan pembaca suara (Text-to-Speech) terkonfigurasi.
///
/// Menggunakan `keepAlive: true` agar mesin TTS tidak terus-menerus diinisialisasi ulang,
/// menjaga performa dan menghindari lag audio pada perangkat mobile.
///
/// Copied from [ttsService].
@ProviderFor(ttsService)
final ttsServiceProvider = Provider<TtsService>.internal(
  ttsService,
  name: r'ttsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ttsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TtsServiceRef = ProviderRef<TtsService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
