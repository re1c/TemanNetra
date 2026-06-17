// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'help_request_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$helpRequestRepositoryHash() =>
    r'af6a4bdbb302cef5d02bd92bc9d1b9fa8f7419ce';

/// See also [helpRequestRepository].
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
String _$helpRequestMessagesHash() =>
    r'3c91105ad9326ba801ae6c1859f4d852c0014a69';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [helpRequestMessages].
@ProviderFor(helpRequestMessages)
const helpRequestMessagesProvider = HelpRequestMessagesFamily();

/// See also [helpRequestMessages].
class HelpRequestMessagesFamily
    extends Family<AsyncValue<List<ChatMessageModel>>> {
  /// See also [helpRequestMessages].
  const HelpRequestMessagesFamily();

  /// See also [helpRequestMessages].
  HelpRequestMessagesProvider call(String requestId) {
    return HelpRequestMessagesProvider(requestId);
  }

  @override
  HelpRequestMessagesProvider getProviderOverride(
    covariant HelpRequestMessagesProvider provider,
  ) {
    return call(provider.requestId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'helpRequestMessagesProvider';
}

/// See also [helpRequestMessages].
class HelpRequestMessagesProvider
    extends AutoDisposeStreamProvider<List<ChatMessageModel>> {
  /// See also [helpRequestMessages].
  HelpRequestMessagesProvider(String requestId)
    : this._internal(
        (ref) => helpRequestMessages(ref as HelpRequestMessagesRef, requestId),
        from: helpRequestMessagesProvider,
        name: r'helpRequestMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$helpRequestMessagesHash,
        dependencies: HelpRequestMessagesFamily._dependencies,
        allTransitiveDependencies:
            HelpRequestMessagesFamily._allTransitiveDependencies,
        requestId: requestId,
      );

  HelpRequestMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.requestId,
  }) : super.internal();

  final String requestId;

  @override
  Override overrideWith(
    Stream<List<ChatMessageModel>> Function(HelpRequestMessagesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HelpRequestMessagesProvider._internal(
        (ref) => create(ref as HelpRequestMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        requestId: requestId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ChatMessageModel>> createElement() {
    return _HelpRequestMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HelpRequestMessagesProvider && other.requestId == requestId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, requestId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HelpRequestMessagesRef
    on AutoDisposeStreamProviderRef<List<ChatMessageModel>> {
  /// The parameter `requestId` of this provider.
  String get requestId;
}

class _HelpRequestMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<ChatMessageModel>>
    with HelpRequestMessagesRef {
  _HelpRequestMessagesProviderElement(super.provider);

  @override
  String get requestId => (origin as HelpRequestMessagesProvider).requestId;
}

String _$helpRequestControllerHash() =>
    r'd8911ce88012b2cc6251376faec24ff04f3faea8';

/// See also [HelpRequestController].
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
