import 'dart:convert';

class UserLoggedModel {
  final String userId;
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final List<String> roles;
  final List<BusinessModel> businesses;
  final int minRequiredVersionCode;
  final bool inMaintenance;

  UserLoggedModel({
    required this.userId,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.roles,
    required this.businesses,
    required this.minRequiredVersionCode,
    required this.inMaintenance,
  });

  factory UserLoggedModel.fromRawJson(String str) => UserLoggedModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory UserLoggedModel.fromJson(Map<String, dynamic> json) => UserLoggedModel(
    userId: json["userId"] ?? '',
    user: UserModel.fromJson(json["user"] ?? {}),
    accessToken: json["access_token"] ?? '',
    refreshToken: json["refresh_token"] ?? '',
    roles: json["roles"] != null ? List<String>.from(json["roles"].map((x) => x.toString())) : [],
    businesses: json["businesses"] != null ? List<BusinessModel>.from(json["businesses"].map((x) => BusinessModel.fromJson(x))) : [],
    minRequiredVersionCode: json["minRequiredVersionCode"] ?? 0,
    inMaintenance: json["inMaintenance"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "userId": userId,
    "user": user.toJson(),
    "access_token": accessToken,
    "refresh_token": refreshToken,
    "roles": List<dynamic>.from(roles.map((x) => x)),
    "businesses": List<dynamic>.from(businesses.map((x) => x.toJson())),
    "minRequiredVersionCode": minRequiredVersionCode,
    "inMaintenance": inMaintenance,
  };
}

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String code;
  final bool isActive;
  final bool isVerified;
  final DateTime? birthdate;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final bool isRegistered;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.code,
    required this.isActive,
    required this.isVerified,
    this.birthdate,
    required this.metadata,
    required this.createdAt,
    required this.isRegistered,
  });

  factory UserModel.fromRawJson(String str) => UserModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json["id"] ?? '',
    firstName: json["firstName"] ?? '',
    lastName: json["lastName"] ?? '',
    email: json["email"] ?? '',
    phone: json["phone"] ?? '',
    code: json["code"] ?? '',
    isActive: json["isActive"] ?? false,
    isVerified: json["isVerified"] ?? false,
    birthdate: json["birthdate"] != null ? DateTime.tryParse(json["birthdate"].toString())?.toLocal() : null,
    metadata: json["metadata"] is Map<String, dynamic> ? Map<String, dynamic>.from(json["metadata"]) : {},
    createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]).toLocal() : DateTime.now(),
    isRegistered: json["isRegistered"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "firstName": firstName,
    "lastName": lastName,
    "email": email,
    "phone": phone,
    "code": code,
    "isActive": isActive,
    "isVerified": isVerified,
    "birthdate": birthdate != null
        ? "${birthdate!.year.toString().padLeft(4, '0')}-${birthdate!.month.toString().padLeft(2, '0')}-${birthdate!.day.toString().padLeft(2, '0')}"
        : null,
    "metadata": metadata,
    "createdAt": createdAt.toIso8601String(),
    "isRegistered": isRegistered,
  };
}

class BusinessModel {
  final String businessId;
  final List<String> businessRoles;

  BusinessModel({required this.businessId, required this.businessRoles});

  factory BusinessModel.fromRawJson(String str) => BusinessModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel(
    businessId: json["businessId"] ?? '',
    businessRoles: json["business_roles"] != null ? List<String>.from(json["business_roles"].map((x) => x.toString())) : [],
  );

  Map<String, dynamic> toJson() => {"businessId": businessId, "business_roles": List<dynamic>.from(businessRoles.map((x) => x))};
}
