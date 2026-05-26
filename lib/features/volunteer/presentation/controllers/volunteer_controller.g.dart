// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volunteer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$volunteerRepositoryHash() =>
    r'5aa80e8340ee65cdb657bc9681e232d5f3e78682';

/// Provider repository relawan.
///
/// Diletakkan di presentation layer agar UI dapat membaca kontrak repository
/// tanpa mengetahui detail implementasi Firestore secara langsung.
///
/// Copied from [volunteerRepository].
@ProviderFor(volunteerRepository)
final volunteerRepositoryProvider =
    AutoDisposeProvider<VolunteerRepository>.internal(
      volunteerRepository,
      name: r'volunteerRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$volunteerRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VolunteerRepositoryRef = AutoDisposeProviderRef<VolunteerRepository>;
String _$pendingHelpRequestsHash() =>
    r'0274b45aa8e65707fb868537cd7eeb33c5299d62';

/// Stream daftar tiket bantuan yang masih tersedia untuk diklaim relawan.
///
/// Copied from [pendingHelpRequests].
@ProviderFor(pendingHelpRequests)
final pendingHelpRequestsProvider =
    AutoDisposeStreamProvider<List<HelpRequestModel>>.internal(
      pendingHelpRequests,
      name: r'pendingHelpRequestsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingHelpRequestsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingHelpRequestsRef =
    AutoDisposeStreamProviderRef<List<HelpRequestModel>>;
String _$myClaimedHelpRequestsHash() =>
    r'4ae1a01a696a6c3a3c641f59377fae0ff904786f';

/// Stream daftar tiket bantuan yang sedang ditangani oleh relawan aktif.
///
/// Copied from [myClaimedHelpRequests].
@ProviderFor(myClaimedHelpRequests)
final myClaimedHelpRequestsProvider =
    AutoDisposeStreamProvider<List<HelpRequestModel>>.internal(
      myClaimedHelpRequests,
      name: r'myClaimedHelpRequestsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$myClaimedHelpRequestsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyClaimedHelpRequestsRef =
    AutoDisposeStreamProviderRef<List<HelpRequestModel>>;
String _$volunteerControllerHash() =>
    r'98e9aeb60aef1e61c77639b9503343f2592407c7';

/// Controller aksi relawan.
///
/// Controller ini menangani operasi mutasi data seperti klaim, selesaikan,
/// dan batalkan klaim tiket bantuan.
///
/// Copied from [VolunteerController].
@ProviderFor(VolunteerController)
final volunteerControllerProvider =
    AutoDisposeAsyncNotifierProvider<VolunteerController, void>.internal(
      VolunteerController.new,
      name: r'volunteerControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$volunteerControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$VolunteerController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
