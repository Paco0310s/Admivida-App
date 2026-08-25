class PaymentMethodModel {
  final String id;
  final String code;
  final String name;
  final String description;

  PaymentMethodModel({required this.id, required this.code, required this.name, required this.description});

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'code': code, 'name': name, 'description': description};
  }
}
