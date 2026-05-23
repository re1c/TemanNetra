// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authRepositoryHash() => r'1c8be288571ca06fe4e803d16111ae2afb53e010';

/// Penyedia repositori autentikasi untuk memfasilitasi injeksi dependensi.
///
/// Menggunakan provider ini memungkinkan pemisahan total instansiasi riil
/// sehingga mempermudah proses penyuntikan tiruan (mocking) saat pengujian.
///
/// Copied from [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = AutoDisposeProvider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = AutoDisposeProviderRef<AuthRepository>;
String _$authControllerHash() => r'83029078675bf4702b72d33b4ec5ba80cbcd4e7b';

/// Pengendali state autentikasi reaktif berbasis StreamNotifier.
///
/// Kelas ini bertindak sebagai jembatan antara lapisan data (Firebase stream)
/// dengan lapisan antarmuka (UI). Karena berbasis StreamNotifier, Riverpod akan
/// secara otomatis memperbarui state UI secara reaktif ketika ada perubahan
/// sesi dari server Firebase (login/logout/token revoking).
///
/// Copied from [AuthController].
@ProviderFor(AuthController)
final authControllerProvider =
    AutoDisposeStreamNotifierProvider<AuthController, UserModel?>.internal(
      AuthController.new,
      name: r'authControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthController = AutoDisposeStreamNotifier<UserModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
