// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReportFilter)
final reportFilterProvider = ReportFilterFamily._();

final class ReportFilterProvider
    extends $NotifierProvider<ReportFilter, ReportFilterState> {
  ReportFilterProvider._({
    required ReportFilterFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'reportFilterProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reportFilterHash();

  @override
  String toString() {
    return r'reportFilterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ReportFilter create() => ReportFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportFilterState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReportFilterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reportFilterHash() => r'26a9fc2feb6775b92f44be0ce9bf1af202898ac3';

final class ReportFilterFamily extends $Family
    with
        $ClassFamilyOverride<
          ReportFilter,
          ReportFilterState,
          ReportFilterState,
          ReportFilterState,
          String
        > {
  ReportFilterFamily._()
    : super(
        retry: null,
        name: r'reportFilterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ReportFilterProvider call(String businessId) =>
      ReportFilterProvider._(argument: businessId, from: this);

  @override
  String toString() => r'reportFilterProvider';
}

abstract class _$ReportFilter extends $Notifier<ReportFilterState> {
  late final _$args = ref.$arg as String;
  String get businessId => _$args;

  ReportFilterState build(String businessId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ReportFilterState, ReportFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReportFilterState, ReportFilterState>,
              ReportFilterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(businessReport)
final businessReportProvider = BusinessReportFamily._();

final class BusinessReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<BusinessReportModel>,
          BusinessReportModel,
          FutureOr<BusinessReportModel>
        >
    with
        $FutureModifier<BusinessReportModel>,
        $FutureProvider<BusinessReportModel> {
  BusinessReportProvider._({
    required BusinessReportFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'businessReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$businessReportHash();

  @override
  String toString() {
    return r'businessReportProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<BusinessReportModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BusinessReportModel> create(Ref ref) {
    final argument = this.argument as String;
    return businessReport(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BusinessReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$businessReportHash() => r'1486def3a87ba508af6510987b6ef1db5e35ad39';

final class BusinessReportFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<BusinessReportModel>, String> {
  BusinessReportFamily._()
    : super(
        retry: null,
        name: r'businessReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BusinessReportProvider call(String businessId) =>
      BusinessReportProvider._(argument: businessId, from: this);

  @override
  String toString() => r'businessReportProvider';
}
