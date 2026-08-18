// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(splashStartupLogic)
final splashStartupLogicProvider = SplashStartupLogicFamily._();

final class SplashStartupLogicProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SplashStartupLogicProvider._({
    required SplashStartupLogicFamily super.from,
    required BuildContext super.argument,
  }) : super(
         retry: null,
         name: r'splashStartupLogicProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$splashStartupLogicHash();

  @override
  String toString() {
    return r'splashStartupLogicProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as BuildContext;
    return splashStartupLogic(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SplashStartupLogicProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$splashStartupLogicHash() =>
    r'8451babb51273cb56839cc0c1e0192ce5730f1da';

final class SplashStartupLogicFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, BuildContext> {
  SplashStartupLogicFamily._()
    : super(
        retry: null,
        name: r'splashStartupLogicProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SplashStartupLogicProvider call(BuildContext context) =>
      SplashStartupLogicProvider._(argument: context, from: this);

  @override
  String toString() => r'splashStartupLogicProvider';
}

@ProviderFor(SplashLoading)
final splashLoadingProvider = SplashLoadingProvider._();

final class SplashLoadingProvider
    extends $NotifierProvider<SplashLoading, bool> {
  SplashLoadingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splashLoadingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$splashLoadingHash();

  @$internal
  @override
  SplashLoading create() => SplashLoading();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$splashLoadingHash() => r'53683daa80dcb94b621c8dce9fb58dab0b9797ca';

abstract class _$SplashLoading extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
