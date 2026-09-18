// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_business_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CollaboratorFormController)
final collaboratorFormControllerProvider = CollaboratorFormControllerFamily._();

final class CollaboratorFormControllerProvider
    extends
        $NotifierProvider<CollaboratorFormController, CollaboratorFormState> {
  CollaboratorFormControllerProvider._({
    required CollaboratorFormControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'collaboratorFormControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$collaboratorFormControllerHash();

  @override
  String toString() {
    return r'collaboratorFormControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CollaboratorFormController create() => CollaboratorFormController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollaboratorFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CollaboratorFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CollaboratorFormControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$collaboratorFormControllerHash() =>
    r'c47b41fd4883f9eab66fe51ff64f75462574e202';

final class CollaboratorFormControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CollaboratorFormController,
          CollaboratorFormState,
          CollaboratorFormState,
          CollaboratorFormState,
          String
        > {
  CollaboratorFormControllerFamily._()
    : super(
        retry: null,
        name: r'collaboratorFormControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CollaboratorFormControllerProvider call(String businessId) =>
      CollaboratorFormControllerProvider._(argument: businessId, from: this);

  @override
  String toString() => r'collaboratorFormControllerProvider';
}

abstract class _$CollaboratorFormController
    extends $Notifier<CollaboratorFormState> {
  late final _$args = ref.$arg as String;
  String get businessId => _$args;

  CollaboratorFormState build(String businessId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CollaboratorFormState, CollaboratorFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CollaboratorFormState, CollaboratorFormState>,
              CollaboratorFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(availableBusinessRoles)
final availableBusinessRolesProvider = AvailableBusinessRolesProvider._();

final class AvailableBusinessRolesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StaffRoleModel>>,
          List<StaffRoleModel>,
          FutureOr<List<StaffRoleModel>>
        >
    with
        $FutureModifier<List<StaffRoleModel>>,
        $FutureProvider<List<StaffRoleModel>> {
  AvailableBusinessRolesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableBusinessRolesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableBusinessRolesHash();

  @$internal
  @override
  $FutureProviderElement<List<StaffRoleModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StaffRoleModel>> create(Ref ref) {
    return availableBusinessRoles(ref);
  }
}

String _$availableBusinessRolesHash() =>
    r'25a8b7ecfa52c9ac2b7c87d19bdc179b9d6cfa88';
