// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'haptic_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hapticServiceHash() => r'63dd2bfdbc3a3d2ddbdef8fa9ed8a93fb8e2a7d2';

/// Pustaka utilitas pembungkus getaran taktil reaktif.
///
/// Mengisolasi integrasi paket pihak ketiga [Vibration] guna menjamin kebersihan
/// arsitektur dan memberikan penanganan error defensif (misal pada emulator tanpa motor getar).
///
/// Copied from [hapticService].
@ProviderFor(hapticService)
final hapticServiceProvider = AutoDisposeProvider<HapticService>.internal(
  hapticService,
  name: r'hapticServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hapticServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HapticServiceRef = AutoDisposeProviderRef<HapticService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
