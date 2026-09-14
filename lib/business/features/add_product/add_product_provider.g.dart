// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(productTypes)
final productTypesProvider = ProductTypesProvider._();

final class ProductTypesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductTypeModel>>,
          List<ProductTypeModel>,
          FutureOr<List<ProductTypeModel>>
        >
    with
        $FutureModifier<List<ProductTypeModel>>,
        $FutureProvider<List<ProductTypeModel>> {
  ProductTypesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productTypesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productTypesHash();

  @$internal
  @override
  $FutureProviderElement<List<ProductTypeModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductTypeModel>> create(Ref ref) {
    return productTypes(ref);
  }
}

String _$productTypesHash() => r'f31736714af8e6f3f889d0ef8346b07a8160409b';

@ProviderFor(productCategories)
final productCategoriesProvider = ProductCategoriesFamily._();

final class ProductCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductCategoryModel>>,
          List<ProductCategoryModel>,
          FutureOr<List<ProductCategoryModel>>
        >
    with
        $FutureModifier<List<ProductCategoryModel>>,
        $FutureProvider<List<ProductCategoryModel>> {
  ProductCategoriesProvider._({
    required ProductCategoriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productCategoriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productCategoriesHash();

  @override
  String toString() {
    return r'productCategoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductCategoryModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductCategoryModel>> create(Ref ref) {
    final argument = this.argument as String;
    return productCategories(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductCategoriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productCategoriesHash() => r'fe4fdcf3764d99b755ed59e36e334840ca3ab77a';

final class ProductCategoriesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ProductCategoryModel>>,
          String
        > {
  ProductCategoriesFamily._()
    : super(
        retry: null,
        name: r'productCategoriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductCategoriesProvider call(String businessId) =>
      ProductCategoriesProvider._(argument: businessId, from: this);

  @override
  String toString() => r'productCategoriesProvider';
}

@ProviderFor(ProductForm)
final productFormProvider = ProductFormFamily._();

final class ProductFormProvider
    extends $NotifierProvider<ProductForm, ProductFormState> {
  ProductFormProvider._({
    required ProductFormFamily super.from,
    required ProductModel? super.argument,
  }) : super(
         retry: null,
         name: r'productFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productFormHash();

  @override
  String toString() {
    return r'productFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProductForm create() => ProductForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productFormHash() => r'7a03bbe3775b8de80125c39e1d33ced483a9fdd3';

final class ProductFormFamily extends $Family
    with
        $ClassFamilyOverride<
          ProductForm,
          ProductFormState,
          ProductFormState,
          ProductFormState,
          ProductModel?
        > {
  ProductFormFamily._()
    : super(
        retry: null,
        name: r'productFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductFormProvider call(ProductModel? initialProduct) =>
      ProductFormProvider._(argument: initialProduct, from: this);

  @override
  String toString() => r'productFormProvider';
}

abstract class _$ProductForm extends $Notifier<ProductFormState> {
  late final _$args = ref.$arg as ProductModel?;
  ProductModel? get initialProduct => _$args;

  ProductFormState build(ProductModel? initialProduct);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProductFormState, ProductFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProductFormState, ProductFormState>,
              ProductFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
