// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_business_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CreateBusiness)
final createBusinessProvider = CreateBusinessProvider._();

final class CreateBusinessProvider
    extends $AsyncNotifierProvider<CreateBusiness, BusinessModel?> {
  CreateBusinessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createBusinessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createBusinessHash();

  @$internal
  @override
  CreateBusiness create() => CreateBusiness();
}

String _$createBusinessHash() => r'74e31d4779a4448c5416615313f05c141eb79b61';

abstract class _$CreateBusiness extends $AsyncNotifier<BusinessModel?> {
  FutureOr<BusinessModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BusinessModel?>, BusinessModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BusinessModel?>, BusinessModel?>,
              AsyncValue<BusinessModel?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(BusinessCategories)
final businessCategoriesProvider = BusinessCategoriesProvider._();

final class BusinessCategoriesProvider
    extends
        $AsyncNotifierProvider<
          BusinessCategories,
          List<BusinessCategoryModel>
        > {
  BusinessCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'businessCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$businessCategoriesHash();

  @$internal
  @override
  BusinessCategories create() => BusinessCategories();
}

String _$businessCategoriesHash() =>
    r'98323f79e4eacb43c723a8440791e6550bb2063a';

abstract class _$BusinessCategories
    extends $AsyncNotifier<List<BusinessCategoryModel>> {
  FutureOr<List<BusinessCategoryModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<BusinessCategoryModel>>,
              List<BusinessCategoryModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<BusinessCategoryModel>>,
                List<BusinessCategoryModel>
              >,
              AsyncValue<List<BusinessCategoryModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
