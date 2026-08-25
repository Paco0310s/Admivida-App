// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_transactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentMethods)
final paymentMethodsProvider = PaymentMethodsProvider._();

final class PaymentMethodsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PaymentMethodModel>>,
          List<PaymentMethodModel>,
          FutureOr<List<PaymentMethodModel>>
        >
    with
        $FutureModifier<List<PaymentMethodModel>>,
        $FutureProvider<List<PaymentMethodModel>> {
  PaymentMethodsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentMethodsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentMethodsHash();

  @$internal
  @override
  $FutureProviderElement<List<PaymentMethodModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PaymentMethodModel>> create(Ref ref) {
    return paymentMethods(ref);
  }
}

String _$paymentMethodsHash() => r'8a9d0e4780c26df7dadeee30189a4bfb2af8ad50';

@ProviderFor(AddTransaction)
final addTransactionProvider = AddTransactionProvider._();

final class AddTransactionProvider
    extends $AsyncNotifierProvider<AddTransaction, TransactionModel?> {
  AddTransactionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addTransactionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addTransactionHash();

  @$internal
  @override
  AddTransaction create() => AddTransaction();
}

String _$addTransactionHash() => r'43aa21b28f8ce15883385d94ba3950404c5c35f8';

abstract class _$AddTransaction extends $AsyncNotifier<TransactionModel?> {
  FutureOr<TransactionModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TransactionModel?>, TransactionModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TransactionModel?>, TransactionModel?>,
              AsyncValue<TransactionModel?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
