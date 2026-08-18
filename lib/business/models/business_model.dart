import 'dart:convert';

class BusinessModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final String businessCategoryId;
  final String categoryName;
  final Map<String, dynamic>? metadata;
  final BusinessImageModel? image;
  final DateTime createdAt;

  const BusinessModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.businessCategoryId,
    required this.categoryName,
    this.metadata,
    this.image,
    required this.createdAt,
  });

  factory BusinessModel.fromRawJson(String str) => BusinessModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] as String?,
      isActive: json['isActive'] ?? true,
      businessCategoryId: json['businessCategoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      metadata: json['metadata'] is Map<String, dynamic> ? Map<String, dynamic>.from(json['metadata']) : null,
      image: json['image'] != null ? BusinessImageModel.fromJson(json['image'] as Map<String, dynamic>) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'isActive': isActive,
    'businessCategoryId': businessCategoryId,
    'categoryName': categoryName,
    'metadata': metadata,
    'image': image?.toJson(),
    'createdAt': createdAt.toIso8601String(),
  };
}

class BusinessImageModel {
  final String id;
  final String url;
  final String? blurHash;

  const BusinessImageModel({required this.id, required this.url, this.blurHash});

  factory BusinessImageModel.fromRawJson(String str) => BusinessImageModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BusinessImageModel.fromJson(Map<String, dynamic> json) {
    return BusinessImageModel(id: json['id'] ?? '', url: json['url'] ?? '', blurHash: json['blurHash'] as String?);
  }

  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'blurHash': blurHash};
}
