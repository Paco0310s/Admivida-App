// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forgot_password_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sendResetLink)
final sendResetLinkProvider = SendResetLinkFamily._();

final class SendResetLinkProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SendResetLinkProvider._({
    required SendResetLinkFamily super.from,
    required (BuildContext, String) super.argument,
  }) : super(
         retry: null,
         name: r'sendResetLinkProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sendResetLinkHash();

  @override
  String toString() {
    return r'sendResetLinkProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (BuildContext, String);
    return sendResetLink(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SendResetLinkProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sendResetLinkHash() => r'cb579a37e0158473477d7ba23d1c9a356eeb18ca';

final class SendResetLinkFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, (BuildContext, String)> {
  SendResetLinkFamily._()
    : super(
        retry: null,
        name: r'sendResetLinkProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SendResetLinkProvider call(BuildContext context, String email) =>
      SendResetLinkProvider._(argument: (context, email), from: this);

  @override
  String toString() => r'sendResetLinkProvider';
}
