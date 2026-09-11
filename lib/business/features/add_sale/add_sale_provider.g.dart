// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_sale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(scannedVariant)
final scannedVariantProvider = ScannedVariantFamily._();

final class ScannedVariantProvider
    extends
        $FunctionalProvider<
          AsyncValue<ScannedVariantModel>,
          ScannedVariantModel,
          FutureOr<ScannedVariantModel>
        >
    with
        $FutureModifier<ScannedVariantModel>,
        $FutureProvider<ScannedVariantModel> {
  ScannedVariantProvider._({
    required ScannedVariantFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'scannedVariantProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$scannedVariantHash();

  @override
  String toString() {
    return r'scannedVariantProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ScannedVariantModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ScannedVariantModel> create(Ref ref) {
    final argument = this.argument as (String, String);
    return scannedVariant(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ScannedVariantProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scannedVariantHash() => r'02dc19bf149f13cd9001b5fe5cf8e7d2977e7c07';

final class ScannedVariantFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ScannedVariantModel>,
          (String, String)
        > {
  ScannedVariantFamily._()
    : super(
        retry: null,
        name: r'scannedVariantProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ScannedVariantProvider call(String sku, String businessId) =>
      ScannedVariantProvider._(argument: (sku, businessId), from: this);

  @override
  String toString() => r'scannedVariantProvider';
}
