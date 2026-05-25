// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'help_request_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$helpRequestRepositoryHash() =>
    r'af6a4bdbb302cef5d02bd92bc9d1b9fa8f7419ce';

/// Penyedia repositori tiket bantuan terkonfigurasi.
///
/// Copied from [helpRequestRepository].
@ProviderFor(helpRequestRepository)
final helpRequestRepositoryProvider =
    AutoDisposeProvider<HelpRequestRepository>.internal(
      helpRequestRepository,
      name: r'helpRequestRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$helpRequestRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HelpRequestRepositoryRef =
    AutoDisposeProviderRef<HelpRequestRepository>;
String _$helpRequestControllerHash() =>
    r'c8d6fa908b40a9fcff47ab4488e7a3ffda4ebcf9';

/// Pengendali state reaktif berbasis StreamNotifier untuk mengelola daftar tiket.
///
/// Kelas ini memantau aliran data perubahan dokumen Firestore secara real-time.
/// Method mutasi dirancang melempar error (rethrow) agar lapisan presentasi (UI)
/// dapat menangkap kegagalan secara asinkron dan memberikan respon suara instan.
///
/// Copied from [HelpRequestController].
@ProviderFor(HelpRequestController)
final helpRequestControllerProvider =
    AutoDisposeStreamNotifierProvider<
      HelpRequestController,
      List<HelpRequestModel>
    >.internal(
      HelpRequestController.new,
      name: r'helpRequestControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$helpRequestControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HelpRequestController =
    AutoDisposeStreamNotifier<List<HelpRequestModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
