// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PosCatalogNotifier)
final posCatalogProvider = PosCatalogNotifierFamily._();

final class PosCatalogNotifierProvider
    extends $NotifierProvider<PosCatalogNotifier, PosCatalogState> {
  PosCatalogNotifierProvider._({
    required PosCatalogNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'posCatalogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$posCatalogNotifierHash();

  @override
  String toString() {
    return r'posCatalogProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PosCatalogNotifier create() => PosCatalogNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PosCatalogState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PosCatalogState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PosCatalogNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$posCatalogNotifierHash() =>
    r'8b4aa91215a36a511385a79c831286794c8efc66';

final class PosCatalogNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PosCatalogNotifier,
          PosCatalogState,
          PosCatalogState,
          PosCatalogState,
          String
        > {
  PosCatalogNotifierFamily._()
    : super(
        retry: null,
        name: r'posCatalogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PosCatalogNotifierProvider call(String businessId) =>
      PosCatalogNotifierProvider._(argument: businessId, from: this);

  @override
  String toString() => r'posCatalogProvider';
}

abstract class _$PosCatalogNotifier extends $Notifier<PosCatalogState> {
  late final _$args = ref.$arg as String;
  String get businessId => _$args;

  PosCatalogState build(String businessId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PosCatalogState, PosCatalogState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PosCatalogState, PosCatalogState>,
              PosCatalogState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
