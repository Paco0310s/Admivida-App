class ProductCategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? parentId;

  const ProductCategoryModel({required this.id, required this.name, this.description, this.parentId});

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      parentId: json['parentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description, 'parentId': parentId};
  }
}
