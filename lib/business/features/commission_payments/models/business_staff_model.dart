import 'package:admivida/business/features/user_businesses/models/commission_types_enum.dart';

class StaffRoleModel {
  final String id;
  final String name;

  StaffRoleModel({required this.id, required this.name});

  factory StaffRoleModel.fromJson(Map<String, dynamic> json) {
    return StaffRoleModel(id: json['id'] as String, name: json['name'] as String);
  }
}

class BusinessStaffModel {
  final String userId;
  final String firstName;
  final String lastName;
  final CommissionType commissionType;
  final double commissionValue;
  final List<StaffRoleModel> roles;

  BusinessStaffModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.commissionType = CommissionType.noCommission,
    this.commissionValue = 0.0,
    this.roles = const [],
  });

  factory BusinessStaffModel.fromJson(Map<String, dynamic> json) {
    return BusinessStaffModel(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: (json['lastName'] as String?) ?? '',
      commissionType: CommissionType.fromString(json['commissionType'] as String? ?? ''),
      commissionValue: (json['commissionValue'] as num?)?.toDouble() ?? 0.0,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => StaffRoleModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}
