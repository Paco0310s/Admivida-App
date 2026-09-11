class BusinessClientModel {
  final String userId;
  final String firstName;
  final String lastName;

  BusinessClientModel({required this.userId, required this.firstName, required this.lastName});

  factory BusinessClientModel.fromJson(Map<String, dynamic> json) {
    return BusinessClientModel(userId: json['userId'] as String, firstName: json['firstName'] as String, lastName: (json['lastName'] as String?) ?? '');
  }

  String get fullName => '$firstName $lastName'.trim();
}
