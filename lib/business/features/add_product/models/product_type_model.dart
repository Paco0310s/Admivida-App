class ProductTypeModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final bool allowFractions;

  const ProductTypeModel({required this.id, required this.code, required this.name, this.description, required this.allowFractions});

  factory ProductTypeModel.fromJson(Map<String, dynamic> json) {
    return ProductTypeModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      allowFractions: json['allowFractions'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'code': code, 'name': name, 'description': description, 'allowFractions': allowFractions};
  }
}
