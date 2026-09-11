// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Cart)
final cartProvider = CartProvider._();

final class CartProvider
    extends $NotifierProvider<Cart, List<CreateSaleDetailInnerDto>> {
  CartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartHash();

  @$internal
  @override
  Cart create() => Cart();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CreateSaleDetailInnerDto> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CreateSaleDetailInnerDto>>(
        value,
      ),
    );
  }
}

String _$cartHash() => r'a71d0f582260c34944688e1a28ef8a141827dfdb';

abstract class _$Cart extends $Notifier<List<CreateSaleDetailInnerDto>> {
  List<CreateSaleDetailInnerDto> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              List<CreateSaleDetailInnerDto>,
              List<CreateSaleDetailInnerDto>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<CreateSaleDetailInnerDto>,
                List<CreateSaleDetailInnerDto>
              >,
              List<CreateSaleDetailInnerDto>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(cartTotal)
final cartTotalProvider = CartTotalProvider._();

final class CartTotalProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  CartTotalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartTotalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartTotalHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return cartTotal(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$cartTotalHash() => r'2efdfdabc542b724536fe4c13b8a8ef575473075';

@ProviderFor(cartItemCount)
final cartItemCountProvider = CartItemCountProvider._();

final class CartItemCountProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  CartItemCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartItemCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartItemCountHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return cartItemCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$cartItemCountHash() => r'f2ed61ab2754324784163270508f370cc2d4a058';

/// Provider to fetch the list of clients for the dropdown.

@ProviderFor(businessClients)
final businessClientsProvider = BusinessClientsFamily._();

/// Provider to fetch the list of clients for the dropdown.

final class BusinessClientsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BusinessClientModel>>,
          List<BusinessClientModel>,
          FutureOr<List<BusinessClientModel>>
        >
    with
        $FutureModifier<List<BusinessClientModel>>,
        $FutureProvider<List<BusinessClientModel>> {
  /// Provider to fetch the list of clients for the dropdown.
  BusinessClientsProvider._({
    required BusinessClientsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'businessClientsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$businessClientsHash();

  @override
  String toString() {
    return r'businessClientsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<BusinessClientModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BusinessClientModel>> create(Ref ref) {
    final argument = this.argument as String;
    return businessClients(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BusinessClientsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$businessClientsHash() => r'0080272c10f115e853b5996c2978d55bd5dfe21e';

/// Provider to fetch the list of clients for the dropdown.

final class BusinessClientsFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<BusinessClientModel>>, String> {
  BusinessClientsFamily._()
    : super(
        retry: null,
        name: r'businessClientsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to fetch the list of clients for the dropdown.

  BusinessClientsProvider call(String businessId) =>
      BusinessClientsProvider._(argument: businessId, from: this);

  @override
  String toString() => r'businessClientsProvider';
}
