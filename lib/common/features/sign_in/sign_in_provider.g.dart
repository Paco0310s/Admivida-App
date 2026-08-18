// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(signIn)
final signInProvider = SignInFamily._();

final class SignInProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SignInProvider._({
    required SignInFamily super.from,
    required (BuildContext, LoginUserDto) super.argument,
  }) : super(
         retry: null,
         name: r'signInProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$signInHash();

  @override
  String toString() {
    return r'signInProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (BuildContext, LoginUserDto);
    return signIn(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SignInProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$signInHash() => r'56215e4c8ddf25204acbbda74df52321b6dfb92f';

final class SignInFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<void>,
          (BuildContext, LoginUserDto)
        > {
  SignInFamily._()
    : super(
        retry: null,
        name: r'signInProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SignInProvider call(BuildContext context, LoginUserDto userLoginDto) =>
      SignInProvider._(argument: (context, userLoginDto), from: this);

  @override
  String toString() => r'signInProvider';
}

@ProviderFor(SignInLoading)
final signInLoadingProvider = SignInLoadingProvider._();

final class SignInLoadingProvider
    extends $NotifierProvider<SignInLoading, bool> {
  SignInLoadingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInLoadingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInLoadingHash();

  @$internal
  @override
  SignInLoading create() => SignInLoading();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$signInLoadingHash() => r'9986cde3c3898d48b85df0733510b2b66d8a296b';

abstract class _$SignInLoading extends $Notifier<bool> {
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

@ProviderFor(signInWithGoogle)
final signInWithGoogleProvider = SignInWithGoogleFamily._();

final class SignInWithGoogleProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SignInWithGoogleProvider._({
    required SignInWithGoogleFamily super.from,
    required BuildContext super.argument,
  }) : super(
         retry: null,
         name: r'signInWithGoogleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$signInWithGoogleHash();

  @override
  String toString() {
    return r'signInWithGoogleProvider'
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
    return signInWithGoogle(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SignInWithGoogleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$signInWithGoogleHash() => r'6039fa78f3a358ec2328d273ad6926609f0f2761';

final class SignInWithGoogleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, BuildContext> {
  SignInWithGoogleFamily._()
    : super(
        retry: null,
        name: r'signInWithGoogleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SignInWithGoogleProvider call(BuildContext context) =>
      SignInWithGoogleProvider._(argument: context, from: this);

  @override
  String toString() => r'signInWithGoogleProvider';
}

@ProviderFor(signInWithApple)
final signInWithAppleProvider = SignInWithAppleFamily._();

final class SignInWithAppleProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SignInWithAppleProvider._({
    required SignInWithAppleFamily super.from,
    required BuildContext super.argument,
  }) : super(
         retry: null,
         name: r'signInWithAppleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$signInWithAppleHash();

  @override
  String toString() {
    return r'signInWithAppleProvider'
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
    return signInWithApple(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SignInWithAppleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$signInWithAppleHash() => r'a0a3236aa0475a3c1256efa151e357dcb837121a';

final class SignInWithAppleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, BuildContext> {
  SignInWithAppleFamily._()
    : super(
        retry: null,
        name: r'signInWithAppleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SignInWithAppleProvider call(BuildContext context) =>
      SignInWithAppleProvider._(argument: context, from: this);

  @override
  String toString() => r'signInWithAppleProvider';
}

@ProviderFor(goToSignUp)
final goToSignUpProvider = GoToSignUpFamily._();

final class GoToSignUpProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  GoToSignUpProvider._({
    required GoToSignUpFamily super.from,
    required BuildContext super.argument,
  }) : super(
         retry: null,
         name: r'goToSignUpProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$goToSignUpHash();

  @override
  String toString() {
    return r'goToSignUpProvider'
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
    return goToSignUp(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GoToSignUpProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goToSignUpHash() => r'd6c6e75191de186df02a344c4507ba31838dafbd';

final class GoToSignUpFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, BuildContext> {
  GoToSignUpFamily._()
    : super(
        retry: null,
        name: r'goToSignUpProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GoToSignUpProvider call(BuildContext context) =>
      GoToSignUpProvider._(argument: context, from: this);

  @override
  String toString() => r'goToSignUpProvider';
}

@ProviderFor(goToForgotPassword)
final goToForgotPasswordProvider = GoToForgotPasswordFamily._();

final class GoToForgotPasswordProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  GoToForgotPasswordProvider._({
    required GoToForgotPasswordFamily super.from,
    required BuildContext super.argument,
  }) : super(
         retry: null,
         name: r'goToForgotPasswordProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$goToForgotPasswordHash();

  @override
  String toString() {
    return r'goToForgotPasswordProvider'
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
    return goToForgotPassword(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GoToForgotPasswordProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goToForgotPasswordHash() =>
    r'8fe77d38893a88d153db2e06a7d49ecbf2722d63';

final class GoToForgotPasswordFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, BuildContext> {
  GoToForgotPasswordFamily._()
    : super(
        retry: null,
        name: r'goToForgotPasswordProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GoToForgotPasswordProvider call(BuildContext context) =>
      GoToForgotPasswordProvider._(argument: context, from: this);

  @override
  String toString() => r'goToForgotPasswordProvider';
}

@ProviderFor(RememberMe)
final rememberMeProvider = RememberMeProvider._();

final class RememberMeProvider extends $NotifierProvider<RememberMe, bool> {
  RememberMeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rememberMeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rememberMeHash();

  @$internal
  @override
  RememberMe create() => RememberMe();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$rememberMeHash() => r'd98cb9316a18abfd798db8c0370c47a9a2e7b30d';

abstract class _$RememberMe extends $Notifier<bool> {
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
