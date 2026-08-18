import 'dart:convert';

class BusinessCategoryModel {
  final String id;
  final String name;
  final String description;

  BusinessCategoryModel({required this.id, required this.name, required this.description});

  factory BusinessCategoryModel.fromRawJson(String str) => BusinessCategoryModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BusinessCategoryModel.fromJson(Map<String, dynamic> json) =>
      BusinessCategoryModel(id: json["id"], name: json["name"], description: json["description"]);

  Map<String, dynamic> toJson() => {"id": id, "name": name, "description": description};
}
