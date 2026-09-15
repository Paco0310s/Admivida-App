// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commission_payment_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CommissionPaymentsController)
final commissionPaymentsControllerProvider =
    CommissionPaymentsControllerFamily._();

final class CommissionPaymentsControllerProvider
    extends
        $AsyncNotifierProvider<
          CommissionPaymentsController,
          CommissionPaymentHistoryResponseModel
        > {
  CommissionPaymentsControllerProvider._({
    required CommissionPaymentsControllerFamily super.from,
    required ({String businessId, bool isAdmin}) super.argument,
  }) : super(
         retry: null,
         name: r'commissionPaymentsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commissionPaymentsControllerHash();

  @override
  String toString() {
    return r'commissionPaymentsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CommissionPaymentsController create() => CommissionPaymentsController();

  @override
  bool operator ==(Object other) {
    return other is CommissionPaymentsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commissionPaymentsControllerHash() =>
    r'fc69659f59236470056ebb9842cf589eb3645ad5';

final class CommissionPaymentsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CommissionPaymentsController,
          AsyncValue<CommissionPaymentHistoryResponseModel>,
          CommissionPaymentHistoryResponseModel,
          FutureOr<CommissionPaymentHistoryResponseModel>,
          ({String businessId, bool isAdmin})
        > {
  CommissionPaymentsControllerFamily._()
    : super(
        retry: null,
        name: r'commissionPaymentsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CommissionPaymentsControllerProvider call({
    required String businessId,
    required bool isAdmin,
  }) => CommissionPaymentsControllerProvider._(
    argument: (businessId: businessId, isAdmin: isAdmin),
    from: this,
  );

  @override
  String toString() => r'commissionPaymentsControllerProvider';
}

abstract class _$CommissionPaymentsController
    extends $AsyncNotifier<CommissionPaymentHistoryResponseModel> {
  late final _$args = ref.$arg as ({String businessId, bool isAdmin});
  String get businessId => _$args.businessId;
  bool get isAdmin => _$args.isAdmin;

  FutureOr<CommissionPaymentHistoryResponseModel> build({
    required String businessId,
    required bool isAdmin,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CommissionPaymentHistoryResponseModel>,
              CommissionPaymentHistoryResponseModel
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CommissionPaymentHistoryResponseModel>,
                CommissionPaymentHistoryResponseModel
              >,
              AsyncValue<CommissionPaymentHistoryResponseModel>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(businessId: _$args.businessId, isAdmin: _$args.isAdmin),
    );
  }
}
