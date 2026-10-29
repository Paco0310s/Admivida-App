// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_transactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PersonalTransactionsList)
final personalTransactionsListProvider = PersonalTransactionsListFamily._();

final class PersonalTransactionsListProvider
    extends
        $AsyncNotifierProvider<
          PersonalTransactionsList,
          TransactionsListState
        > {
  PersonalTransactionsListProvider._({
    required PersonalTransactionsListFamily super.from,
    required (String?, {String category}) super.argument,
  }) : super(
         retry: null,
         name: r'personalTransactionsListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$personalTransactionsListHash();

  @override
  String toString() {
    return r'personalTransactionsListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PersonalTransactionsList create() => PersonalTransactionsList();

  @override
  bool operator ==(Object other) {
    return other is PersonalTransactionsListProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$personalTransactionsListHash() =>
    r'3c6351c2c2531a567830b6d5f27532a1b59ba2bd';

final class PersonalTransactionsListFamily extends $Family
    with
        $ClassFamilyOverride<
          PersonalTransactionsList,
          AsyncValue<TransactionsListState>,
          TransactionsListState,
          FutureOr<TransactionsListState>,
          (String?, {String category})
        > {
  PersonalTransactionsListFamily._()
    : super(
        retry: null,
        name: r'personalTransactionsListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PersonalTransactionsListProvider call(
    String? accountId, {
    String category = 'REAL',
  }) => PersonalTransactionsListProvider._(
    argument: (accountId, category: category),
    from: this,
  );

  @override
  String toString() => r'personalTransactionsListProvider';
}

abstract class _$PersonalTransactionsList
    extends $AsyncNotifier<TransactionsListState> {
  late final _$args = ref.$arg as (String?, {String category});
  String? get accountId => _$args.$1;
  String get category => _$args.category;

  FutureOr<TransactionsListState> build(
    String? accountId, {
    String category = 'REAL',
  });
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
    element.handleCreate(
      ref,
      () => build(_$args.$1, category: _$args.category),
    );
  }
}

@ProviderFor(personalAccounts)
final personalAccountsProvider = PersonalAccountsProvider._();

final class PersonalAccountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AccountModel>>,
          List<AccountModel>,
          FutureOr<List<AccountModel>>
        >
    with
        $FutureModifier<List<AccountModel>>,
        $FutureProvider<List<AccountModel>> {
  PersonalAccountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personalAccountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personalAccountsHash();

  @$internal
  @override
  $FutureProviderElement<List<AccountModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AccountModel>> create(Ref ref) {
    return personalAccounts(ref);
  }
}

String _$personalAccountsHash() => r'fd8da7b0964dc4546e8fb2a7b5f8ada300fc2a66';
