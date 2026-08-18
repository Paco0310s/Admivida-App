// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SalesList)
final salesListProvider = SalesListFamily._();

final class SalesListProvider
    extends $AsyncNotifierProvider<SalesList, SalesListState> {
  SalesListProvider._({
    required SalesListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'salesListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$salesListHash();

  @override
  String toString() {
    return r'salesListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SalesList create() => SalesList();

  @override
  bool operator ==(Object other) {
    return other is SalesListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$salesListHash() => r'7dc1b7f46e8242438fe9c9f79af15d9484046298';

final class SalesListFamily extends $Family
    with
        $ClassFamilyOverride<
          SalesList,
          AsyncValue<SalesListState>,
          SalesListState,
          FutureOr<SalesListState>,
          String
        > {
  SalesListFamily._()
    : super(
        retry: null,
        name: r'salesListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SalesListProvider call(String businessId) =>
      SalesListProvider._(argument: businessId, from: this);

  @override
  String toString() => r'salesListProvider';
}

abstract class _$SalesList extends $AsyncNotifier<SalesListState> {
  late final _$args = ref.$arg as String;
  String get businessId => _$args;

  FutureOr<SalesListState> build(String businessId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SalesListState>, SalesListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SalesListState>, SalesListState>,
              AsyncValue<SalesListState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
