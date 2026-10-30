// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransactionsList)
final transactionsListProvider = TransactionsListFamily._();

final class TransactionsListProvider
    extends $AsyncNotifierProvider<TransactionsList, TransactionsListState> {
  TransactionsListProvider._({
    required TransactionsListFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'transactionsListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionsListHash();

  @override
  String toString() {
    return r'transactionsListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TransactionsList create() => TransactionsList();

  @override
  bool operator ==(Object other) {
    return other is TransactionsListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionsListHash() => r'ea2c7faa7c5856156ad3b4fcf39129e4c3430815';

final class TransactionsListFamily extends $Family
    with
        $ClassFamilyOverride<
          TransactionsList,
          AsyncValue<TransactionsListState>,
          TransactionsListState,
          FutureOr<TransactionsListState>,
          (String, String?)
        > {
  TransactionsListFamily._()
    : super(
        retry: null,
        name: r'transactionsListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TransactionsListProvider call(String businessId, String? accountId) =>
      TransactionsListProvider._(argument: (businessId, accountId), from: this);

  @override
  String toString() => r'transactionsListProvider';
}

abstract class _$TransactionsList
    extends $AsyncNotifier<TransactionsListState> {
  late final _$args = ref.$arg as (String, String?);
  String get businessId => _$args.$1;
  String? get accountId => _$args.$2;

  FutureOr<TransactionsListState> build(String businessId, String? accountId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<TransactionsListState>, TransactionsListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<TransactionsListState>,
                TransactionsListState
              >,
              AsyncValue<TransactionsListState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

@ProviderFor(AccountsBusiness)
final accountsBusinessProvider = AccountsBusinessFamily._();

final class AccountsBusinessProvider
    extends $AsyncNotifierProvider<AccountsBusiness, List<AccountModel>> {
  AccountsBusinessProvider._({
    required AccountsBusinessFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'accountsBusinessProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$accountsBusinessHash();

  @override
  String toString() {
    return r'accountsBusinessProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AccountsBusiness create() => AccountsBusiness();

  @override
  bool operator ==(Object other) {
    return other is AccountsBusinessProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$accountsBusinessHash() => r'5812a463bc3347d6d4f48941f86782b321592186';

final class AccountsBusinessFamily extends $Family
    with
        $ClassFamilyOverride<
          AccountsBusiness,
          AsyncValue<List<AccountModel>>,
          List<AccountModel>,
          FutureOr<List<AccountModel>>,
          String?
        > {
  AccountsBusinessFamily._()
    : super(
        retry: null,
        name: r'accountsBusinessProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AccountsBusinessProvider call({String? businessId}) =>
      AccountsBusinessProvider._(argument: businessId, from: this);

  @override
  String toString() => r'accountsBusinessProvider';
}

abstract class _$AccountsBusiness extends $AsyncNotifier<List<AccountModel>> {
  late final _$args = ref.$arg as String?;
  String? get businessId => _$args;

  FutureOr<List<AccountModel>> build({String? businessId});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<AccountModel>>, List<AccountModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AccountModel>>, List<AccountModel>>,
              AsyncValue<List<AccountModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(businessId: _$args));
  }
}

@ProviderFor(isBusinessAdmin)
final isBusinessAdminProvider = IsBusinessAdminFamily._();

final class IsBusinessAdminProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsBusinessAdminProvider._({
    required IsBusinessAdminFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isBusinessAdminProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isBusinessAdminHash();

  @override
  String toString() {
    return r'isBusinessAdminProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isBusinessAdmin(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsBusinessAdminProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isBusinessAdminHash() => r'24055390b5165bcc4fe9eb7d1dd114ac9d13adbd';

final class IsBusinessAdminFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsBusinessAdminFamily._()
    : super(
        retry: null,
        name: r'isBusinessAdminProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsBusinessAdminProvider call(String businessId) =>
      IsBusinessAdminProvider._(argument: businessId, from: this);

  @override
  String toString() => r'isBusinessAdminProvider';
}
