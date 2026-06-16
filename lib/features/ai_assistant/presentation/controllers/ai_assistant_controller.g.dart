// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_assistant_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiRepositoryHash() => r'ce775e4175f81bff7a9c7c98ec1088ab70079dc7';

/// Penyedia repositori asisten AI cerdas terkonfigurasi.
///
/// Dependensi API Key dibaca langsung melalui compiler [String.fromEnvironment]
/// guna mencegah paparan variabel mentah di repositori publik (best-practice keamanan).
///
/// Copied from [aiRepository].
@ProviderFor(aiRepository)
final aiRepositoryProvider = AutoDisposeProvider<AiRepository>.internal(
  aiRepository,
  name: r'aiRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AiRepositoryRef = AutoDisposeProviderRef<AiRepository>;
String _$aiAssistantControllerHash() =>
    r'01a52e5179aa31e4a63200cb25bac8a46770d243';

/// Pengendali state asisten AI reaktif berbasis AsyncNotifier.
///
/// Mengelola siklus hidup asinkronus dari permintaan pemrosesan gambar ke Gemini API.
/// Kelas ini memetakan hasil sukses, status loading, dan penanganan batasan kuota
/// (Graceful Degradation) secara reaktif untuk dibaca oleh lapisan UI aksesibel.
///
/// Copied from [AiAssistantController].
@ProviderFor(AiAssistantController)
final aiAssistantControllerProvider =
    AutoDisposeAsyncNotifierProvider<AiAssistantController, AiResult?>.internal(
      AiAssistantController.new,
      name: r'aiAssistantControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$aiAssistantControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AiAssistantController = AutoDisposeAsyncNotifier<AiResult?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
