import 'package:admivida/business/features/user_businesses/models/commission_types_enum.dart';
import 'package:admivida/common/models/user_logged_model.dart';

class CollaboratorFormState {
  final UserModel? searchedUser;
  final bool isLoading;
  final String? errorMessage;
  final List<String> selectedRoleIds;
  final CommissionType commissionType;
  final double commissionValue;
  final bool isSuccess;
  final bool isCreatingNewUser;
  final bool userFound;

  CollaboratorFormState({
    this.searchedUser,
    this.isLoading = false,
    this.errorMessage,
    this.selectedRoleIds = const [],
    this.commissionType = CommissionType.noCommission,
    this.commissionValue = 0.0,
    this.isSuccess = false,
    this.isCreatingNewUser = false,
    this.userFound = false, // <-- Por defecto en falso
  });

  CollaboratorFormState copyWith({
    UserModel? searchedUser,
    bool? isLoading,
    String? errorMessage,
    List<String>? selectedRoleIds,
    CommissionType? commissionType,
    double? commissionValue,
    bool? isSuccess,
    bool? isCreatingNewUser,
    bool? userFound, // <-- Incluido en copyWith
    bool clearError = false,
    bool clearUser = false,
  }) {
    return CollaboratorFormState(
      searchedUser: clearUser ? null : (searchedUser ?? this.searchedUser),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedRoleIds: selectedRoleIds ?? this.selectedRoleIds,
      commissionType: commissionType ?? this.commissionType,
      commissionValue: commissionValue ?? this.commissionValue,
      isSuccess: isSuccess ?? this.isSuccess,
      isCreatingNewUser: isCreatingNewUser ?? this.isCreatingNewUser,
      userFound: userFound ?? this.userFound,
    );
  }
}
