import 'package:admivida/business/features/user_businesses/models/commission_types_enum.dart';

class BusinessRoleModel {
  final String id;
  final String name;

  BusinessRoleModel({required this.id, required this.name});

  factory BusinessRoleModel.fromJson(Map<String, dynamic> json) {
    return BusinessRoleModel(id: json['id'] as String, name: json['name'] as String);
  }
}

class UserBusinessModel {
  final String id;
  final String userId;
  final String businessId;
  final CommissionType commissionType;
  final double commissionValue;
  final List<BusinessRoleModel> businessRoles;

  UserBusinessModel({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.commissionType,
    required this.commissionValue,
    required this.businessRoles,
  });

  factory UserBusinessModel.fromJson(Map<String, dynamic> json) {
    return UserBusinessModel(
      id: json['id'] as String,
      userId: json['userId'] as String, // From database mapping user_id
      businessId: json['businessId'] as String, // From database mapping business_id
      commissionType: CommissionType.fromString(json['commissionType'] as String? ?? ''),
      commissionValue: (json['commissionValue'] as num?)?.toDouble() ?? 0.0,
      businessRoles: (json['businessRoles'] as List<dynamic>?)?.map((e) => BusinessRoleModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}
