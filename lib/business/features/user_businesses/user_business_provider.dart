import 'package:admivida/business/features/commission_payments/models/business_staff_model.dart';
import 'package:admivida/business/features/user_businesses/models/collaborator_form_state.dart';
import 'package:admivida/business/features/user_businesses/models/commission_types_enum.dart';
import 'package:admivida/business/features/user_businesses/models/user_to_business_model.dart';
import 'package:admivida/business/features/user_businesses/user_business_service.dart';
import 'package:admivida/common/features/sign_up/models/create_user_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_business_provider.g.dart';

@riverpod
class CollaboratorFormController extends _$CollaboratorFormController {
  @override
  CollaboratorFormState build(String businessId) {
    return CollaboratorFormState();
  }

  Future<void> searchUser(String term) async {
    if (term.trim().isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true, clearUser: true, userFound: false);

    final result = await UserBusinessService.searchUser(businessId, term.trim());

    result.when(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (searchResult) {
        state = state.copyWith(
          isLoading: false,
          searchedUser: searchResult.user,
          userFound: true,
          selectedRoleIds: List<String>.from(searchResult.existingRoles),
          commissionType: searchResult.existingCommissionType ?? CommissionType.noCommission,
          commissionValue: searchResult.existingCommissionValue ?? 0.0,
        );
      },
    );
  }

  /// Toggles a role selection on or off
  void toggleRole(String roleId) {
    final currentRoles = List<String>.from(state.selectedRoleIds);

    if (currentRoles.contains(roleId)) {
      currentRoles.remove(roleId);
    } else {
      currentRoles.add(roleId);
    }

    state = state.copyWith(selectedRoleIds: List.from(currentRoles));
  }

  /// Updates the commission settings in the state
  void updateCommission(CommissionType type, double value) {
    state = state.copyWith(commissionType: type, commissionValue: value);
  }

  /// Assigns the searched user to the business
  Future<void> assignUser() async {
    // 👉 Validación: Si está en medio del formulario de creación y no ha registrado, avisar
    if (state.isCreatingNewUser) {
      state = state.copyWith(errorMessage: 'Por favor, primero registra al usuario nuevo antes de confirmar.');
      return;
    }

    if (state.searchedUser == null) {
      state = state.copyWith(errorMessage: 'Por favor, busca o selecciona un usuario.');
      return;
    }

    if (state.selectedRoleIds.isEmpty) {
      state = state.copyWith(errorMessage: 'Por favor selecciona uno almenos');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);

    final request = AddUserToBusinessRequestModel(
      userId: state.searchedUser!.id,
      roleIds: state.selectedRoleIds,
      commissionType: state.commissionType,
      commissionValue: state.commissionValue,
    );

    final result = await UserBusinessService.assignUserToBusiness(businessId: businessId, request: request);

    result.when(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (success) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      },
    );
  }

  /// Updates an already assigned user's roles and commissions
  Future<void> updateUser(String userId) async {
    if (state.selectedRoleIds.isEmpty) {
      state = state.copyWith(errorMessage: 'Please select at least one role.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);

    final request = UpdateUserBusinessRequestModel(
      roleIds: state.selectedRoleIds,
      commissionType: state.commissionType,
      commissionValue: state.commissionValue,
    );

    final result = await UserBusinessService.updateUserInBusiness(businessId: businessId, userId: userId, request: request);

    result.when(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (success) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      },
    );
  }

  /// Toggles the UI to show or hide the new user registration form
  void toggleCreateUserMode(bool isCreating) {
    state = state.copyWith(isCreatingNewUser: isCreating, clearError: true, clearUser: true, isSuccess: false, selectedRoleIds: []);
  }

  void clearAssignmentFields() {
    state = state.copyWith(selectedRoleIds: [], commissionType: CommissionType.noCommission, commissionValue: 0.0, isSuccess: false);
  }

  /// Registers a completely new user and automatically selects them for role assignment
  Future<void> registerNewUser(CreateUserDto dto) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);

    final result = await UserBusinessService.createNewUser(dto);

    result.when(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (user) {
        state = state.copyWith(isLoading: false, isCreatingNewUser: false, searchedUser: user, userFound: true, selectedRoleIds: []);
      },
    );
  }

  /// Preloads an existing collaborator's details for editing
  void loadExistingCollaborator(BusinessStaffModel staff) {
    final existingRoleIds = staff.roles.map((r) => r.id).toList();

    state = state.copyWith(
      isLoading: false,
      isSuccess: false, // Fundamental para que la UI detecte cambios de éxito futuros
      clearError: true,
      selectedRoleIds: existingRoleIds,
      commissionType: staff.commissionType,
      commissionValue: staff.commissionValue,
    );
  }
}

@riverpod
Future<List<StaffRoleModel>> availableBusinessRoles(Ref ref) async {
  final result = await UserBusinessService.getAvailableRoles();

  return result.when((failure) => throw Exception(failure.message), (roles) => roles);
}
