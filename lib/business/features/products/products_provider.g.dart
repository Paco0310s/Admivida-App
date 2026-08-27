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

String _$productsListHash() => r'9a646e52f402d8064b37d21ec7d2aad22edf0306';

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

@ProviderFor(StockAdjustment)
final stockAdjustmentProvider = StockAdjustmentProvider._();

final class StockAdjustmentProvider
    extends $AsyncNotifierProvider<StockAdjustment, void> {
  StockAdjustmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stockAdjustmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stockAdjustmentHash();

  @$internal
  @override
  StockAdjustment create() => StockAdjustment();
}

String _$stockAdjustmentHash() => r'a8dcd381049c07b1be8f8bea8787d91c206bef77';

abstract class _$StockAdjustment extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(productDetail)
final productDetailProvider = ProductDetailFamily._();

final class ProductDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProductModel>,
          ProductModel,
          FutureOr<ProductModel>
        >
    with $FutureModifier<ProductModel>, $FutureProvider<ProductModel> {
  ProductDetailProvider._({
    required ProductDetailFamily super.from,
    required ({String businessId, String productId}) super.argument,
  }) : super(
         retry: null,
         name: r'productDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productDetailHash();

  @override
  String toString() {
    return r'productDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ProductModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProductModel> create(Ref ref) {
    final argument = this.argument as ({String businessId, String productId});
    return productDetail(
      ref,
      businessId: argument.businessId,
      productId: argument.productId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productDetailHash() => r'9d8cc6c6a104840292475465b5b0b4e908e5740c';

final class ProductDetailFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ProductModel>,
          ({String businessId, String productId})
        > {
  ProductDetailFamily._()
    : super(
        retry: null,
        name: r'productDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductDetailProvider call({
    required String businessId,
    required String productId,
  }) => ProductDetailProvider._(
    argument: (businessId: businessId, productId: productId),
    from: this,
  );

  @override
  String toString() => r'productDetailProvider';
}
