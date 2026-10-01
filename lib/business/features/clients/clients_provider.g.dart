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

@ProviderFor(PaymentDistribution)
final paymentDistributionProvider = PaymentDistributionFamily._();

final class PaymentDistributionProvider
    extends $NotifierProvider<PaymentDistribution, PaymentDistributionState> {
  PaymentDistributionProvider._({
    required PaymentDistributionFamily super.from,
    required ({String businessId, String clientId}) super.argument,
  }) : super(
         retry: null,
         name: r'paymentDistributionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$paymentDistributionHash();

  @override
  String toString() {
    return r'paymentDistributionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PaymentDistribution create() => PaymentDistribution();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentDistributionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentDistributionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentDistributionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$paymentDistributionHash() =>
    r'27f361ac1db3a1baca9ddd29dab62592ba4c2ca0';

final class PaymentDistributionFamily extends $Family
    with
        $ClassFamilyOverride<
          PaymentDistribution,
          PaymentDistributionState,
          PaymentDistributionState,
          PaymentDistributionState,
          ({String businessId, String clientId})
        > {
  PaymentDistributionFamily._()
    : super(
        retry: null,
        name: r'paymentDistributionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PaymentDistributionProvider call({
    required String businessId,
    required String clientId,
  }) => PaymentDistributionProvider._(
    argument: (businessId: businessId, clientId: clientId),
    from: this,
  );

  @override
  String toString() => r'paymentDistributionProvider';
}

abstract class _$PaymentDistribution
    extends $Notifier<PaymentDistributionState> {
  late final _$args = ref.$arg as ({String businessId, String clientId});
  String get businessId => _$args.businessId;
  String get clientId => _$args.clientId;

  PaymentDistributionState build({
    required String businessId,
    required String clientId,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<PaymentDistributionState, PaymentDistributionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PaymentDistributionState, PaymentDistributionState>,
              PaymentDistributionState,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(businessId: _$args.businessId, clientId: _$args.clientId),
    );
  }
}

@ProviderFor(ProcessClientPayment)
final processClientPaymentProvider = ProcessClientPaymentProvider._();

final class ProcessClientPaymentProvider
    extends
        $NotifierProvider<
          ProcessClientPayment,
          AsyncValue<ClientPaymentResponse?>
        > {
  ProcessClientPaymentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'processClientPaymentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$processClientPaymentHash();

  @$internal
  @override
  ProcessClientPayment create() => ProcessClientPayment();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ClientPaymentResponse?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ClientPaymentResponse?>>(
        value,
      ),
    );
  }
}

String _$processClientPaymentHash() =>
    r'75e6a942111f5dc3dcfcf448f5562a77f805a42b';

abstract class _$ProcessClientPayment
    extends $Notifier<AsyncValue<ClientPaymentResponse?>> {
  AsyncValue<ClientPaymentResponse?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ClientPaymentResponse?>,
              AsyncValue<ClientPaymentResponse?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ClientPaymentResponse?>,
                AsyncValue<ClientPaymentResponse?>
              >,
              AsyncValue<ClientPaymentResponse?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CreateClient)
final createClientProvider = CreateClientProvider._();

final class CreateClientProvider
    extends $NotifierProvider<CreateClient, AsyncValue<void>> {
  CreateClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createClientHash();

  @$internal
  @override
  CreateClient create() => CreateClient();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$createClientHash() => r'7814cfb8a44b26b6c45773b434ee3cdfcde2cc5e';

abstract class _$CreateClient extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
