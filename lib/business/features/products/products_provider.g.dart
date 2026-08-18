// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'products_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProductsList)
final productsListProvider = ProductsListFamily._();

final class ProductsListProvider
    extends $AsyncNotifierProvider<ProductsList, ProductsListState> {
  ProductsListProvider._({
    required ProductsListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productsListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productsListHash();

  @override
  String toString() {
    return r'productsListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProductsList create() => ProductsList();

  @override
  bool operator ==(Object other) {
    return other is ProductsListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productsListHash() => r'd17b98e26d3489bb92860a4f15f7399579a813ab';

final class ProductsListFamily extends $Family
    with
        $ClassFamilyOverride<
          ProductsList,
          AsyncValue<ProductsListState>,
          ProductsListState,
          FutureOr<ProductsListState>,
          String
        > {
  ProductsListFamily._()
    : super(
        retry: null,
        name: r'productsListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductsListProvider call(String businessId) =>
      ProductsListProvider._(argument: businessId, from: this);

  @override
  String toString() => r'productsListProvider';
}

abstract class _$ProductsList extends $AsyncNotifier<ProductsListState> {
  late final _$args = ref.$arg as String;
  String get businessId => _$args;

  FutureOr<ProductsListState> build(String businessId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ProductsListState>, ProductsListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ProductsListState>, ProductsListState>,
              AsyncValue<ProductsListState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
