// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volunteer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$volunteerRepositoryHash() =>
    r'5aa80e8340ee65cdb657bc9681e232d5f3e78682';

/// See also [volunteerRepository].
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

/// See also [pendingHelpRequests].
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

/// See also [myClaimedHelpRequests].
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
String _$chatMessagesHash() => r'bf3a9b9b6b6229e54e6941edf32fb157b29a8e93';

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

/// See also [chatMessages].
@ProviderFor(chatMessages)
const chatMessagesProvider = ChatMessagesFamily();

/// See also [chatMessages].
class ChatMessagesFamily extends Family<AsyncValue<List<ChatMessageModel>>> {
  /// See also [chatMessages].
  const ChatMessagesFamily();

  /// See also [chatMessages].
  ChatMessagesProvider call(String requestId) {
    return ChatMessagesProvider(requestId);
  }

  @override
  ChatMessagesProvider getProviderOverride(
    covariant ChatMessagesProvider provider,
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
  String? get name => r'chatMessagesProvider';
}

/// See also [chatMessages].
class ChatMessagesProvider
    extends AutoDisposeStreamProvider<List<ChatMessageModel>> {
  /// See also [chatMessages].
  ChatMessagesProvider(String requestId)
    : this._internal(
        (ref) => chatMessages(ref as ChatMessagesRef, requestId),
        from: chatMessagesProvider,
        name: r'chatMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chatMessagesHash,
        dependencies: ChatMessagesFamily._dependencies,
        allTransitiveDependencies:
            ChatMessagesFamily._allTransitiveDependencies,
        requestId: requestId,
      );

  ChatMessagesProvider._internal(
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
    Stream<List<ChatMessageModel>> Function(ChatMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatMessagesProvider._internal(
        (ref) => create(ref as ChatMessagesRef),
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
    return _ChatMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesProvider && other.requestId == requestId;
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
mixin ChatMessagesRef on AutoDisposeStreamProviderRef<List<ChatMessageModel>> {
  /// The parameter `requestId` of this provider.
  String get requestId;
}

class _ChatMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<ChatMessageModel>>
    with ChatMessagesRef {
  _ChatMessagesProviderElement(super.provider);

  @override
  String get requestId => (origin as ChatMessagesProvider).requestId;
}

String _$volunteerControllerHash() =>
    r'133bafc6508d22d0ae23788ec80722af8e33e20c';

/// See also [VolunteerController].
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
