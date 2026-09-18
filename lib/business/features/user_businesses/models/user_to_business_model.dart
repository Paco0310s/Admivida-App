import 'package:admivida/business/features/user_businesses/models/commission_types_enum.dart';

class AddUserToBusinessRequestModel {
  final String userId;
  final List<String> roleIds;
  final CommissionType commissionType;
  final double commissionValue;

  AddUserToBusinessRequestModel({required this.userId, required this.roleIds, required this.commissionType, required this.commissionValue});

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'roleIds': roleIds, 'commissionType': commissionType.value, 'commissionValue': commissionValue};
  }
}

class UpdateUserBusinessRequestModel {
  final List<String>? roleIds;
  final CommissionType? commissionType;
  final double? commissionValue;

  UpdateUserBusinessRequestModel({this.roleIds, this.commissionType, this.commissionValue});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (roleIds != null) data['roleIds'] = roleIds;
    if (commissionType != null) data['commissionType'] = commissionType!.value;
    if (commissionValue != null) data['commissionValue'] = commissionValue;

    return data;
  }
}
