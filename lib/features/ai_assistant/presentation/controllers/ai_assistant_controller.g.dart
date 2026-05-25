// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_assistant_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiRepositoryHash() => r'd3bfdf63526e1dbdbca873a66cc6a161960c4b76';

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
    r'b197a17eca6a844a8e00a1a97433e54f03cc2620';

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
