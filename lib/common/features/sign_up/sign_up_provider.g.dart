// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_up_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(signUp)
final signUpProvider = SignUpFamily._();

final class SignUpProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SignUpProvider._({
    required SignUpFamily super.from,
    required (BuildContext, CreateUserDto) super.argument,
  }) : super(
         retry: null,
         name: r'signUpProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$signUpHash();

  @override
  String toString() {
    return r'signUpProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (BuildContext, CreateUserDto);
    return signUp(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SignUpProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$signUpHash() => r'f3e98f83874cf7f2214a2edd56d0dc7ea268466b';

final class SignUpFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<void>,
          (BuildContext, CreateUserDto)
        > {
  SignUpFamily._()
    : super(
        retry: null,
        name: r'signUpProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SignUpProvider call(BuildContext context, CreateUserDto userCreateModel) =>
      SignUpProvider._(argument: (context, userCreateModel), from: this);

  @override
  String toString() => r'signUpProvider';
}

@ProviderFor(SignUpLoading)
final signUpLoadingProvider = SignUpLoadingProvider._();

final class SignUpLoadingProvider
    extends $NotifierProvider<SignUpLoading, bool> {
  SignUpLoadingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpLoadingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpLoadingHash();

  @$internal
  @override
  SignUpLoading create() => SignUpLoading();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$signUpLoadingHash() => r'de4e40cfc6a2e654f19b3cc86abc4cb814629518';

abstract class _$SignUpLoading extends $Notifier<bool> {
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

@ProviderFor(signUpWithGoogle)
final signUpWithGoogleProvider = SignUpWithGoogleFamily._();

final class SignUpWithGoogleProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SignUpWithGoogleProvider._({
    required SignUpWithGoogleFamily super.from,
    required BuildContext super.argument,
  }) : super(
         retry: null,
         name: r'signUpWithGoogleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$signUpWithGoogleHash();

  @override
  String toString() {
    return r'signUpWithGoogleProvider'
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
    return signUpWithGoogle(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SignUpWithGoogleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$signUpWithGoogleHash() => r'2bdea5656897a7e0f4992e6fbd98eef4a03f803e';

final class SignUpWithGoogleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, BuildContext> {
  SignUpWithGoogleFamily._()
    : super(
        retry: null,
        name: r'signUpWithGoogleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SignUpWithGoogleProvider call(BuildContext context) =>
      SignUpWithGoogleProvider._(argument: context, from: this);

  @override
  String toString() => r'signUpWithGoogleProvider';
}

@ProviderFor(signUpWithApple)
final signUpWithAppleProvider = SignUpWithAppleFamily._();

final class SignUpWithAppleProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SignUpWithAppleProvider._({
    required SignUpWithAppleFamily super.from,
    required BuildContext super.argument,
  }) : super(
         retry: null,
         name: r'signUpWithAppleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$signUpWithAppleHash();

  @override
  String toString() {
    return r'signUpWithAppleProvider'
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
    return signUpWithApple(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SignUpWithAppleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$signUpWithAppleHash() => r'c713863a9698b9b02d782d5897377ceea8d6aebf';

final class SignUpWithAppleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, BuildContext> {
  SignUpWithAppleFamily._()
    : super(
        retry: null,
        name: r'signUpWithAppleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SignUpWithAppleProvider call(BuildContext context) =>
      SignUpWithAppleProvider._(argument: context, from: this);

  @override
  String toString() => r'signUpWithAppleProvider';
}

@ProviderFor(goToSignIn)
final goToSignInProvider = GoToSignInFamily._();

final class GoToSignInProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  GoToSignInProvider._({
    required GoToSignInFamily super.from,
    required BuildContext super.argument,
  }) : super(
         retry: null,
         name: r'goToSignInProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$goToSignInHash();

  @override
  String toString() {
    return r'goToSignInProvider'
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
    return goToSignIn(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GoToSignInProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goToSignInHash() => r'650ff074a0ff7181a4552cd7b0635ff6c1e028fb';

final class GoToSignInFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, BuildContext> {
  GoToSignInFamily._()
    : super(
        retry: null,
        name: r'goToSignInProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GoToSignInProvider call(BuildContext context) =>
      GoToSignInProvider._(argument: context, from: this);

  @override
  String toString() => r'goToSignInProvider';
}
