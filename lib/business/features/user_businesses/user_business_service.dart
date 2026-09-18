import 'package:admivida/business/features/commission_payments/models/business_staff_model.dart';
import 'package:admivida/business/features/user_businesses/models/collaborator_search_model.dart';
import 'package:admivida/business/features/user_businesses/models/user_to_business_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/features/sign_up/models/create_user_dto.dart';
import 'package:admivida/common/models/user_logged_model.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class UserBusinessService {
  /// Searches for a user globally by email, phone, code, or UUID
  static Future<EitherUtil<HttpFailure, CollaboratorSearchModel>> searchUser(String businessId, String term) async {
    return await DioService.get<CollaboratorSearchModel>(
      AppConfig.searchCollaboratorEndpoint(businessId),
      (data) => CollaboratorSearchModel.fromJson(data),
      queryParameters: {'term': term},
    );
  }

  /// Assigns an existing user to a specific business with roles and commissions
  static Future<EitherUtil<HttpFailure, BusinessStaffModel>> assignUserToBusiness({
    required String businessId,
    required AddUserToBusinessRequestModel request,
  }) async {
    return await DioService.post<BusinessStaffModel>(
      AppConfig.addUserToBusinessEndpoint(businessId),
      request.toJson(),
      (data) => BusinessStaffModel.fromJson(data),
    );
  }

  /// Updates a user's roles and commission structure within a specific business
  static Future<EitherUtil<HttpFailure, BusinessStaffModel>> updateUserInBusiness({
    required String businessId,
    required String userId,
    required UpdateUserBusinessRequestModel request,
  }) async {
    return await DioService.patch<BusinessStaffModel>(
      AppConfig.updateUserInBusinessEndpoint(businessId, userId),
      request.toJson(),
      (data) => BusinessStaffModel.fromJson(data),
    );
  }

  /// Creates a new user in the platform from the collaborator screen
  static Future<EitherUtil<HttpFailure, UserModel>> createNewUser(CreateUserDto dto) async {
    return await DioService.post<UserModel>(AppConfig.users, dto.toJson(), (data) => UserModel.fromJson(data));
  }

  /// Retrieves all available business roles from the backend
  static Future<EitherUtil<HttpFailure, List<StaffRoleModel>>> getAvailableRoles() async {
    return await DioService.getList<StaffRoleModel>(AppConfig.businessesRoles, StaffRoleModel.fromJson);
  }
}
