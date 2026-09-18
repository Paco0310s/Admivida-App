import 'dart:convert';

import 'package:admivida/business/features/user_businesses/models/commission_types_enum.dart';
import 'package:admivida/common/models/user_logged_model.dart';

class CollaboratorSearchModel {
  final UserModel user;
  final List<String> existingRoles;
  final CommissionType? existingCommissionType;
  final double? existingCommissionValue;

  CollaboratorSearchModel({required this.user, required this.existingRoles, this.existingCommissionType, this.existingCommissionValue});

  factory CollaboratorSearchModel.fromRawJson(String str) => CollaboratorSearchModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CollaboratorSearchModel.fromJson(Map<String, dynamic> json) => CollaboratorSearchModel(
    user: UserModel.fromJson(json["user"] ?? {}),
    existingRoles: json["existingRoles"] != null ? List<String>.from(json["existingRoles"].map((x) => x.toString())) : [],
    existingCommissionType: json["existingCommissionType"] != null
        ? CommissionType.values.firstWhere(
            (e) => e.name.toUpperCase() == json["existingCommissionType"].toString().toUpperCase(),
            orElse: () => CommissionType.noCommission,
          )
        : null,
    existingCommissionValue: json["existingCommissionValue"] != null ? double.tryParse(json["existingCommissionValue"].toString()) ?? 0.0 : null,
  );

  Map<String, dynamic> toJson() => {
    "user": user.toJson(),
    "existingRoles": existingRoles,
    "existingCommissionType": existingCommissionType?.name,
    "existingCommissionValue": existingCommissionValue,
  };
}
