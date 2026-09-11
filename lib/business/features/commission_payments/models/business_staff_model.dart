// business_staff_model.dart
class BusinessStaffModel {
  final String userId;
  final String firstName;
  final String lastName;
  // Optional: final double? commissionValue;

  BusinessStaffModel({required this.userId, required this.firstName, required this.lastName});

  factory BusinessStaffModel.fromJson(Map<String, dynamic> json) {
    return BusinessStaffModel(userId: json['userId'] as String, firstName: json['firstName'] as String, lastName: (json['lastName'] as String?) ?? '');
  }

  String get fullName => '$firstName $lastName'.trim();
}
