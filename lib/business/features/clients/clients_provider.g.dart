// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ClientsDebtList)
final clientsDebtListProvider = ClientsDebtListFamily._();

final class ClientsDebtListProvider
    extends $AsyncNotifierProvider<ClientsDebtList, ClientsDebtListState> {
  ClientsDebtListProvider._({
    required ClientsDebtListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clientsDebtListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clientsDebtListHash();

  @override
  String toString() {
    return r'clientsDebtListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ClientsDebtList create() => ClientsDebtList();

  @override
  bool operator ==(Object other) {
    return other is ClientsDebtListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clientsDebtListHash() => r'2e0902b7e5d129668af1525429db7f19483a6702';

final class ClientsDebtListFamily extends $Family
    with
        $ClassFamilyOverride<
          ClientsDebtList,
          AsyncValue<ClientsDebtListState>,
          ClientsDebtListState,
          FutureOr<ClientsDebtListState>,
          String
        > {
  ClientsDebtListFamily._()
    : super(
        retry: null,
        name: r'clientsDebtListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClientsDebtListProvider call(String businessId) =>
      ClientsDebtListProvider._(argument: businessId, from: this);

  @override
  String toString() => r'clientsDebtListProvider';
}

abstract class _$ClientsDebtList extends $AsyncNotifier<ClientsDebtListState> {
  late final _$args = ref.$arg as String;
  String get businessId => _$args;

  FutureOr<ClientsDebtListState> build(String businessId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ClientsDebtListState>, ClientsDebtListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ClientsDebtListState>,
                ClientsDebtListState
              >,
              AsyncValue<ClientsDebtListState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(PendingSales)
final pendingSalesProvider = PendingSalesFamily._();

final class PendingSalesProvider
    extends $AsyncNotifierProvider<PendingSales, List<PendingSaleModel>> {
  PendingSalesProvider._({
    required PendingSalesFamily super.from,
    required ({String businessId, String clientId}) super.argument,
  }) : super(
         retry: null,
         name: r'pendingSalesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingSalesHash();

  @override
  String toString() {
    return r'pendingSalesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PendingSales create() => PendingSales();

  @override
  bool operator ==(Object other) {
    return other is PendingSalesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingSalesHash() => r'fe28c07064a2980c8ab9a11a72f7db6e37126885';

final class PendingSalesFamily extends $Family
    with
        $ClassFamilyOverride<
          PendingSales,
          AsyncValue<List<PendingSaleModel>>,
          List<PendingSaleModel>,
          FutureOr<List<PendingSaleModel>>,
          ({String businessId, String clientId})
        > {
  PendingSalesFamily._()
    : super(
        retry: null,
        name: r'pendingSalesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PendingSalesProvider call({
    required String businessId,
    required String clientId,
  }) => PendingSalesProvider._(
    argument: (businessId: businessId, clientId: clientId),
    from: this,
  );

  @override
  String toString() => r'pendingSalesProvider';
}

abstract class _$PendingSales extends $AsyncNotifier<List<PendingSaleModel>> {
  late final _$args = ref.$arg as ({String businessId, String clientId});
  String get businessId => _$args.businessId;
  String get clientId => _$args.clientId;

  FutureOr<List<PendingSaleModel>> build({
    required String businessId,
    required String clientId,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<PendingSaleModel>>, List<PendingSaleModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PendingSaleModel>>,
                List<PendingSaleModel>
              >,
              AsyncValue<List<PendingSaleModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(businessId: _$args.businessId, clientId: _$args.clientId),
    );
  }
}
