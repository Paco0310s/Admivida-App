// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commission_payment_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider to fetch the list of sellers/admins for the dropdown.

@ProviderFor(businessSellers)
final businessSellersProvider = BusinessSellersFamily._();

/// Provider to fetch the list of sellers/admins for the dropdown.

final class BusinessSellersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BusinessStaffModel>>,
          List<BusinessStaffModel>,
          FutureOr<List<BusinessStaffModel>>
        >
    with
        $FutureModifier<List<BusinessStaffModel>>,
        $FutureProvider<List<BusinessStaffModel>> {
  /// Provider to fetch the list of sellers/admins for the dropdown.
  BusinessSellersProvider._({
    required BusinessSellersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'businessSellersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$businessSellersHash();

  @override
  String toString() {
    return r'businessSellersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<BusinessStaffModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BusinessStaffModel>> create(Ref ref) {
    final argument = this.argument as String;
    return businessSellers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BusinessSellersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$businessSellersHash() => r'9acb5da08b526c146c0def96d65336629ab7199a';

/// Provider to fetch the list of sellers/admins for the dropdown.

final class BusinessSellersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<BusinessStaffModel>>, String> {
  BusinessSellersFamily._()
    : super(
        retry: null,
        name: r'businessSellersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to fetch the list of sellers/admins for the dropdown.

  BusinessSellersProvider call(String businessId) =>
      BusinessSellersProvider._(argument: businessId, from: this);

  @override
  String toString() => r'businessSellersProvider';
}

/// Provider to fetch the pending commissions.
/// It automatically invalidates/refetches if the businessId or sellerId changes.

@ProviderFor(pendingCommissions)
final pendingCommissionsProvider = PendingCommissionsFamily._();

/// Provider to fetch the pending commissions.
/// It automatically invalidates/refetches if the businessId or sellerId changes.

final class PendingCommissionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PendingCommissionItem>>,
          List<PendingCommissionItem>,
          FutureOr<List<PendingCommissionItem>>
        >
    with
        $FutureModifier<List<PendingCommissionItem>>,
        $FutureProvider<List<PendingCommissionItem>> {
  /// Provider to fetch the pending commissions.
  /// It automatically invalidates/refetches if the businessId or sellerId changes.
  PendingCommissionsProvider._({
    required PendingCommissionsFamily super.from,
    required ({String businessId, String sellerId}) super.argument,
  }) : super(
         retry: null,
         name: r'pendingCommissionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingCommissionsHash();

  @override
  String toString() {
    return r'pendingCommissionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PendingCommissionItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PendingCommissionItem>> create(Ref ref) {
    final argument = this.argument as ({String businessId, String sellerId});
    return pendingCommissions(
      ref,
      businessId: argument.businessId,
      sellerId: argument.sellerId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PendingCommissionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingCommissionsHash() =>
    r'5108d344ab835e79cee67041f6bd3ec06189833a';

/// Provider to fetch the pending commissions.
/// It automatically invalidates/refetches if the businessId or sellerId changes.

final class PendingCommissionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PendingCommissionItem>>,
          ({String businessId, String sellerId})
        > {
  PendingCommissionsFamily._()
    : super(
        retry: null,
        name: r'pendingCommissionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to fetch the pending commissions.
  /// It automatically invalidates/refetches if the businessId or sellerId changes.

  PendingCommissionsProvider call({
    required String businessId,
    required String sellerId,
  }) => PendingCommissionsProvider._(
    argument: (businessId: businessId, sellerId: sellerId),
    from: this,
  );

  @override
  String toString() => r'pendingCommissionsProvider';
}

@ProviderFor(accountsUser)
final accountsUserProvider = AccountsUserFamily._();

final class AccountsUserProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AccountModel>>,
          List<AccountModel>,
          FutureOr<List<AccountModel>>
        >
    with
        $FutureModifier<List<AccountModel>>,
        $FutureProvider<List<AccountModel>> {
  AccountsUserProvider._({
    required AccountsUserFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'accountsUserProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$accountsUserHash();

  @override
  String toString() {
    return r'accountsUserProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AccountModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AccountModel>> create(Ref ref) {
    final argument = this.argument as String?;
    return accountsUser(ref, userId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AccountsUserProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$accountsUserHash() => r'b612d493f6f9e82e1c1c48ae124e2c6fc482390e';

final class AccountsUserFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AccountModel>>, String?> {
  AccountsUserFamily._()
    : super(
        retry: null,
        name: r'accountsUserProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AccountsUserProvider call({String? userId}) =>
      AccountsUserProvider._(argument: userId, from: this);

  @override
  String toString() => r'accountsUserProvider';
}
