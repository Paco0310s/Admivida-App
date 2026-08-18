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
