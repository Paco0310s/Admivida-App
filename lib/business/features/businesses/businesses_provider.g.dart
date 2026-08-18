// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'businesses_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BusinessesList)
final businessesListProvider = BusinessesListProvider._();

final class BusinessesListProvider
    extends $AsyncNotifierProvider<BusinessesList, List<BusinessModel>> {
  BusinessesListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'businessesListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$businessesListHash();

  @$internal
  @override
  BusinessesList create() => BusinessesList();
}

String _$businessesListHash() => r'ee15827816220356f745d7752cea34c94654f578';

abstract class _$BusinessesList extends $AsyncNotifier<List<BusinessModel>> {
  FutureOr<List<BusinessModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<BusinessModel>>, List<BusinessModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BusinessModel>>, List<BusinessModel>>,
              AsyncValue<List<BusinessModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
